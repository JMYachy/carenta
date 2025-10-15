import 'dart:convert';
import 'package:carenta/service/config/service_base_url.dart';
import 'package:http/http.dart' as http;

class CarStatusService {
  /// Fetch car and rental status counts
  Future<Map<String, dynamic>> fetchStatuses() async {
    final url = Uri.parse(ServiceBaseUrl.endpoint("admin_car_status.php"));
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception("Server error: ${response.statusCode}");
    }

    final data = jsonDecode(response.body);

    if (data is Map && data["ok"] == true) {
      return {
        "cars": Map<String, int>.from(data["cars"] ?? {}),
        "rentals": Map<String, int>.from(data["rentals"] ?? {}),
      };
    }

    // If the server returned an error payload
    final message =
        data is Map ? (data["message"] ?? data["error"]) : "Unknown error";
    throw Exception("Failed to load statuses: $message");
  }
}
