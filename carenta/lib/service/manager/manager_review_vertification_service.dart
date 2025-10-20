import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:carenta/service/config/service_base_url.dart';

class ManagerVerificationService {
  /// ✅ Fetch all pending verifications
  static Future<Map<String, dynamic>> fetchPendingVerifications() async {
    final url = ServiceBaseUrl.endpoint("user_verification_list.php");

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["success"] == true) {
          return {"success": true, "data": data["data"] ?? []};
        } else {
          return {
            "success": false,
            "message": data["message"] ?? "Failed to fetch verifications.",
          };
        }
      } else {
        return {
          "success": false,
          "message":
              "Server error: ${response.statusCode} (${response.reasonPhrase})",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Network error: $e"};
    }
  }

  /// ✅ Submit verification review (approve / reject)
  static Future<Map<String, dynamic>> reviewVerification({
    required int userId,
    required String action, // 'approved' or 'rejected'
    String? notes,
  }) async {
    final url = ServiceBaseUrl.endpoint("review_verification.php");

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {
          "userid": userId.toString(),
          "action": action,
          "notes": notes ?? "",
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["success"] == true) {
        return {
          "success": true,
          "message": data["message"] ?? "Action successful.",
          "data": data["data"] ?? {},
        };
      } else {
        return {
          "success": false,
          "message": data["message"] ?? "Failed to process review.",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Network error: $e"};
    }
  }
}
