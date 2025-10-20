import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:carenta/service/config/service_base_url.dart';

class ManagerProfileService {
  static Future<Map<String, dynamic>> fetchProfile(int managerId) async {
    final url = ServiceBaseUrl.endpoint(
      "manager_profile.php?manager_id=$managerId",
    );

    try {
      final res = await http.get(Uri.parse(url));
      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data["success"] == true) {
        return {"success": true, "data": data["data"]};
      } else {
        return {
          "success": false,
          "message": data["message"] ?? "Failed to load",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Network error: $e"};
    }
  }

  static Future<Map<String, dynamic>> updateProfile({
    required int managerId,
    required String email,
    required String phone,
    required String username,
    required String firstName,
    required String lastName,
  }) async {
    final url = ServiceBaseUrl.endpoint("manager_profile.php");

    try {
      final res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          "manager_id": managerId.toString(),
          "email": email,
          "phone_number": phone,
          "username": username,
          "first_name": firstName,
          "last_name": lastName,
        },
      );
      final data = jsonDecode(res.body);
      return {
        "success": data["success"] ?? false,
        "message": data["message"] ?? "No response",
      };
    } catch (e) {
      return {"success": false, "message": "Network error: $e"};
    }
  }
}
