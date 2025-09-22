import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class UserProfileService {
  /// Use 10.0.2.2 for Android emulator, your LAN IP for real devices.
  final String apiRoot;
  const UserProfileService({this.apiRoot = 'http://10.0.2.2/carenta/api'});

  Map<String, dynamic> _toMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
    return <String, dynamic>{};
  }

  Future<Map<String, dynamic>> fetchProfile(
    int userId, {
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final uri = Uri.parse('$apiRoot/user_profile.php')
        .replace(queryParameters: {'user_id': '$userId'});

    final res = await http.get(uri).timeout(timeout);
    if (res.statusCode != 200) {
      return {"success": false, "message": "HTTP ${res.statusCode}", "body": res.body};
    }

    final raw = res.body.trimLeft();
    if (!(raw.startsWith('{') || raw.startsWith('['))) {
      return {"success": false, "message": "Unexpected server response", "body": raw};
    }

    final root = _toMap(jsonDecode(raw));
    if (root['ok'] == true || root['status'] == 'success') {
      final data = _toMap(root['data']).isNotEmpty ? _toMap(root['data']) : root;
      return {"status": "success", "data": data};
    }
    return {
      "success": false,
      "message": root['message'] ?? root['error'] ?? 'Failed to fetch profile',
      "body": raw
    };
  }

  /// Update profile with more fields from usertbl.
  Future<Map<String, dynamic>> updateProfile({
    required int userId,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    String? username,
    String? gender,           // 'male' | 'female' | 'other'
    String? birthdate,        // 'YYYY-MM-DD'
    String? address,          // address line
    String? city,
    String? province,
    String? zipCode,
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final res = await http.post(
      Uri.parse('$apiRoot/user_profile_update.php'),
      body: {
        'user_id': '$userId',
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone_number': phone,
        if (username != null) 'username': username,
        if (gender != null) 'gender': gender,
        if (birthdate != null) 'birthdate': birthdate,
        if (address != null) 'address': address,
        if (city != null) 'city': city,
        if (province != null) 'province': province,
        if (zipCode != null) 'zip_code': zipCode,
      },
    ).timeout(timeout);

    if (res.statusCode != 200) {
      return {"success": false, "message": "HTTP ${res.statusCode}", "body": res.body};
    }

    final raw = res.body.trimLeft();
    final root = (raw.startsWith('{') || raw.startsWith('['))
        ? _toMap(jsonDecode(raw))
        : {};
    if (root['ok'] == true || root['status'] == 'success') {
      return {"status": "success", "message": root['message'] ?? 'Profile updated'};
    }
    return {
      "success": false,
      "message": root['message'] ?? root['error'] ?? 'Update failed',
      "body": raw
    };
  }

  /// Optional: avatar upload (multipart). Provide a File path from image_picker.
  Future<Map<String, dynamic>> uploadAvatar({
    required int userId,
    required File file,
    Duration timeout = const Duration(seconds: 20), required File imageFile,
  }) async {
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('$apiRoot/user_profile_avatar_upload.php'),
    );
    req.fields['user_id'] = '$userId';
    req.files.add(await http.MultipartFile.fromPath('avatar', file.path));

    final streamed = await req.send().timeout(timeout);
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode != 200) {
      return {"success": false, "message": "HTTP ${res.statusCode}", "body": res.body};
    }
    final raw = res.body.trimLeft();
    final root = (raw.startsWith('{') || raw.startsWith('['))
        ? _toMap(jsonDecode(raw))
        : {};
    if (root['ok'] == true || root['status'] == 'success') {
      return {"status": "success", "message": root['message'] ?? 'Avatar updated', "url": root['url']};
    }
    return {
      "success": false,
      "message": root['message'] ?? root['error'] ?? 'Upload failed',
      "body": raw
    };
  }

  Future<Map<String, dynamic>> changePassword({
    required int userId,
    required String currentPassword,
    required String newPassword,
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final res = await http.post(
      Uri.parse('$apiRoot/user_change_password.php'),
      body: {
        'user_id': '$userId',
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    ).timeout(timeout);

    if (res.statusCode != 200) {
      return {"success": false, "message": "HTTP ${res.statusCode}", "body": res.body};
    }

    final raw = res.body.trimLeft();
    final root = (raw.startsWith('{') || raw.startsWith('['))
        ? _toMap(jsonDecode(raw))
        : {};
    if (root['ok'] == true || root['status'] == 'success') {
      return {"status": "success", "message": root['message'] ?? 'Password updated'};
    }
    return {
      "success": false,
      "message": root['message'] ?? root['error'] ?? 'Change password failed',
      "body": raw
    };
  }
}
