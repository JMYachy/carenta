import 'dart:convert';
import 'package:http/http.dart' as http;

class FavoritesService {
  final String apiRoot;
  const FavoritesService({this.apiRoot = 'http://10.0.2.2/carenta/api'});

  Future<Map<String, dynamic>> list({
    required int userId,
    String? q,
    String sort = 'recent', // recent | price_asc | price_desc | rating_desc
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final uri = Uri.parse('$apiRoot/user_favorites.php').replace(queryParameters: {
      'user_id': '$userId',
      if ((q ?? '').trim().isNotEmpty) 'q': q!.trim(),
      'sort': sort,
    });

    final res = await http.get(uri).timeout(timeout);
    if (res.statusCode != 200) {
      return {"success": false, "message": "HTTP ${res.statusCode}", "body": res.body};
    }

    final raw = res.body.trimLeft();
    if (!(raw.startsWith('{') || raw.startsWith('['))) {
      return {"success": false, "message": "Unexpected server response", "body": raw};
    }

    final decoded = jsonDecode(raw);
    if (decoded is Map && (decoded['ok'] == true || decoded['status'] == 'success')) {
      final List data = (decoded['data'] as List?) ?? const [];
      return {"status": "success", "count": data.length, "data": data};
    }

    return {
      "success": false,
      "message": decoded is Map ? (decoded['message'] ?? decoded['error'] ?? 'Unknown error') : 'Unknown error',
      "body": raw,
    };
  }

  Future<Map<String, dynamic>> toggle({
    required int userId,
    required int carId,
    required bool add, // true -> add, false -> remove
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final res = await http.post(
      Uri.parse('$apiRoot/user_favorite_toggle.php'),
      body: {'user_id': '$userId', 'car_id': '$carId', 'action': add ? 'add' : 'remove'},
    ).timeout(timeout);

    if (res.statusCode != 200) {
      return {"success": false, "message": "HTTP ${res.statusCode}", "body": res.body};
    }
    final raw = res.body.trimLeft();
    final decoded = (raw.startsWith('{') || raw.startsWith('[')) ? jsonDecode(raw) : null;

    if (decoded is Map && (decoded['ok'] == true || decoded['status'] == 'success')) {
      return {"status": "success", "message": decoded['message'] ?? 'OK'};
    }
    return {
      "success": false,
      "message": decoded is Map ? (decoded['message'] ?? decoded['error'] ?? 'Unknown error') : 'Unexpected server response',
      "body": raw,
    };
  }
}
