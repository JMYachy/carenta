import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminDashboardService {
  static const String _baseUrl = "http://10.0.2.2/carenta/api/admin_dashboard_stats.php";

  static Future<Map<String, dynamic>> fetchStats() async {
    final response = await http.get(Uri.parse(_baseUrl));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load dashboard stats");
    }
  }
}
