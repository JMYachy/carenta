// lib/service/user/user_favorite_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:carenta/service/config/service_base_url.dart';

class FavoritesService {
  FavoritesService();

  String get _listUrl => ServiceBaseUrl.endpoint('user_favorites.php');
  String get _toggleUrl => ServiceBaseUrl.endpoint('user_favorites_toggle.php');

  /// ✅ List favorites for a user
  /// sort: recent | price_asc | price_desc | rating_desc
  Future<Map<String, dynamic>> list({
    required int userId,
    String? q,
    String sort = 'recent',
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      final uri = Uri.parse(_listUrl).replace(queryParameters: {
        'user_id': '$userId',
        if ((q ?? '').trim().isNotEmpty) 'q': q!.trim(),
        'sort': sort,
      });

      final res = await http
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(timeout);

      if (res.statusCode != 200) {
        return {
          "ok": false,
          "message": "HTTP ${res.statusCode}",
          "body": res.body,
        };
      }

      final body = res.body.trim();
      if (!(body.startsWith('{') || body.startsWith('['))) {
        return {
          "ok": false,
          "message": "Invalid server response",
          "body": body,
        };
      }

      final decoded = jsonDecode(body);
      if (decoded is Map &&
          (decoded['ok'] == true || decoded['status'] == 'success')) {
        final List data = (decoded['data'] as List?) ?? const [];
        return {
          "ok": true,
          "status": "success",
          "count": data.length,
          "data": data,
          "message": decoded['message'] ?? 'Favorites loaded',
        };
      }

      return {
        "ok": false,
        "message": decoded is Map
            ? (decoded['message'] ?? decoded['error'] ?? 'Failed to load favorites')
            : 'Unexpected server response',
      };
    } catch (e) {
      return {"ok": false, "message": "Network error: $e"};
    }
  }

  /// ✅ Toggle favorite (add/remove)
  Future<Map<String, dynamic>> toggle({
    required int userId,
    required int carId,
    required bool add, // true -> add, false -> remove
    Duration timeout = const Duration(seconds: 12),
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse(_toggleUrl),
            headers: const {'Accept': 'application/json'},
            body: {
              'user_id': '$userId',
              'car_id': '$carId',
              'action': add ? 'add' : 'remove',
            },
          )
          .timeout(timeout);

      if (res.statusCode != 200) {
        return {
          "ok": false,
          "message": "HTTP ${res.statusCode}",
          "body": res.body,
        };
      }

      final body = res.body.trim();
      if (!(body.startsWith('{') || body.startsWith('['))) {
        return {
          "ok": false,
          "message": "Invalid server response",
          "body": body,
        };
      }

      final decoded = jsonDecode(body);
      if (decoded is Map &&
          (decoded['ok'] == true || decoded['status'] == 'success')) {
        return {
          "ok": true,
          "status": "success",
          "message": decoded['message'] ?? 'Favorite updated successfully',
        };
      }

      return {
        "ok": false,
        "message": decoded is Map
            ? (decoded['message'] ?? decoded['error'] ?? 'Failed to update favorite')
            : 'Unexpected server response',
      };
    } catch (e) {
      return {"ok": false, "message": "Network error: $e"};
    }
  }
}
