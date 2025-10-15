import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:carenta/service/config/service_base_url.dart';

class UserBookingService {
  final http.Client _client;

  UserBookingService({http.Client? client}) : _client = client ?? http.Client();

  /// ✅ Automatically uses your ServiceBaseUrl
  String get _endpoint => ServiceBaseUrl.endpoint("get_booking.php");

  /// Fetch user’s booking list
  Future<Map<String, dynamic>> fetchUserBookings({
    required int userId,
    String? status,
    int limit = 50,
    int offset = 0,
    String order = 'desc',
  }) async {
    final uri = Uri.parse(_endpoint).replace(
      queryParameters: {
        'user_id': userId.toString(),
        if (status != null && status.isNotEmpty) 'status': status,
        'limit': limit.toString(),
        'offset': offset.toString(),
        'order': order,
      },
    );

    debugPrint('📡 GET $uri');

    final resp = await _client.get(uri);
    final bodyText = resp.body;

    debugPrint('Response ${resp.statusCode}');
    if (bodyText.isNotEmpty) {
      debugPrint(
        bodyText.length > 400 ? '${bodyText.substring(0, 400)}...' : bodyText,
      );
    }

    if (resp.statusCode != 200) {
      throw Exception('Server error: ${resp.statusCode}\n$bodyText');
    }

    // ✅ Check if response looks like JSON
    final trimmed = bodyText.trimLeft();
    final looksJson = trimmed.startsWith('{') || trimmed.startsWith('[');
    if (!looksJson) {
      throw Exception('Expected JSON but got:\n${trimmed.substring(0, 200)}');
    }

    final data = jsonDecode(trimmed);

    // ✅ Handle successful response
    if (data is Map && (data['ok'] == true || data['status'] == 'success')) {
      final List<dynamic> bookings = data['data'] ?? [];

      return {
        "status": "success",
        "message": data['message'] ?? "Bookings fetched",
        "count": data['count'] ?? bookings.length,
        "data": bookings,
      };
    }

    // ❌ Handle error response
    return {
      "success": false,
      "message":
          (data is Map ? (data['message'] ?? data['error']) : "Unknown error"),
    };
  }

  void close() => _client.close();
}
