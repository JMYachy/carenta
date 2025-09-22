import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class AdminProfileService {
  /// Point this to your server API root
  final String apiRoot;
  const AdminProfileService({this.apiRoot = 'http://10.0.2.2/carenta/api'});

  String get _getUrl    => '$apiRoot/admin_profile_get.php';
  String get _updateUrl => '$apiRoot/admin_profile_update.php';
  String get _pwUrl     => '$apiRoot/admin_change_password.php';
  String get _avatarUrl => '$apiRoot/admin_upload_avatar.php';

  Future<Map<String, dynamic>> fetchProfile(int adminId) async {
    try {
      final uri = Uri.parse(_getUrl).replace(queryParameters: {'admin_id': '$adminId'});
      final res = await http.get(uri);
      if (res.statusCode != 200) return {"success": false, "message": "HTTP ${res.statusCode}"};
      final data = jsonDecode(res.body);
      if (data is Map && data['ok'] == true) {
        return {"status": "success", "data": data['data']};
      }
      return {"success": false, "message": data['message'] ?? data['error'] ?? "Unknown error"};
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required int adminId,
    required String firstName,
    required String lastName,
    required String email,
    String? phone,
    bool twoFactorEnabled = false,
  }) async {
    try {
      final res = await http.post(Uri.parse(_updateUrl), body: {
        'admin_id': '$adminId',
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        if (phone != null) 'phone_number': phone,
        'two_factor_enabled': twoFactorEnabled ? '1' : '0',
      });
      if (res.statusCode != 200) return {"success": false, "message": "HTTP ${res.statusCode}"};
      final data = jsonDecode(res.body);
      if (data is Map && data['ok'] == true) {
        return {"status": "success", "message": data['message'] ?? "Profile updated"};
      }
      return {"success": false, "message": data['message'] ?? data['error'] ?? "Failed to update"};
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required int adminId,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final res = await http.post(Uri.parse(_pwUrl), body: {
        'admin_id': '$adminId',
        'old_password': oldPassword,
        'new_password': newPassword,
      });
      if (res.statusCode != 200) return {"success": false, "message": "HTTP ${res.statusCode}"};
      final data = jsonDecode(res.body);
      if (data is Map && data['ok'] == true) {
        return {"status": "success", "message": data['message'] ?? "Password changed"};
      }
      return {"success": false, "message": data['message'] ?? data['error'] ?? "Failed to change password"};
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    }
  }

  Future<Map<String, dynamic>> uploadAvatar({
    required int adminId,
    required File imageFile,
  }) async {
    try {
      final req = http.MultipartRequest('POST', Uri.parse(_avatarUrl))
        ..fields['admin_id'] = '$adminId'
        ..files.add(await http.MultipartFile.fromPath('avatar', imageFile.path));
      final streamed = await req.send();
      final res = await http.Response.fromStream(streamed);
      if (res.statusCode != 200) return {"success": false, "message": "HTTP ${res.statusCode}"};
      final data = jsonDecode(res.body);
      if (data is Map && data['ok'] == true) {
        return {"status": "success", "message": data['message'] ?? "Avatar updated", "avatar_url": data['avatar_url']};
      }
      return {"success": false, "message": data['message'] ?? data['error'] ?? "Failed to upload avatar"};
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    }
  }
}
