import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:carenta/service/config/service_base_url.dart';

class AdminProfileService {
  final http.Client _client;

  AdminProfileService({http.Client? client})
    : _client = client ?? http.Client();

  String get _getUrl => ServiceBaseUrl.endpoint("admin_profile_get.php");
  String get _updateUrl => ServiceBaseUrl.endpoint("admin_profile_update.php");
  String get _pwUrl => ServiceBaseUrl.endpoint("admin_change_password.php");
  String get _avatarUrl => ServiceBaseUrl.endpoint("admin_upload_avatar.php");

  /// ✅ Fetch admin profile details
  Future<Map<String, dynamic>> fetchProfile(int adminId) async {
    try {
      final uri = Uri.parse(
        _getUrl,
      ).replace(queryParameters: {'admin_id': '$adminId'});
      final res = await _client.get(uri);

      if (res.statusCode != 200) {
        return {"success": false, "message": "HTTP ${res.statusCode}"};
      }

      final data = jsonDecode(res.body);
      if (data is Map && data['ok'] == true) {
        return {"status": "success", "data": data['data']};
      }

      return {
        "success": false,
        "message": data['message'] ?? data['error'] ?? "Unknown error",
      };
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    }
  }

  /// ✅ Update admin profile info
  Future<Map<String, dynamic>> updateProfile({
    required int adminId,
    required String firstName,
    required String lastName,
    required String email,
    String? phone,
    bool twoFactorEnabled = false,
  }) async {
    try {
      final res = await _client.post(
        Uri.parse(_updateUrl),
        body: {
          'admin_id': '$adminId',
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          if (phone != null) 'phone_number': phone,
          'two_factor_enabled': twoFactorEnabled ? '1' : '0',
        },
      );

      if (res.statusCode != 200) {
        return {"success": false, "message": "HTTP ${res.statusCode}"};
      }

      final data = jsonDecode(res.body);
      if (data is Map && data['ok'] == true) {
        return {
          "status": "success",
          "message": data['message'] ?? "Profile updated",
        };
      }

      return {
        "success": false,
        "message": data['message'] ?? data['error'] ?? "Failed to update",
      };
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    }
  }

  /// ✅ Change admin password
  Future<Map<String, dynamic>> changePassword({
    required int adminId,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final res = await _client.post(
        Uri.parse(_pwUrl),
        body: {
          'admin_id': '$adminId',
          'old_password': oldPassword,
          'new_password': newPassword,
        },
      );

      if (res.statusCode != 200) {
        return {"success": false, "message": "HTTP ${res.statusCode}"};
      }

      final data = jsonDecode(res.body);
      if (data is Map && data['ok'] == true) {
        return {
          "status": "success",
          "message": data['message'] ?? "Password changed",
        };
      }

      return {
        "success": false,
        "message":
            data['message'] ?? data['error'] ?? "Failed to change password",
      };
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    }
  }

  /// ✅ Upload admin avatar/profile picture
  Future<Map<String, dynamic>> uploadAvatar({
    required int adminId,
    required File imageFile,
  }) async {
    try {
      final req =
          http.MultipartRequest('POST', Uri.parse(_avatarUrl))
            ..fields['admin_id'] = '$adminId'
            ..files.add(
              await http.MultipartFile.fromPath('avatar', imageFile.path),
            );

      final streamed = await req.send();
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode != 200) {
        return {"success": false, "message": "HTTP ${res.statusCode}"};
      }

      final data = jsonDecode(res.body);
      if (data is Map && data['ok'] == true) {
        return {
          "status": "success",
          "message": data['message'] ?? "Avatar updated",
          "avatar_url": data['avatar_url'],
        };
      }

      return {
        "success": false,
        "message":
            data['message'] ?? data['error'] ?? "Failed to upload avatar",
      };
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    }
  }

  void close() => _client.close();
}
