import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:carenta/service/config/service_base_url.dart';

class UserProfileService {
  Map<String, dynamic> _toMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
    return <String, dynamic>{};
  }

  /// ✅ Fetch user profile by ID
  Future<Map<String, dynamic>> fetchProfile(
    int userId, {
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final uri = Uri.parse(
      ServiceBaseUrl.endpoint('user_profile.php'),
    ).replace(queryParameters: {'user_id': '$userId'});

    try {
      final res = await http.get(uri).timeout(timeout);

      if (res.statusCode != 200) {
        return {
          "success": false,
          "message": "HTTP ${res.statusCode}",
          "body": res.body,
        };
      }

      final body = res.body.trimLeft();
      if (!(body.startsWith('{') || body.startsWith('['))) {
        return {
          "success": false,
          "message": "Unexpected server response",
          "body": body,
        };
      }

      final decoded = _toMap(jsonDecode(body));
      if (decoded['ok'] == true || decoded['status'] == 'success') {
        final data =
            _toMap(decoded['data']).isNotEmpty
                ? _toMap(decoded['data'])
                : decoded;
        return {"status": "success", "data": data};
      }

      return {
        "success": false,
        "message":
            decoded['message'] ?? decoded['error'] ?? 'Failed to fetch profile',
        "body": body,
      };
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    }
  }

  /// ✅ Update user profile (with or without avatar)
  Future<Map<String, dynamic>> updateProfile({
    required int userId,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    String? username,
    String? gender,
    String? birthdate,
    String? address,
    String? city,
    String? province,
    String? zipCode,
    String? country,
    String? language,
    String? timezone,
    bool? darkMode,
    File? avatarFile,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final uri = Uri.parse(ServiceBaseUrl.endpoint('user_profile_update.php'));

    try {
      if (avatarFile != null) {
        // ✅ Multipart form for avatar upload
        final req =
            http.MultipartRequest('POST', uri)
              ..fields.addAll({
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
                if (country != null) 'country': country,
                if (language != null) 'language': language,
                if (timezone != null) 'timezone': timezone,
                if (darkMode != null) 'dark_mode': darkMode ? '1' : '0',
              })
              ..files.add(
                await http.MultipartFile.fromPath('avatar', avatarFile.path),
              );

        final streamed = await req.send().timeout(timeout);
        final res = await http.Response.fromStream(streamed);
        return _parseResponse(res);
      } else {
        // ✅ Regular POST (no avatar)
        final res = await http
            .post(
              uri,
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
                if (country != null) 'country': country,
                if (language != null) 'language': language,
                if (timezone != null) 'timezone': timezone,
                if (darkMode != null) 'dark_mode': darkMode ? '1' : '0',
              },
            )
            .timeout(timeout);

        return _parseResponse(res);
      }
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    }
  }

  /// ✅ Upload avatar only (update_avatar.php)
  Future<Map<String, dynamic>> uploadAvatar({
    required int userId,
    required File avatarFile,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final uri = Uri.parse(ServiceBaseUrl.endpoint('update_avatar.php'));

    try {
      final req =
          http.MultipartRequest('POST', uri)
            ..fields['user_id'] = '$userId'
            ..files.add(
              await http.MultipartFile.fromPath('avatar', avatarFile.path),
            );

      final streamed = await req.send().timeout(timeout);
      final res = await http.Response.fromStream(streamed);
      return _parseResponse(res);
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    }
  }

  /// ✅ Change password (user_change_password.php)
  Future<Map<String, dynamic>> changePassword({
    required int userId,
    required String currentPassword,
    required String newPassword,
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final uri = Uri.parse(ServiceBaseUrl.endpoint('user_change_password.php'));

    try {
      final res = await http
          .post(
            uri,
            body: {
              'user_id': '$userId',
              'current_password': currentPassword,
              'new_password': newPassword,
            },
          )
          .timeout(timeout);

      return _parseResponse(res);
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    }
  }

  /// ✅ Common JSON response handler
  Map<String, dynamic> _parseResponse(http.Response res) {
    if (res.statusCode != 200) {
      return {
        "success": false,
        "message": "HTTP ${res.statusCode}",
        "body": res.body,
      };
    }

    final raw = res.body.trimLeft();
    final root =
        (raw.startsWith('{') || raw.startsWith('['))
            ? _toMap(jsonDecode(raw))
            : {};

    if (root['ok'] == true || root['status'] == 'success') {
      return {
        "status": "success",
        "message": root['message'] ?? 'Success',
        "data": root['data'] ?? {},
      };
    }

    return {
      "success": false,
      "message": root['message'] ?? root['error'] ?? 'Operation failed',
      "body": raw,
    };
  }
}
