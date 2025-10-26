import 'dart:convert';
import 'package:carenta/service/util_service/session_manager_service.dart';
import 'package:http/http.dart' as http;
import 'package:carenta/service/config/service_base_url.dart';

/// Service for fetching notifications & advisories
class NotificationService {
  final String _fetchUrl = ServiceBaseUrl.endpoint('fetch_notifications.php');

  /// ✅ Fetch all notifications for the logged-in renter
  Future<List<Map<String, dynamic>>> fetchNotifications() async {
    try {
      final session = await SessionManagerService.checkSession();
      final userId = session['data']?['userid'];
      if (userId == null) throw Exception('No active user session');

      final url = Uri.parse('$_fetchUrl?renter_id=$userId');
      final response = await http.get(url, headers: {
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true && data['notifications'] != null) {
          return List<Map<String, dynamic>>.from(data['notifications']);
        }
      }
    } catch (e) {
      print('Error fetching notifications: $e');
    }

    return [];
  }
}
