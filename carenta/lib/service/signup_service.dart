import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class SignupService {
  static const String _url = 'http://10.0.2.2/carenta/api/signup.php';
  // Use your PC's LAN IP on a real device, e.g. http://192.168.x.x/carenta/api/signup.php

  static Future<Map<String, dynamic>> signupUser(
    String password,
    String phoneNumber,
  ) async {
    try {
      final uri = Uri.parse(_url);
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {'phone_number': phoneNumber, 'bcrypt': password},
          )
          .timeout(const Duration(seconds: 15));

      Map<String, dynamic> data;
      try {
        data = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {
        return {
          'status': 'error',
          'message': 'Invalid server response',
          'raw': res.body,
        };
      }

      // Normalize: always return a {status, message, ...}
      final status = (data['status'] ?? '').toString();
      final message = (data['message'] ?? '').toString();

      if (res.statusCode == 200 && status.isNotEmpty) {
        return data; // e.g., {status: success, message: ..., userid: 123, phone: ...}
      } else {
        return {
          'status': 'error',
          'message': message.isNotEmpty
              ? message
              : 'Server returned ${res.statusCode}',
        };
      }
    } on TimeoutException {
      return {'status': 'error', 'message': 'Request timed out'};
    } catch (e) {
      return {'status': 'error', 'message': 'Error: $e'};
    }
  }
}
