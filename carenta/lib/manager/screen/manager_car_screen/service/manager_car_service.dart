import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:carenta/service/config/service_base_url.dart';

/// Model representing a paginated set of cars.
class CarPage {
  final bool success;
  final int total;
  final int limit;
  final int offset;
  final List<Map<String, dynamic>> cars;

  CarPage({
    required this.success,
    required this.total,
    required this.limit,
    required this.offset,
    required this.cars,
  });
}

/// ✅ ManagerCarService
/// A high-level fleet data service for the manager dashboard.
/// Wraps around the backend API to fetch, filter, and analyze car data.
class ManagerCarService {
  final http.Client _client;

  ManagerCarService({http.Client? client}) : _client = client ?? http.Client();

  // ---------------------------------------------------------------------------
  // 🔧 UTILITIES
  // ---------------------------------------------------------------------------

  /// Converts relative paths to absolute URLs using your configured base.
  String _resolveUrl(dynamic path) {
    if (path == null) return '';
    final p = path.toString().trim();
    if (p.isEmpty) return '';
    if (p.startsWith('http://') || p.startsWith('https://')) return p;
    return ServiceBaseUrl.file(p);
  }

  /// Parses numbers safely into doubles.
  double? _toNum(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  // ---------------------------------------------------------------------------
  // 🚗 FETCHING
  // ---------------------------------------------------------------------------

  /// Fetch paginated list of cars.
  ///
  /// Supports optional search term (`q`) and pagination.
  Future<CarPage> fetchCarsPage({
    int limit = 50,
    int offset = 0,
    String? search,
  }) async {
    final uri = Uri.parse(ServiceBaseUrl.endpoint("fetch_car.php")).replace(
      queryParameters: {
        'limit': '$limit',
        'offset': '$offset',
        if (search != null && search.isNotEmpty) 'q': search,
      },
    );

    final res = await _client.get(uri);
    final bodyText = res.body.trim();

    if (res.statusCode != 200) {
      throw Exception('Failed to fetch cars: HTTP ${res.statusCode}');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(bodyText);
    } catch (_) {
      throw Exception('Invalid JSON from server: $bodyText');
    }

    if (decoded is! Map || decoded['success'] != true) {
      final msg = (decoded is Map ? decoded['message'] : null) ?? 'Unknown error';
      throw Exception('API error: $msg');
    }

    final rawCars = (decoded['cars'] as List?) ?? const [];

    final cars = rawCars.map<Map<String, dynamic>>((e) {
      final m = Map<String, dynamic>.from(e as Map);

      // ✅ Resolve top-level media URLs
      m['media_url'] = _resolveUrl(m['media_url']);
      m['thumbnail_url'] = _resolveUrl(m['thumbnail_url']);

      // ✅ Numeric safety
      for (final k in [
        'hourly_rate',
        'daily_rate',
        'weekly_rate',
        'monthly_rate',
      ]) {
        m[k] = _toNum(m[k]);
      }

      // ✅ Data normalization
      m['color'] = m['color'] ?? '';
      m['milage'] = m['milage'] ?? m['mileage'] ?? '';
      m['fueltype'] = m['fueltype'] ?? m['fuel_type'] ?? '';
      m['transmission'] = m['transmission'] ?? '';
      m['seatingcap'] = m['seatingcap'] ?? m['seating_capacity'] ?? '';
      m['withDriver'] = m['withDriver'] ?? m['with_driver'] ?? 'No';
      m['status'] = (m['status'] ?? '').toString().toLowerCase();
      m['type'] = m['type'] ?? m['car_type'] ?? '';

      // ✅ Parse media arrays
      if (m['media'] is List) {
        m['media'] = (m['media'] as List)
            .map<Map<String, dynamic>>((img) {
          final mm = Map<String, dynamic>.from(img as Map);
          mm['media_url'] = _resolveUrl(mm['media_url']);
          mm['thumbnail_url'] = _resolveUrl(mm['thumbnail_url']);
          return mm;
        }).toList();
      }

      // ✅ Parse video arrays
      if (m['videos'] is List) {
        m['videos'] = (m['videos'] as List)
            .map<Map<String, dynamic>>((vid) {
          final vv = Map<String, dynamic>.from(vid as Map);
          vv['media_url'] = _resolveUrl(vv['media_url']);
          vv['thumbnail_url'] = _resolveUrl(vv['thumbnail_url']);
          return vv;
        }).toList();
      }

      // ✅ Add human-friendly aliases
      final manu = (m['manufacturer'] ?? '').toString();
      final model = (m['model'] ?? '').toString();
      m['car_name'] = (m['car_name'] ?? '$manu $model').toString().trim();
      m['price_per_day'] = m['daily_rate'];

      return m;
    }).toList(growable: false);

    return CarPage(
      success: true,
      total: (decoded['total'] ?? cars.length) as int,
      limit: (decoded['limit'] ?? limit) as int,
      offset: (decoded['offset'] ?? offset) as int,
      cars: cars,
    );
  }

  /// Fetch a flat list of all cars (simple helper)
  Future<List<Map<String, dynamic>>> getCars({
    int limit = 50,
    int offset = 0,
    String? search,
  }) async {
    final page = await fetchCarsPage(limit: limit, offset: offset, search: search);
    return page.cars;
  }

  // ---------------------------------------------------------------------------
  // 🧭 FILTERING + ANALYTICS
  // ---------------------------------------------------------------------------

  /// Returns a subset of cars filtered by status (local filtering).
  List<Map<String, dynamic>> filterByStatus(
      List<Map<String, dynamic>> cars, String status) {
    if (status == 'all') return List.from(cars);
    final st = status.toLowerCase();
    return cars.where((c) {
      final s = (c['status'] ?? '').toString().toLowerCase();
      return s.contains(st);
    }).toList();
  }

  /// Computes fleet summary metrics for the dashboard.
  ///
  /// Returns counts for: available, rented, maintenance, inactive.
  Map<String, int> computeFleetStats(List<Map<String, dynamic>> cars) {
    int available = 0;
    int rented = 0;
    int maintenance = 0;
    int inactive = 0;

    for (final car in cars) {
      final status = (car['status'] ?? '').toString().toLowerCase();
      if (status == 'available') {
        available++;
      } else if (status == 'rented' || status == 'in-use') {
        rented++;
      } else if (status == 'maintenance') {
        maintenance++;
      } else if (status == 'inactive' || status == 'archived') {
        inactive++;
      }
    }

    return {
      'available': available,
      'rented': rented,
      'maintenance': maintenance,
      'inactive': inactive,
    };
  }

  // ---------------------------------------------------------------------------
  // 🔍 SEARCH UTILITIES
  // ---------------------------------------------------------------------------

  /// Filters cars locally by text search.
  List<Map<String, dynamic>> searchCars(
      List<Map<String, dynamic>> cars, String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return cars;
    return cars.where((c) {
      final model = (c['model'] ?? '').toString().toLowerCase();
      final manufacturer = (c['manufacturer'] ?? '').toString().toLowerCase();
      final plate = (c['license_plate'] ?? '').toString().toLowerCase();
      return model.contains(q) ||
          manufacturer.contains(q) ||
          plate.contains(q);
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // 🧹 CLEANUP
  // ---------------------------------------------------------------------------

  void close() => _client.close();
}
