import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:carenta/utils/session_manager.dart';
import 'package:carenta/service/config/service_base_url.dart';

class LoginService {
  // Instead of hardcoding, use the global base URL
  final String endpoint;

  const LoginService({
    this.endpoint = '', // default empty — will be auto-resolved below
  });

  // Normalize any Map to Map<String, dynamic>
  Map<String, dynamic> _toMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) {
      return v.map((k, val) => MapEntry(k.toString(), val));
    }
    return <String, dynamic>{};
  }

  int? _toInt(dynamic v) =>
      v == null ? null : (v is int ? v : int.tryParse('$v'));

  Future<Map<String, dynamic>> login(
    String loginInput,
    String password, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final String url =
        endpoint.isNotEmpty ? endpoint : ServiceBaseUrl.endpoint("login.php");

    try {
      final res = await http
          .post(
            Uri.parse(url),
            body: {'username': loginInput, 'password': password},
          )
          .timeout(timeout);

      if (res.statusCode != 200) {
        return {"success": false, "message": "Server error: ${res.statusCode}"};
      }

      final raw = res.body.trimLeft();
      if (!(raw.startsWith('{') || raw.startsWith('['))) {
        return {"success": false, "message": "Unexpected server response"};
      }

      final decoded = jsonDecode(raw);
      final root = _toMap(decoded);
      final ok = root['ok'] == true || root['status'] == 'success';

      if (!ok) {
        return {
          "success": false,
          "message": root['message'] ?? root['error'] ?? 'Login failed',
        };
      }

      final data = _toMap(root['data']);
      final src = data.isNotEmpty ? data : root;

      final userId = _toInt(src['user_id']);
      final adminId = _toInt(src['admin_id']);
      final username = (src['username'] ?? loginInput).toString();
      final role =
          (src['role'] ?? (adminId != null ? 'admin' : 'user')).toString();
      final accountType = src['account_type']?.toString();
      final email = src['email']?.toString();
      final avatar = src['profile_picture']?.toString();
      final token = src['token']?.toString();

      await SessionManager.instance.save(
        userId: userId,
        adminId: adminId,
        username: username,
        role: role,
        accountType: accountType,
        email: email,
        avatarUrl: avatar,
        token: token,
        ttl: const Duration(days: 7),
      );

      return {
        "status": "success",
        "message": root['message'] ?? "Login successful",
        "role": role,
        "account_type": accountType,
        "user_id": userId,
        "admin_id": adminId,
      };
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    }
  }

  Future<void> logout() async {
    await SessionManager.instance.clear();
  }
}
