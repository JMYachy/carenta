import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
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
/// Provides CRUD operations, analytics, and filtering for the manager fleet dashboard.
class ManagerCarService {
  final http.Client _client;

  ManagerCarService({http.Client? client}) : _client = client ?? http.Client();

  // ---------------------------------------------------------------------------
  // 🔧 UTILITIES
  // ---------------------------------------------------------------------------

  String _resolveUrl(dynamic path) {
    if (path == null) return '';
    final p = path.toString().trim();
    if (p.isEmpty) return '';
    if (p.startsWith('http://') || p.startsWith('https://')) return p;
    return ServiceBaseUrl.file(p);
  }

  double? _toNum(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  String _normalizeStatus(dynamic raw) {
    if (raw == null) return 'unknown';
    final s = raw.toString().trim().toLowerCase();

    if (['available', 'active', '0'].contains(s)) return 'available';
    if (['maintenance', 'maint', '1', 'under maintenance'].contains(s))
      return 'maintenance';
    if (['inactive', 'disabled', 'archived', '2'].contains(s))
      return 'inactive';
    if (['rented', 'ongoing', 'booked', 'in-use', '3'].contains(s))
      return 'rented';
    return s;
  }

  // ---------------------------------------------------------------------------
  // 🚗 FETCHING
  // ---------------------------------------------------------------------------

  Future<CarPage> fetchCarsPage({
    int limit = 50,
    int offset = 0,
    String? search,
    String? status,
  }) async {
    final queryParams = <String, String>{
      'limit': '$limit',
      'offset': '$offset',
      if (search != null && search.isNotEmpty) 'q': search,
      if (status != null && status.isNotEmpty && status != 'all')
        'status': status,
    };

    final uri = Uri.parse(
      ServiceBaseUrl.endpoint("manager_fetch_cars.php"),
    ).replace(queryParameters: queryParams);

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
          (decoded is Map ? decoded['message'] : null) ?? 'Unknown API error';
      throw Exception('API error: $msg');
    }

    final rawCars = (decoded['cars'] as List?) ?? const [];
    final cars = rawCars
        .map<Map<String, dynamic>>((e) {
          final m = Map<String, dynamic>.from(e as Map);

          // ✅ Resolve URLs
          m['media_url'] = _resolveUrl(m['media_url']);
          m['thumbnail_url'] = _resolveUrl(m['thumbnail_url']);

          // ✅ Normalize numeric fields
          for (final k in [
            'hourly_rate',
            'daily_rate',
            'weekly_rate',
            'monthly_rate',
          ]) {
            m[k] = _toNum(m[k]);
          }

          // ✅ Default values
          m['color'] = m['color'] ?? '';
          m['milage'] = m['milage'] ?? m['mileage'] ?? '';
          m['fueltype'] = m['fueltype'] ?? m['fuel_type'] ?? '';
          m['transmission'] = m['transmission'] ?? '';
          m['seatingcap'] = m['seatingcap'] ?? m['seating_capacity'] ?? '';
          m['withDriver'] = m['withDriver'] ?? m['with_driver'] ?? 'No';
          m['type'] = m['type'] ?? m['car_type'] ?? '';
          m['status'] = _normalizeStatus(m['status']);

          // ✅ Parse media arrays
          if (m['media'] is List) {
            m['media'] =
                (m['media'] as List).map<Map<String, dynamic>>((img) {
                  final mm = Map<String, dynamic>.from(img as Map);
                  mm['media_url'] = _resolveUrl(mm['media_url']);
                  mm['thumbnail_url'] = _resolveUrl(mm['thumbnail_url']);
                  return mm;
                }).toList();
          }

          if (m['videos'] is List) {
            m['videos'] =
                (m['videos'] as List).map<Map<String, dynamic>>((vid) {
                  final vv = Map<String, dynamic>.from(vid as Map);
                  vv['media_url'] = _resolveUrl(vv['media_url']);
                  vv['thumbnail_url'] = _resolveUrl(vv['thumbnail_url']);
                  return vv;
                }).toList();
          }

          // ✅ Friendly display fields
          final manu = (m['manufacturer'] ?? '').toString();
          final model = (m['model'] ?? '').toString();
          m['car_name'] = (m['car_name'] ?? '$manu $model').toString().trim();
          m['price_per_day'] = m['daily_rate'] ?? 0;

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

  Future<List<Map<String, dynamic>>> getCars({
    int limit = 50,
    int offset = 0,
    String? search,
    String? status,
  }) async {
    final page = await fetchCarsPage(
      limit: limit,
      offset: offset,
      search: search,
      status: status,
    );
    return page.cars;
  }

  // ---------------------------------------------------------------------------
  // 🧭 FILTERING + ANALYTICS
  // ---------------------------------------------------------------------------

  List<Map<String, dynamic>> filterByStatus(
    List<Map<String, dynamic>> cars,
    String status,
  ) {
    if (status == 'all') return List.from(cars);
    final st = status.toLowerCase();
    return cars.where((c) {
      final s = _normalizeStatus(c['status']);
      return s == st;
    }).toList();
  }

  Map<String, int> computeFleetStats(List<Map<String, dynamic>> cars) {
    final stats = {
      'available': 0,
      'rented': 0,
      'maintenance': 0,
      'inactive': 0,
    };

    for (final car in cars) {
      final s = _normalizeStatus(car['status']);
      if (stats.containsKey(s)) stats[s] = (stats[s]! + 1);
    }

    return stats;
  }

  List<Map<String, dynamic>> searchCars(
    List<Map<String, dynamic>> cars,
    String query,
  ) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return cars;
    return cars.where((c) {
      return (c['model'] ?? '').toString().toLowerCase().contains(q) ||
          (c['manufacturer'] ?? '').toString().toLowerCase().contains(q) ||
          (c['license_plate'] ?? '').toString().toLowerCase().contains(q) ||
          (c['type'] ?? '').toString().toLowerCase().contains(q);
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // ✏️ UPDATE CAR DATA
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> updateCar({
    required int carId,
    required String model,
    required String manufacturer,
    required String color,
    required String licensePlate,
    required String milage,
    required String dailyRate,
    required String status,
    List<File>? newImages,
    File? newVideo,
  }) async {
    try {
      final url = ServiceBaseUrl.endpoint("manager_update_car_detail.php");
      final req = http.MultipartRequest("POST", Uri.parse(url));

      req.fields.addAll({
        "carid": carId.toString(),
        "model": model,
        "manufacturer": manufacturer,
        "color": color,
        "license_plate": licensePlate,
        "milage": milage,
        "daily_rate": dailyRate,
        "status": status,
      });

      // Image uploads
      if (newImages != null && newImages.isNotEmpty) {
        for (final file in newImages) {
          final mime = lookupMimeType(file.path) ?? 'image/jpeg';
          final parts = mime.split('/');
          req.files.add(
            await http.MultipartFile.fromPath(
              'images[]',
              file.path,
              contentType: MediaType(parts[0], parts[1]),
            ),
          );
        }
      }

      // Video upload
      if (newVideo != null && await newVideo.exists()) {
        final mime = lookupMimeType(newVideo.path) ?? 'video/mp4';
        final parts = mime.split('/');
        req.files.add(
          await http.MultipartFile.fromPath(
            'video',
            newVideo.path,
            contentType: MediaType(parts[0], parts[1]),
          ),
        );
      }

      final response = await req.send();
      final body = await response.stream.bytesToString();
      final decoded = jsonDecode(body);

      if (response.statusCode == 200 && decoded["success"] == true) {
        return {
          "success": true,
          "message": decoded["message"],
          "data": decoded,
        };
      } else {
        return {
          "success": false,
          "message": decoded["message"] ?? "Update failed",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    }
  }

  // ---------------------------------------------------------------------------
  // 🧹 CLEANUP
  // ---------------------------------------------------------------------------

  void close() => _client.close();
}
