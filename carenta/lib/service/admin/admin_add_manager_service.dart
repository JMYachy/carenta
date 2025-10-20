import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:carenta/service/config/service_base_url.dart';

class AdminAddManagerService {
  static Future<Map<String, dynamic>> registerManager({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String username,
    required String password,
  }) async {
    final url = ServiceBaseUrl.endpoint("admin_add_manager.php");

    try {
      final res = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {
          "first_name": firstName,
          "last_name": lastName,
          "email": email,
          "phone_number": phone,
          "username": username,
          "password": password,
        },
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data["success"] == true) {
        return {"success": true, "message": data["message"] ?? "Created"};
      } else {
        return {"success": false, "message": data["message"] ?? "Failed"};
      }
    } catch (e) {
      return {"success": false, "message": "Network error: $e"};
    }
  }
}
