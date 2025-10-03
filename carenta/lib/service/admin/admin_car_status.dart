import 'dart:convert';
import 'package:http/http.dart' as http;

class CarStatusService {
  final String baseUrl = "http://10.0.2.2/carenta/api"; // adjust for prod

  Future<Map<String, dynamic>> fetchStatuses() async {
    final url = Uri.parse("$baseUrl/admin_car_status.php");

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["ok"] == true) {
        return {
          "cars": Map<String, int>.from(data["cars"]),
          "rentals": Map<String, int>.from(data["rentals"]),
        };
      }
    }
    throw Exception("Failed to load statuses");
  }
}
