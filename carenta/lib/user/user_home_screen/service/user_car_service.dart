import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:carenta/service/config/service_base_url.dart';

/// ✅ UserCarService
/// Fetches cars for user side (renter), using your fetch_car.php endpoint.
class UserCarService {
  final http.Client _client;

  UserCarService({http.Client? client}) : _client = client ?? http.Client();

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

  Future<List<Map<String, dynamic>>> fetchCars({
    int limit = 100,
    int offset = 0,
    String? search,
    String? type,
  }) async {
    final queryParams = <String, String>{
      'limit': '$limit',
      'offset': '$offset',
      if (search != null && search.isNotEmpty) 'q': search,
      if (type != null && type.isNotEmpty) 'type': type,
    };

    final uri = Uri.parse(
      ServiceBaseUrl.endpoint("fetch_car.php"),
    ).replace(queryParameters: queryParams);

    final res = await _client.get(uri);
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map || decoded['success'] != true) {
      throw Exception(decoded['message'] ?? 'Failed to fetch cars');
    }

    final List rawCars = decoded['cars'] ?? decoded['data'] ?? [];
    return rawCars.map<Map<String, dynamic>>(_normalizeCar).toList();
  }

  Map<String, dynamic> _normalizeCar(dynamic raw) {
    if (raw is! Map) return {};
    final m = Map<String, dynamic>.from(raw);

    m['media_url'] = _resolveUrl(
      m['media_url'] ?? m['thumbnail_url'] ?? m['image_url'],
    );

    m['currency'] = m['currency'] ?? 'PHP';
    m['daily_rate'] = _toNum(m['daily_rate']) ?? 0;
    m['manufacturer'] = m['manufacturer'] ?? '';
    m['model'] = m['model'] ?? '';
    m['type'] = m['type'] ?? '';
    m['color'] = m['color'] ?? '';
    m['transmission'] = m['transmission'] ?? '';
    m['fueltype'] = m['fueltype'] ?? '';
    m['milage'] = m['milage']?.toString() ?? '';
    m['seatingcap'] = m['seatingcap']?.toString() ?? '';
    m['withDriver'] = m['withDriver'] ?? 'No';
    m['status'] = m['status'] ?? 'available';

    return m;
  }

  void close() => _client.close();
}
