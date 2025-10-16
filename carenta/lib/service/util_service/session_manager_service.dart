import 'dart:convert';
import 'package:carenta/service/config/service_base_url.dart';
import 'package:http/http.dart' as http;

/// Handles login, session checking, and logout for Carenta.
/// Communicates with: https://carentaph.com/api/session_manager.php
class SessionService {
  static final String _url = ServiceBaseUrl.endpoint("session_manager.php");
  static final http.Client _client = http.Client();

  static String? _cookie; // stores "PHPSESSID=xxxx"

  /// Build common headers (with cookie if available)
  static Map<String, String> _headers({bool form = false}) {
    return {
      if (form) "Content-Type": "application/x-www-form-urlencoded",
      "Accept": "application/json",
      if (_cookie != null) "Cookie": _cookie!,
    };
  }

  /// Capture and store the PHPSESSID cookie from server
  static void _captureCookie(http.Response resp) {
    final setCookie = resp.headers['set-cookie'] ?? resp.headers['Set-Cookie'];
    if (setCookie != null) {
      // Example: "PHPSESSID=abc123; path=/; HttpOnly"
      final sess = setCookie
          .split(';')
          .firstWhere(
            (p) => p.trim().toLowerCase().startsWith('phpsessid='),
            orElse: () => '',
          );
      if (sess.isNotEmpty) _cookie = sess.trim();
    }
  }

  /// 🔐 Login (email / username / phone accepted)
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

      if (resp.statusCode != 200) {
        throw Exception("Server error: ${resp.statusCode}");
      }

      final data = jsonDecode(resp.body);
      if (data is! Map<String, dynamic>) {
        throw Exception("Invalid server response");
      }

      return data;
    } catch (e) {
      return {"success": false, "status": "error", "message": e.toString()};
    }
  }

  /// 🔍 Check if there’s an active session on the server
  static Future<Map<String, dynamic>> checkSession() async {
    try {
      final resp = await _client.get(
        Uri.parse("$_url?action=check"),
        headers: _headers(),
      );

      if (resp.statusCode != 200) {
        throw Exception("Server error: ${resp.statusCode}");
      }

      final data = jsonDecode(resp.body);
      if (data is! Map<String, dynamic>) {
        throw Exception("Invalid server response");
      }

      return data;
    } catch (e) {
      return {"success": false, "status": "error", "message": e.toString()};
    }
  }

  /// 🚪 Logout the current session
  static Future<Map<String, dynamic>> logout() async {
    try {
      final resp = await _client.post(
        Uri.parse(_url),
        headers: _headers(form: true),
        body: {"action": "logout"},
      );

      _cookie = null; // clear local session
      final data = jsonDecode(resp.body);
      return data is Map<String, dynamic>
          ? data
          : {
            "success": false,
            "status": "error",
            "message": "Invalid response",
          };
    } catch (e) {
      return {"success": false, "status": "error", "message": e.toString()};
    }
  }

  /// 🧹 Clear cookie manually (optional for logout safety)
  static void clearSessionCookie() => _cookie = null;
}
