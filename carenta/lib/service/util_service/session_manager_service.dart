import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:carenta/service/config/service_base_url.dart';

/// ===============================================================
/// SESSION MANAGER SERVICE (Users + Managers)
/// Matches updated session_manager.php on server
/// ===============================================================
class SessionManagerService {
  static final String _url = ServiceBaseUrl.endpoint("session_manager.php");
  static final http.Client _client = http.Client();
  static String? _cookie; // Stores PHPSESSID

  /// ---------------------------------------------------------------
  /// INTERNAL HELPERS
  /// ---------------------------------------------------------------
  static Map<String, String> _headers({bool form = false}) {
    return {
      if (form) "Content-Type": "application/x-www-form-urlencoded",
      "Accept": "application/json",
      if (_cookie != null) "Cookie": _cookie!,
    };
  }

  static void _captureCookie(http.Response resp) {
    final setCookie = resp.headers['set-cookie'] ?? resp.headers['Set-Cookie'];
    if (setCookie != null) {
      final sess = setCookie
          .split(';')
          .firstWhere(
            (p) => p.trim().toLowerCase().startsWith('phpsessid='),
            orElse: () => '',
          );
      if (sess.isNotEmpty) _cookie = sess.trim();
    }
  }

  /// ---------------------------------------------------------------
  /// LOGIN
  /// ---------------------------------------------------------------
  static Future<Map<String, dynamic>> login(
    String loginInput,
    String password,
  ) async {
    try {
      final resp = await _client.post(
        Uri.parse(_url),
        headers: _headers(form: true),
        body: {
          "action": "login",
          "email": loginInput,
          "username": loginInput,
          "password": password,
        },
      );

      _captureCookie(resp);

      final data = jsonDecode(resp.body);
      return (data is Map<String, dynamic>)
          ? data
          : _error("Invalid response structure");
    } on SocketException catch (e) {
      return _error("Network unreachable: ${e.message}");
    } catch (e) {
      return _error("Login error: $e");
    }
  }

  /// ---------------------------------------------------------------
  /// CHECK SESSION
  /// ---------------------------------------------------------------
  static Future<Map<String, dynamic>> checkSession({int retries = 1}) async {
    try {
      debugPrint("🔗 Checking session at $_url?action=check");

      final resp = await _client.get(
        Uri.parse("$_url?action=check"),
        headers: _headers(),
      );

      if (resp.statusCode != 200) {
        return _error("HTTP ${resp.statusCode}: ${resp.body}");
      }

      final data = jsonDecode(resp.body);

      // ❗ PRINT FOR VERIFICATION DEBUGGING
      debugPrint("SESSION CHECK RAW: ${resp.body}");

      if (data is Map<String, dynamic>) {
        return data;
      }

      return _error("Invalid server response");
    } on SocketException catch (e) {
      if (retries > 0) {
        debugPrint("⚠️ Host lookup failed, retrying...");
        await Future.delayed(const Duration(seconds: 1));
        return checkSession(retries: retries - 1);
      }
      return _error("Host lookup failed: ${e.message}");
    } catch (e) {
      return _error("Session check failed: $e");
    }
  }

  /// ---------------------------------------------------------------
  /// LOGOUT
  /// ---------------------------------------------------------------
  static Future<Map<String, dynamic>> logout() async {
    try {
      final resp = await _client.post(
        Uri.parse(_url),
        headers: _headers(form: true),
        body: {"action": "logout"},
      );
      _cookie = null;

      final data = jsonDecode(resp.body);
      return (data is Map<String, dynamic>)
          ? data
          : _error("Invalid response format");
    } catch (e) {
      return _error("Logout error: $e");
    }
  }

  /// ---------------------------------------------------------------
  /// UNIFIED SESSION MODEL (User + Admin)
  /// ---------------------------------------------------------------
  static Future<SessionAccount?> getSession() async {
    final result = await checkSession();

    final ok = result['success'] == true || result['ok'] == true;
    if (!ok) return null;

    final data = result['data'] ?? result;
    if (data is! Map<String, dynamic>) return null;

    return SessionAccount(
      userId: int.tryParse(data['userid']?.toString() ?? '0') ?? 0,
      adminId: int.tryParse(data['adminid']?.toString() ?? '0') ?? 0,
      role: data['role']?.toString() ?? '',
      username: data['username']?.toString(),
      email: data['email']?.toString(),

      accountType: data['account_type']?.toString(),

      // 🔥 NEW — expose verification straight into the model
      isVerified: _parseBool(data['is_verified']),
      status: data['status']?.toString(),
    );
  }

  /// Small helper for weird types (0,1,"1","true")
  static bool _parseBool(dynamic v) {
    return v == 1 || v == true || v == '1' || v == 'true' || v == 'verified';
  }

  /// ---------------------------------------------------------------
  /// UTILITIES
  /// ---------------------------------------------------------------
  static void clearSessionCookie() => _cookie = null;

  static Map<String, dynamic> _error(String msg) => {
    "success": false,
    "status": "error",
    "message": msg,
  };
}

/// ===============================================================
/// MODEL: unified User/Admin session object
/// ===============================================================
class SessionAccount {
  final int userId;
  final int adminId;
  final String role;
  final String? username;
  final String? email;
  final String? accountType;

  final bool isVerified; // 🔥 NEW
  final String? status; // 🔥 NEW

  SessionAccount({
    required this.userId,
    required this.adminId,
    required this.role,
    this.username,
    this.email,
    this.accountType,

    required this.isVerified,
    this.status,
  });

  bool get isManager => role.toLowerCase() == 'manager';
  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isUser => role.toLowerCase() == 'user';

  @override
  String toString() {
    return 'SessionAccount(userId: $userId, adminId: $adminId, role: $role, '
        'username: $username, email: $email, '
        'isVerified: $isVerified, status: $status)';
  }
}
