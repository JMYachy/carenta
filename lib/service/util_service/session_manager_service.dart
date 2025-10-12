import 'dart:convert';
import 'package:carenta/service/config/service_base_url.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static final String _url = ServiceBaseUrl.endpoint('session_manager.php');
  static final http.Client _client = http.Client();
  static String? _cookie;

  // Initialize on app startup
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _cookie = prefs.getString('session_cookie');
  }

  static Map<String, String> _headers({bool json = false}) {
    return {
      if (json) "Content-Type": "application/x-www-form-urlencoded",
      "Accept": "application/json",
      if (_cookie != null) "Cookie": _cookie!,
    };
  }

  static void _captureCookie(http.Response resp) async {
    final setCookie = resp.headers['set-cookie'] ?? resp.headers['Set-Cookie'];
    if (setCookie != null) {
      final parts = setCookie.split(';');
      if (parts.isNotEmpty) {
        final sess = parts.first.trim();
        if (sess.toLowerCase().startsWith('phpsessid=')) {
          _cookie = sess;

          // persist cookie locally
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('session_cookie', sess);
        }
      }
    }
  }

  /// Login
  static Future<Map<String, dynamic>> login(
    String loginInput,
    String password,
  ) async {
    final resp = await _client.post(
      Uri.parse(_url),
      headers: _headers(json: true),
      body: {
        "action": "login",
        "email": loginInput,
        "username": loginInput,
        "password": password,
      },
    );
    _captureCookie(resp);
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  /// Check session
  static Future<Map<String, dynamic>> checkSession() async {
    final resp = await _client.get(
      Uri.parse("$_url?action=check"),
      headers: _headers(),
    );
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  /// Logout
  static Future<Map<String, dynamic>> logout() async {
    final resp = await _client.post(
      Uri.parse(_url),
      headers: _headers(json: true),
      body: {"action": "logout"},
    );

    // clear local cookie
    _cookie = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_cookie');

    return jsonDecode(resp.body) as Map<String, dynamic>;
  }
}
