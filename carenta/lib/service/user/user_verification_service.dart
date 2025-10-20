import 'dart:convert';
import 'dart:io';
import 'package:carenta/service/config/service_base_url.dart';
import 'package:http/http.dart' as http;

class UserVerificationService {
  static Future<Map<String, dynamic>> submitVerification({
    required int userId,
    required String idType,
    required File frontImage,
    File? backImage,
  }) async {
    try {
      final url = Uri.parse(
        ServiceBaseUrl.endpoint("user_submit_verification.php"),
      );
      final request =
          http.MultipartRequest('POST', url)
            ..fields['userid'] = userId.toString()
            ..fields['id_type'] = idType
            ..files.add(
              await http.MultipartFile.fromPath('id_front', frontImage.path),
            );

      if (backImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('id_back', backImage.path),
        );
      }

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return jsonDecode(body);
      } else {
        return {
          "success": false,
          "status": "error",
          "message": "Server returned ${response.statusCode}",
        };
      }
    } catch (e) {
      return {
        "success": false,
        "status": "error",
        "message": "Upload failed: $e",
      };
    }
  }
}
