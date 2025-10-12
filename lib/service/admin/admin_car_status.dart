import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:carenta/service/config/service_base_url.dart'; // ✅ Always import this

class CarStatusService {
  // ✅ Use the global base URL from your config
  static final String _endpoint = ServiceBaseUrl.endpoint('admin_car_status.php');

  Future<Map<String, dynamic>> fetchStatuses() async {
    final url = Uri.parse(_endpoint);

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["ok"] == true || data["status"] == "success") {
        return {
          "cars": Map<String, int>.from(data["cars"]),
          "rentals": Map<String, int>.from(data["rentals"]),
        };
      }
    }
    throw Exception("Failed to load statuses");
  }
}
