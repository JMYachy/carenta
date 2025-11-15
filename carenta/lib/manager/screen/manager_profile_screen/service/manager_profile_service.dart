import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:carenta/service/config/service_base_url.dart';

class ManagerProfileService {
  static const _jsonHeaders = {'Accept': 'application/json'};

  static Exception _error(Object e, [StackTrace? st]) =>
      Exception('NETWORK_ERROR: $e');

  static Future<Map<String, dynamic>> _decode(http.Response res) async {
    if (res.statusCode != 200) {
      throw Exception('HTTP_${res.statusCode}: ${res.body}');
    }
    try {
      final data = jsonDecode(res.body);
      if (data is Map<String, dynamic>) return data;
      throw Exception('INVALID_JSON');
    } catch (e) {
      throw Exception('INVALID_JSON: $e');
    }
  }

  /// GET /api/fetch_manager_profile.php?admin_id={id}
  static Future<Map<String, dynamic>> fetchProfile(int adminId) async {
    final uri = Uri.parse(
      ServiceBaseUrl.endpoint('fetch_manager_profile.php?admin_id=$adminId'),
    );
    try {
      final res = await http
          .get(uri, headers: _jsonHeaders)
          .timeout(const Duration(seconds: 20));
      return _decode(res);
    } catch (e, st) {
      throw _error(e, st);
    }
  }

  /// POST /api/update_manager_profile.php
  static Future<Map<String, dynamic>> updateProfile({
    required int adminId,
    required Map<String, String> fields,
  }) async {
    final uri = Uri.parse(
      ServiceBaseUrl.endpoint('update_manager_profile.php'),
    );
    try {
      final res = await http
          .post(
            uri,
            headers: _jsonHeaders,
            body: {'admin_id': '$adminId', ...fields},
          )
          .timeout(const Duration(seconds: 20));
      return _decode(res);
    } catch (e, st) {
      throw _error(e, st);
    }
  }

  /// POST /api/manager_change_password.php
  static Future<Map<String, dynamic>> changePassword({
    required int adminId,
    required String current,
    required String next,
  }) async {
    final uri = Uri.parse(
      ServiceBaseUrl.endpoint('manager_change_password.php'),
    );
    try {
      final res = await http
          .post(
            uri,
            headers: _jsonHeaders,
            body: {
              'admin_id': '$adminId',
              'current_password': current,
              'new_password': next,
            },
          )
          .timeout(const Duration(seconds: 20));
      return _decode(res);
    } catch (e, st) {
      throw _error(e, st);
    }
  }

  /// POST /api/manager_toggle_2fa.php
  static Future<Map<String, dynamic>> toggle2FA({
    required int adminId,
    required bool enabled,
  }) async {
    final uri = Uri.parse(ServiceBaseUrl.endpoint('manager_toggle_2fa.php'));
    try {
      final res = await http
          .post(
            uri,
            headers: _jsonHeaders,
            body: {'admin_id': '$adminId', 'enabled': enabled ? '1' : '0'},
          )
          .timeout(const Duration(seconds: 20));
      return _decode(res);
    } catch (e, st) {
      throw _error(e, st);
    }
  }

  /// POST multipart /api/manager_upload_avatar.php
  static Future<Map<String, dynamic>> uploadAvatar({
    required int adminId,
    required File file,
  }) async {
    final uri = Uri.parse(ServiceBaseUrl.endpoint('manager_upload_avatar.php'));
    try {
      final req =
          http.MultipartRequest('POST', uri)
            ..fields['admin_id'] = '$adminId'
            ..files.add(await http.MultipartFile.fromPath('file', file.path));
      final streamed = await req.send().timeout(const Duration(seconds: 30));
      final res = await http.Response.fromStream(streamed);
      return _decode(res);
    } catch (e, st) {
      throw _error(e, st);
    }
  }
}
