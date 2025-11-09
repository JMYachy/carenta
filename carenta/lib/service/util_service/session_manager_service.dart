import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:carenta/service/config/service_base_url.dart';

/// ✅ Handles login, session checking, and logout for Carenta.
/// Uses: https://carentaph.com/api/session_manager.php
class SessionManagerService {
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
      String loginInput, String password) async {
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
      return (data is Map<String, dynamic>) ? data : _error("Invalid response");
    } on SocketException catch (e) {
      return _error("Network unreachable: ${e.message}");
    } catch (e) {
      return _error("Login error: $e");
    }
  }

  /// 🔍 Check if there’s an active session on the server
  static Future<Map<String, dynamic>> checkSession({int retries = 1}) async {
    try {
      debugPrint("🔗 Checking session at: $_url?action=check");
      final resp = await _client.get(
        Uri.parse("$_url?action=check"),
        headers: _headers(),
      );

      final data = jsonDecode(resp.body);
      if (resp.statusCode != 200 || data is! Map<String, dynamic>) {
        return _error("Invalid server response");
      }
      return data;
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

  /// 🚪 Logout the current session
  static Future<Map<String, dynamic>> logout() async {
    try {
      final resp = await _client.post(
        Uri.parse(_url),
        headers: _headers(form: true),
        body: {"action": "logout"},
      );
      _cookie = null;
      final data = jsonDecode(resp.body);
      return (data is Map<String, dynamic>) ? data : _error("Invalid response");
    } catch (e) {
      return _error("Logout error: $e");
    }
  }

  static Future<_SessionUser?> getSession() async {
    final result = await checkSession();
    if (result['success'] == true || result['ok'] == true) {
      final data = result['data'];
      if (data is Map<String, dynamic> && data['userid'] != null) {
        return _SessionUser(
          userId: int.tryParse(data['userid'].toString()) ?? 0,
          username: data['username']?.toString(),
          email: data['email']?.toString(),
        );
      }
    }
    return null;
  }

  static void clearSessionCookie() => _cookie = null;

  static Map<String, dynamic> _error(String msg) =>
      {"success": false, "status": "error", "message": msg};
}

class _SessionUser {
  final int userId;
  final String? username;
  final String? email;

  _SessionUser({required this.userId, this.username, this.email});
}
