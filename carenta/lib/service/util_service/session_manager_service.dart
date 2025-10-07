import 'dart:convert';
import 'package:http/http.dart' as http;

class SessionService {
  static const String _url = "http://10.0.2.2/carenta/api/session_manager.php";

  static final http.Client _client = http.Client();
  static String? _cookie; // e.g., "PHPSESSID=xxxx"

  static Map<String, String> _headers({bool json = false}) {
    return {
      if (json) "Content-Type": "application/x-www-form-urlencoded",
      "Accept": "application/json",
      if (_cookie != null) "Cookie": _cookie!,
    };
  }

  static void _captureCookie(http.Response resp) {
    final setCookie = resp.headers['set-cookie'] ?? resp.headers['Set-Cookie'];
    if (setCookie != null) {
      // grab the first cookie (PHPSESSID=...)
      final parts = setCookie.split(';');
      if (parts.isNotEmpty) {
        final sess = parts.first.trim();
        if (sess.toLowerCase().startsWith('phpsessid=')) {
          _cookie = sess; // store "PHPSESSID=..."
        }
      }
    }
  }

  /// Login (email OR username accepted)
  static Future<Map<String, dynamic>> login(
    String loginInput,
    String password,
  ) async {
    final resp = await _client.post(
      Uri.parse(_url),
      headers: _headers(json: true),
      body: {
        "action": "login",
        // send in both fields to be safe with any server expectation
        "email": loginInput,
        "username": loginInput,
        "password": password,
      },
    );
    _captureCookie(resp);
    return jsonDecode(resp.body) as Map<String, dynamic>;
    // The server also returns "data.phpsessid" if you want to persist it yourself.
  }

  /// Check active session
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
    // clear cookie on client side
    _cookie = null;
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }
}
