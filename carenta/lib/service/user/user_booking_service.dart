// lib/service/user/user_booking_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class UserBookingService {
  final String endpoint;
  UserBookingService({
    // point to the exact file that exists on your server
    this.endpoint = 'http://10.0.2.2/carenta/api/get_booking.php',
  });

  Future<Map<String, dynamic>> fetchUserBookings({
    required int userId,
    String? status,
    int limit = 50,
    int offset = 0,
    String order = 'desc',
  }) async {
    final uri = Uri.parse(endpoint).replace(queryParameters: {
      'user_id': userId.toString(),
      if (status != null && status.isNotEmpty) 'status': status,
      'limit': limit.toString(),
      'offset': offset.toString(),
      'order': order,
    });

    final resp = await http.get(uri);
    final bodyText = resp.body;

    // helpful for debugging
    debugPrint('GET $uri  => ${resp.statusCode}');
    debugPrint(bodyText.length > 400 ? bodyText.substring(0, 400) : bodyText);

    if (resp.statusCode != 200) {
      throw Exception('Server error: ${resp.statusCode}\n$bodyText');
    }

    // If the server ever returns HTML/PHP error, avoid FormatException
    final trimmed = bodyText.trimLeft();
    final looksJson = trimmed.startsWith('{') || trimmed.startsWith('[');
    if (!looksJson) {
      throw Exception('Expected JSON but got:\n${trimmed.substring(0, 200)}');
    }

    final data = jsonDecode(trimmed);
    if (data is Map && data['ok'] == true) {
      return {
        "status": "success",
        "message": "Bookings fetched",
        "count": data['count'] ?? (data['data'] as List?)?.length ?? 0,
        "data": data['data'] ?? [],
      };
    }
    return {
      "success": false,
      "message": (data is Map ? (data['message'] ?? data['error']) : "Unknown error"),
    };
  }
}
