import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:carenta/service/config/service_base_url.dart';

/// Model for a paginated response containing cars
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

class AdminGetCarService {
  final http.Client _client;

  AdminGetCarService({http.Client? client}) : _client = client ?? http.Client();

  /// Helper to build absolute URLs for images and files
  String _resolveUrl(dynamic path) {
    if (path == null) return '';
    final p = path.toString().trim();
    if (p.isEmpty) return '';
    if (p.startsWith('http://') || p.startsWith('https://')) return p;
    return '${ServiceBaseUrl.baseUrl}$p';
  }

  double? _toNum(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  /// Fetch cars with pagination and optional search
  Future<CarPage> fetchCarsPage({
    int limit = 50,
    int offset = 0,
    String? search,
  }) async {
    final uri = Uri.parse(ServiceBaseUrl.endpoint("admin_get_car.php")).replace(
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
      final msg =
          (decoded is Map ? decoded['message'] : null) ?? 'Unknown error';
      throw Exception('API error: $msg');
    }

    final rawCars = (decoded['cars'] as List?) ?? const [];
    final cars = rawCars
        .map<Map<String, dynamic>>((e) {
          final m = Map<String, dynamic>.from(e as Map);

          // Make URLs absolute
          m['media_url'] = _resolveUrl(m['media_url']);
          m['thumbnail_url'] = _resolveUrl(m['thumbnail_url']);

          // Convert to numeric values
          for (final k in [
            'hourly_rate',
            'daily_rate',
            'weekly_rate',
            'monthly_rate',
          ]) {
            m[k] = _toNum(m[k]);
          }

          // Extra UI-friendly fields
          final manu = (m['manufacturer'] ?? '').toString();
          final model = (m['model'] ?? '').toString();
          m['car_name'] = (m['car_name'] ?? '$manu $model').toString().trim();
          m['price_per_day'] = m['daily_rate'];

          return m;
        })
        .toList(growable: false);

    return CarPage(
      success: true,
      total: (decoded['total'] ?? cars.length) as int,
      limit: (decoded['limit'] ?? limit) as int,
      offset: (decoded['offset'] ?? offset) as int,
      cars: cars,
    );
  }

  /// Quick helper to get just the car list
  Future<List<Map<String, dynamic>>> getCars({
    int limit = 50,
    int offset = 0,
    String? search,
  }) async {
    final page = await fetchCarsPage(
      limit: limit,
      offset: offset,
      search: search,
    );
    return page.cars;
  }

  void close() => _client.close();
}
