import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:carenta/service/config/service_base_url.dart';

class UserBookingService {
  final http.Client _client;

  UserBookingService({http.Client? client}) : _client = client ?? http.Client();

  /// ✅ Fetch Bookings
  String get _fetchEndpoint => ServiceBaseUrl.endpoint("get_booking.php");

  /// ✅ Booking Action Endpoint
  String get _actionEndpoint =>
      ServiceBaseUrl.endpoint("user_booking_action.php");

  /// 🧾 Fetch user’s booking list
  Future<Map<String, dynamic>> fetchUserBookings({
    required int userId,
    String? status,
    int limit = 50,
    int offset = 0,
    String order = 'desc',
  }) async {
    final uri = Uri.parse(_fetchEndpoint).replace(
      queryParameters: {
        'user_id': userId.toString(),
        if (status != null && status.isNotEmpty) 'status': status,
        'limit': '$limit',
        'offset': '$offset',
        'order': order,
      },
    );

    debugPrint('📡 GET $uri');
    final resp = await _client.get(uri);

    if (resp.statusCode != 200) {
      throw Exception('Server error: ${resp.statusCode}');
    }

    final trimmed = resp.body.trimLeft();
    if (!trimmed.startsWith('{')) {
      throw Exception('Invalid JSON response');
    }

    final data = jsonDecode(trimmed);
    if (data is Map && (data['ok'] == true || data['status'] == 'success')) {
      final bookings = (data['data'] as List?) ?? [];
      return {
        "status": "success",
        "message": data['message'] ?? "Bookings fetched successfully.",
        "data": bookings,
      };
    }

    return {
      "success": false,
      "message": (data is Map ? data['message'] : "Failed to fetch bookings"),
    };
  }

  /// 🚦 Perform booking actions: cancel | confirm | complete
  Future<Map<String, dynamic>> performAction({
    required int rentalId,
    required String action, // cancel | confirm | complete
    String? reason,
  }) async {
    final uri = Uri.parse(_actionEndpoint);
    final body = {
      'rental_id': '$rentalId',
      'action': action,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    };

    debugPrint('📤 POST $uri\nBody: $body');

    final resp = await _client.post(uri, body: body);

    if (resp.statusCode != 200) {
      return {"status": "fail", "message": "HTTP ${resp.statusCode}"};
    }

    final data = jsonDecode(resp.body);
    if (data['ok'] == true) {
      return {
        "status": "success",
        "message": data['message'] ?? "Action successful",
      };
    }

    return {"status": "fail", "message": data['message'] ?? "Action failed"};
  }

  /// 🛑 Shortcut for cancelling booking
  Future<Map<String, dynamic>> cancelBooking(int rentalId, {String? reason}) {
    return performAction(rentalId: rentalId, action: 'cancel', reason: reason);
  }

  /// 🟢 Shortcut for confirming booking
  Future<Map<String, dynamic>> confirmBooking(int rentalId) {
    return performAction(rentalId: rentalId, action: 'confirm');
  }

  /// 🔵 Shortcut for marking as completed
  Future<Map<String, dynamic>> completeBooking(int rentalId) {
    return performAction(rentalId: rentalId, action: 'complete');
  }

  void close() => _client.close();
}
