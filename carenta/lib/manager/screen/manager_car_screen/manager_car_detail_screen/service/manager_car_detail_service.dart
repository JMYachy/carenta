import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:carenta/service/config/service_base_url.dart';

/// Dedicated service for the Manager Car Detail Screen (backward-compatible).
/// - Keeps your existing manager_car_service.dart untouched.
/// - Uses ServiceBaseUrl.endpoint() for API URLs and ServiceBaseUrl.file() for media URLs.
class ManagerCarDetailService {
  /// Fetch detailed car data (car + price + media + rental_status).
  /// Tries manager_fetch_car_detail.php first; if not available, falls back to fetch_car.php.
  static Future<Map<String, dynamic>> fetchCarBundle(int carId) async {
    // 1) Try manager endpoint (preferred)
    final tryManager = await _tryFetch(
      ServiceBaseUrl.endpoint('manager_fetch_car_detail.php?car_id=$carId'),
    );
    if (tryManager != null) return tryManager;

    // 2) Fallback to legacy endpoint
    final tryLegacy = await _tryFetch(
      ServiceBaseUrl.endpoint('fetch_car.php?car_id=$carId'),
      legacyShape: true,
    );
    if (tryLegacy != null) return tryLegacy;

    throw Exception('Failed to fetch car bundle for car_id=$carId');
  }

  /// Internal fetch helper that understands both { data: {...} } and legacy flat shapes.
  static Future<Map<String, dynamic>?> _tryFetch(
    String url, {
    bool legacyShape = false,
  }) async {
    final uri = Uri.parse(url);
    final res = await http.get(uri, headers: {'Accept': 'application/json'});

    if (res.statusCode != 200) return null;

    Map<String, dynamic> root;
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) return null;

      // Unwrap "data" if present (new manager scripts)
      root =
          decoded.containsKey('data') && decoded['data'] is Map<String, dynamic>
              ? Map<String, dynamic>.from(decoded['data'])
              : decoded;
    } catch (_) {
      return null;
    }

    // Map into the bundle the screen expects
    final car = Map<String, dynamic>.from(
      root['car'] ?? (legacyShape ? (root['data'] ?? {}) : {}),
    );
    final price = Map<String, dynamic>.from(root['price'] ?? {});
    final rawMedia = root['media'] ?? root['images'] ?? [];
    final media = _normalizeMediaList(rawMedia);
    final rentalStatus =
        '${root['rental_status'] ?? root['rentalStatus'] ?? 'none'}';

    return {
      'car': car,
      'price': price,
      'media': media,
      'rental_status': rentalStatus,
    };
  }

  /// Update car details (excluding status).
  static Future<bool> updateCarDetails({
    required int carId,
    required Map<String, dynamic> fields,
  }) async {
    final uri = Uri.parse(
      ServiceBaseUrl.endpoint('manager_update_car_detail.php'),
    );
    final body = {
      'car_id': '$carId',
      ...fields.map((k, v) => MapEntry(k, '$v')),
    };

    final res = await http.post(uri, body: body);
    if (res.statusCode != 200) return false;

    try {
      final json = jsonDecode(res.body);
      return json['success'] == true || json['ok'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Update only car status (available | maintenance | inactive).
  static Future<bool> updateCarStatus({
    required int carId,
    required String status,
  }) async {
    final uri = Uri.parse(
      ServiceBaseUrl.endpoint('manager_update_car_status.php'),
    );
    final res = await http.post(
      uri,
      body: {'car_id': '$carId', 'status': status},
    );

    if (res.statusCode != 200) return false;
    try {
      final json = jsonDecode(res.body);
      return json['success'] == true || json['ok'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Update price table (pricetbl).
  static Future<bool> updatePrice({
    required int carId,
    required Map<String, dynamic> priceFields,
  }) async {
    final uri = Uri.parse(
      ServiceBaseUrl.endpoint('manager_update_car_detail.php'),
    );
    final body = {
      'car_id': '$carId',
      'update_price': '1',
      ...priceFields.map((k, v) => MapEntry(k, '$v')),
    };

    final res = await http.post(uri, body: body);
    if (res.statusCode != 200) return false;

    try {
      final json = jsonDecode(res.body);
      return json['success'] == true || json['ok'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Upload media (image/video) via multipart/form-data.
  static Future<bool> uploadMedia({
    required int carId,
    required String filePath,
    required String mediaType, // 'image' | 'video'
  }) async {
    final uri = Uri.parse(ServiceBaseUrl.endpoint('manager_manage_media.php'));
    final req =
        http.MultipartRequest('POST', uri)
          ..fields['action'] = 'upload'
          ..fields['car_id'] = '$carId'
          ..fields['media_type'] = mediaType;

    final file = await http.MultipartFile.fromPath('file', filePath);
    req.files.add(file);

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode != 200) return false;
    try {
      final json = jsonDecode(res.body);
      return json['success'] == true || json['ok'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Delete media item by id.
  static Future<bool> deleteMedia({required int mediaId}) async {
    final uri = Uri.parse(ServiceBaseUrl.endpoint('manager_manage_media.php'));
    final res = await http.post(
      uri,
      body: {'action': 'delete', 'media_id': '$mediaId'},
    );

    if (res.statusCode != 200) return false;
    try {
      final json = jsonDecode(res.body);
      return json['success'] == true || json['ok'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Ensure media URLs are absolute using ServiceBaseUrl.file().
  static List<Map<String, dynamic>> _normalizeMediaList(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map<Map<String, dynamic>>((e) {
      final m = Map<String, dynamic>.from(e as Map);
      final mediaUrl = '${m['media_url'] ?? ''}';
      final thumbUrl = '${m['thumbnail_url'] ?? ''}';
      m['media_url'] = ServiceBaseUrl.file(mediaUrl);
      if (thumbUrl.isNotEmpty) {
        m['thumbnail_url'] = ServiceBaseUrl.file(thumbUrl);
      }
      return m;
    }).toList();
  }
}
