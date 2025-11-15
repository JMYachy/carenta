import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:carenta/service/config/service_base_url.dart';

class ManagerVerificationService {
  static const Duration _timeout = Duration(seconds: 20);

  static Uri _listUri(String status) {
    // status: pending | approved | rejected | all
    final safe = (status.isEmpty ? 'pending' : status).toLowerCase();
    final base = ServiceBaseUrl.endpoint('user_verification_list.php');
    return Uri.parse('$base?status=$safe');
  }

  static Map<String, String> _jsonHeaders() => {'Accept': 'application/json'};

  static Map<String, String> _formHeaders() => {
    'Accept': 'application/json',
    'Content-Type': 'application/x-www-form-urlencoded',
  };

  static Map<String, dynamic> _ok({dynamic data, String? message}) => {
    'success': true,
    'data': data,
    if (message != null) 'message': message,
  };

  static Map<String, dynamic> _fail(String message) => {
    'success': false,
    'message': message,
  };

  static dynamic _safeDecode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  /// Fetch verifications by status:
  /// - 'pending' (default)
  /// - 'approved'
  /// - 'rejected'
  /// - 'all'
  static Future<Map<String, dynamic>> fetchVerifications([
    String status = 'pending',
  ]) async {
    try {
      final resp = await http
          .get(_listUri(status), headers: _jsonHeaders())
          .timeout(_timeout);

      if (resp.statusCode != 200) {
        return _fail(
          'Server error: ${resp.statusCode} (${resp.reasonPhrase ?? 'Unknown'})',
        );
      }

      final data = _safeDecode(resp.body);
      if (data is! Map) return _fail('Invalid server response');

      if (data['success'] == true) {
        final list =
            (data['data'] is List)
                ? List<Map<String, dynamic>>.from(data['data'])
                : <Map<String, dynamic>>[];
        return _ok(data: list, message: data['message']?.toString());
      }

      return _fail(data['message']?.toString() ?? 'Failed to fetch data');
    } on SocketException catch (e) {
      return _fail('Network error: ${e.message}');
    } on TimeoutException {
      return _fail('Request timed out. Please try again.');
    } catch (e) {
      return _fail('Unexpected error: $e');
    }
  }

  /// Submit a review decision.
  /// action: 'approved' or 'rejected'
  static Future<Map<String, dynamic>> reviewVerification({
    required int userId,
    required String action,
    String? notes,
  }) async {
    final normalized = action.toLowerCase().trim();
    if (normalized != 'approved' && normalized != 'rejected') {
      return _fail("Invalid action. Use 'approved' or 'rejected'.");
    }

    final url = ServiceBaseUrl.endpoint('review_verification.php');

    try {
      final resp = await http
          .post(
            Uri.parse(url),
            headers: _formHeaders(),
            body: {
              'userid': userId.toString(),
              'action': normalized,
              'notes': notes?.trim() ?? '',
            },
          )
          .timeout(_timeout);

      final decoded = _safeDecode(resp.body);

      if (resp.statusCode != 200) {
        // Try to surface backend message if present
        final msg =
            (decoded is Map && decoded['message'] is String)
                ? decoded['message'] as String
                : 'Server error: ${resp.statusCode}';
        return _fail(msg);
      }

      if (decoded is! Map) {
        return _fail('Invalid server response');
      }

      if (decoded['success'] == true) {
        return _ok(
          data: decoded['data'] ?? {},
          message: decoded['message']?.toString() ?? 'Action successful.',
        );
      }

      return _fail(
        decoded['message']?.toString() ?? 'Failed to process review.',
      );
    } on SocketException catch (e) {
      return _fail('Network error: ${e.message}');
    } on TimeoutException {
      return _fail('Request timed out. Please try again.');
    } catch (e) {
      return _fail('Unexpected error: $e');
    }
  }

  // Optional convenience wrappers:
  static Future<Map<String, dynamic>> approve(int userId) =>
      reviewVerification(userId: userId, action: 'approved');

  static Future<Map<String, dynamic>> reject(int userId, {String? notes}) =>
      reviewVerification(userId: userId, action: 'rejected', notes: notes);
}
