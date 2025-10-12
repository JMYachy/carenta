import 'dart:async';
import 'dart:convert';
import 'package:carenta/service/config/service_base_url.dart';
import 'package:http/http.dart' as http;

class AdminDashboardStatsService {
  static final String _endpoint = ServiceBaseUrl.endpoint('admin_dashboard_stats.php');

  static Future<Map<String, dynamic>> fetchStats() async {
    try {
      final res = await http
          .get(Uri.parse(_endpoint))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) {
        return {"success": false, "message": "HTTP ${res.statusCode}"};
      }

      final decoded = jsonDecode(res.body);
      if (decoded["status"] == "success") {
        return {"success": true, "data": decoded["data"] ?? {}};
      }
      return {
        "success": false,
        "message": decoded["message"] ?? "Unknown error",
      };
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  static Stream<Map<String, dynamic>> pollStats({
    Duration interval = const Duration(seconds: 5),
  }) async* {
    while (true) {
      yield await fetchStats();
      await Future.delayed(interval);
    }
  }
}
