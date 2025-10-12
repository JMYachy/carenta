// lib/service/admin/admin_get_car_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:carenta/service/config/service_base_url.dart'; // ✅ import your base URL config

/// Page model with metadata + cars list
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
  // ✅ Use ServiceBaseUrl to automatically link to your API root
  static final String _endpoint = ServiceBaseUrl.endpoint('admingetcar.php');
  final http.Client _client;

  AdminGetCarService({http.Client? client}) : _client = client ?? http.Client();

  // ✅ Make URLs absolute (for images/videos)
  String _resolveUrl(dynamic path) {
    if (path == null) return '';
    final p = path.toString();
    if (p.isEmpty) return '';
    if (p.startsWith('http://') || p.startsWith('https://')) return p;
    return '${ServiceBaseUrl.baseUrl}$p';
  }

  double? _toNum(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  /// ✅ Fetch cars with pagination & normalization
  Future<CarPage> fetchCarsPage({int limit = 50, int offset = 0}) async {
    final uri = Uri.parse(_endpoint)
        .replace(queryParameters: {'limit': '$limit', 'offset': '$offset'});

    final res = await _client.get(uri);
    final bodyText = res.body.trim();

    if (res.statusCode != 200) {
      throw Exception('Failed to fetch cars: ${res.statusCode}');
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

    // Normalize cars
    final rawCars = (decoded['cars'] as List?) ?? const [];
    final cars = rawCars.map<Map<String, dynamic>>((e) {
      final m = Map<String, dynamic>.from(e as Map);

      // Make media URLs absolute
      m['media_url'] = _resolveUrl(m['media_url']);
      m['thumbnail_url'] = _resolveUrl(m['thumbnail_url']);

      // Numbers as doubles
      for (final k in ['hourly_rate', 'daily_rate', 'weekly_rate', 'monthly_rate']) {
        m[k] = _toNum(m[k]);
      }

      // Convenience fields
      final manu = (m['manufacturer'] ?? '').toString();
      final model = (m['model'] ?? '').toString();
      m['car_name'] = (m['car_name'] ?? '$manu $model').toString().trim();
      m['price_per_day'] = m['daily_rate']; // Handy for UI cards

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

  /// ✅ Backwards-compatible: return only the car list (first page)
  Future<List<Map<String, dynamic>>> getCars({int limit = 50, int offset = 0}) async {
    final page = await fetchCarsPage(limit: limit, offset: offset);
    return page.cars;
  }

  void close() => _client.close();
}
