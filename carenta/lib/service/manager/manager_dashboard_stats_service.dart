import 'dart:async';
import 'dart:convert';
import 'package:carenta/service/config/service_base_url.dart';
import 'package:http/http.dart' as http;

class ManagerDashboardStatsService {
  static final String _endpoint = '${ServiceBaseUrl.baseUrl}/manager_dashboard_stats.php';

  /// Continuously polls manager stats every [interval]
  static Stream<Map<String, dynamic>> pollStats({
    Duration interval = const Duration(seconds: 8),
  }) async* {
    while (true) {
      try {
        final response = await http.get(Uri.parse(_endpoint));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          yield data;
        } else {
          yield {
            "success": false,
            "message": "Server error: ${response.statusCode}"
          };
        }
      } catch (e) {
        yield {"success": false, "message": "Connection error: $e"};
      }
      await Future.delayed(interval);
    }
  }
}
