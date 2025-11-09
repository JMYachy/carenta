import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:carenta/service/config/service_base_url.dart';

class UserNotificationService {
  Future<List<Map<String, dynamic>>> list({required int userId}) async {
    final endpoint =
        ServiceBaseUrl.endpoint('fetch_notifications.php?user_id=$userId');
    final url = Uri.parse(endpoint);

    final res = await http.get(url);

    if (res.statusCode != 200) {
      throw Exception('Failed to load notifications (HTTP ${res.statusCode})');
    }

    final data = jsonDecode(res.body);

    if (data['ok'] != true) {
      throw Exception(data['message'] ?? 'Error fetching notifications');
    }

    if (data['data'] is! List) {
      throw Exception('Invalid data format from server');
    }

    return (data['data'] as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}
