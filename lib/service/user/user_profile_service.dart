import 'dart:convert';
import 'dart:io';
import 'package:carenta/service/config/service_base_url.dart';
import 'package:http/http.dart' as http;

class UserProfileService {
  /// Use 10.0.2.2 for Android emulator, your LAN IP for real devices.

  Map<String, dynamic> _toMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
    return <String, dynamic>{};
  }

  /// Fetch profile by user_id (GET user_profile.php?user_id=)
  Future<Map<String, dynamic>> fetchProfile(
    int userId, {
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final uri = Uri.parse(
      ServiceBaseUrl.endpoint('user_profile.php'),
    ).replace(queryParameters: {'user_id': '$userId'});

    final res = await http.get(uri).timeout(timeout);
    if (res.statusCode != 200) {
      return {
        "success": false,
        "message": "HTTP ${res.statusCode}",
        "body": res.body,
      };
    }

    final raw = res.body.trimLeft();
    if (!(raw.startsWith('{') || raw.startsWith('['))) {
      return {
        "success": false,
        "message": "Unexpected server response",
        "body": raw,
      };
    }

    final root = _toMap(jsonDecode(raw));
    if (root['ok'] == true || root['status'] == 'success') {
      final data =
          _toMap(root['data']).isNotEmpty ? _toMap(root['data']) : root;
      return {"status": "success", "data": data};
    }
    return {
      "success": false,
      "message": root['message'] ?? root['error'] ?? 'Failed to fetch profile',
      "body": raw,
    };
  }

  /// Update profile with all fields (POST user_profile.php)
  Future<Map<String, dynamic>> updateProfile({
    required int userId,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    String? username,
    String? gender, // 'Male' | 'Female' | 'Other'
    String? birthdate, // 'YYYY-MM-DD'
    String? address, // street_address
    String? city,
    String? province, // state
    String? zipCode, // postal_code
    String? country,
    String? language,
    String? timezone,
    bool? darkMode,
    File? avatarFile, // optional multipart file
    Duration timeout = const Duration(seconds: 20),
  }) async {
    if (avatarFile != null) {
      // Multipart if avatar is included
      final req = http.MultipartRequest(
        'POST',
        Uri.parse(ServiceBaseUrl.endpoint('user_profile.php')),
      );
      req.fields.addAll({
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
      });
      req.files.add(
        await http.MultipartFile.fromPath('avatar', avatarFile.path),
      );

      final streamed = await req.send().timeout(timeout);
      final res = await http.Response.fromStream(streamed);

      return _parseResponse(res);
    } else {
      // Simple form POST if no avatar
      final res = await http
          .post(
            Uri.parse(ServiceBaseUrl.endpoint('user_profile.php')),
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
  }

  /// Change password (POST user_change_password.php)
  Future<Map<String, dynamic>> changePassword({
    required int userId,
    required String currentPassword,
    required String newPassword,
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final res = await http
        .post(
          Uri.parse(ServiceBaseUrl.endpoint('user_change_password.php')),
          body: {
            'user_id': '$userId',
            'current_password': currentPassword,
            'new_password': newPassword,
          },
        )
        .timeout(timeout);

    return _parseResponse(res);
  }

  /// Common response parser
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
