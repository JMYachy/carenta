import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:carenta/service/config/service_base_url.dart';
import 'package:http/http.dart' as http;

/// Handles updating existing car details and car status (Admin side).
/// Matches the PHP endpoints:
///  - update_car_details.php
///  - update_car_status.php
class AdminEditCarService {
  static final String _updateDetailsEndpoint =
      ServiceBaseUrl.endpoint("update_car_details.php");
  static final String _updateStatusEndpoint =
      ServiceBaseUrl.endpoint("update_car_status.php");

  /// Updates full car information (model, color, transmission, etc.)
  static Future<Map<String, dynamic>> updateCarDetails({
    required int carId,
    Map<String, dynamic>? fields,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final uri = Uri.parse(_updateDetailsEndpoint);

    if (fields == null || fields.isEmpty) {
      return {'success': false, 'message': 'No fields provided to update.'};
    }

    final body = jsonEncode({'carid': carId, ...fields});

    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(timeout);

      return _parseResponse(response);
    } on SocketException {
      return {'success': false, 'message': 'Network error. Please check your connection.'};
    } on TimeoutException {
      return {'success': false, 'message': 'Request timed out. Try again.'};
    } catch (e) {
      return {'success': false, 'message': 'Unexpected error: $e'};
    }
  }

  /// Updates only the status of a car.
  static Future<Map<String, dynamic>> updateCarStatus({
    required int carId,
    required String newStatus,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final uri = Uri.parse(_updateStatusEndpoint);
    final body = jsonEncode({'carid': carId, 'status': newStatus});

    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(timeout);

      return _parseResponse(response);
    } on SocketException {
      return {'success': false, 'message': 'Network error. Please check your connection.'};
    } on TimeoutException {
      return {'success': false, 'message': 'Request timed out. Try again.'};
    } catch (e) {
      return {'success': false, 'message': 'Unexpected error: $e'};
    }
  }

  /// Helper for safe JSON parsing and consistent response structure
  static Map<String, dynamic> _parseResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      } else {
        return {
          'success': false,
          'message': 'Unexpected response format.',
          'raw': decoded,
        };
      }
    } catch (_) {
      return {
        'success': false,
        'message': 'Invalid JSON from server.',
        'statusCode': response.statusCode,
        'body': response.body,
      };
    }
  }
}
