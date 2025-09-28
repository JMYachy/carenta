// lib/service/admin/admin_booking_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AdminBookingService {
  /// Set this to wherever your PHP lives. (Match what WORKS for list.)
  /// e.g. 'http://10.0.2.2/carenta/api'  or  'http://10.0.0.2/carenta/api'
  final String apiRoot;

  const AdminBookingService({
    this.apiRoot = 'http://10.0.2.2/carenta/api',
  });

  String get fetchUrl  => '$apiRoot/admin_bookings.php';
  String get actionUrl => '$apiRoot/admin_booking_action.php';

  Future<Map<String, dynamic>> fetchBookings({
    String? status,
    int limit = 100,
    int offset = 0,
    String order = 'desc',
  }) async {
    final uri = Uri.parse(fetchUrl).replace(queryParameters: {
      if (status != null && status.isNotEmpty) 'status': status,
      'limit': '$limit',
      'offset': '$offset',
      'order': order,
    });
    debugPrint('GET $uri');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      return {"success": false, "message": "Server error: ${res.statusCode}"};
    }
    final data = jsonDecode(res.body);
    if (data is Map && data['ok'] == true) {
      return {
        "status": "success",
        "message": "Bookings fetched",
        "count": data['count'] ?? (data['data'] as List?)?.length ?? 0,
        "data": data['data'] ?? [],
      };
    }
    return {"success": false, "message": (data is Map ? (data['message'] ?? data['error']) : "Unknown error")};
  }

  Future<Map<String, dynamic>> approveBooking({
    required int rentalId,
    required int adminId,
  }) async {
    final uri = Uri.parse(actionUrl);
    final body = {
      'rental_id': '$rentalId',
      'action': 'confirm',
      'admin_id': '$adminId',
    };
    debugPrint('POST $uri  body=$body');
    final res = await http.post(uri, body: body);
    debugPrint('RESP ${res.statusCode}: ${res.body}');
    if (res.statusCode != 200) {
      return {"success": false, "message": "Server error: ${res.statusCode}"};
    }
    final data = jsonDecode(res.body);
    if (data is Map && data['ok'] == true) {
      return {"status": "success", "message": data['message'] ?? "Booking confirmed"};
    }
    return {"success": false, "message": data['message'] ?? data['error'] ?? "Failed to confirm"};
  }

  Future<Map<String, dynamic>> cancelBooking({
    required int rentalId,
    required int adminId,
    String? reason,
  }) async {
    final uri = Uri.parse(actionUrl);
    final body = {
      'rental_id': '$rentalId',
      'action': 'cancel',
      'admin_id': '$adminId',
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    };
    debugPrint('POST $uri  body=$body');
    final res = await http.post(uri, body: body);
    debugPrint('RESP ${res.statusCode}: ${res.body}');
    if (res.statusCode != 200) {
      return {"success": false, "message": "Server error: ${res.statusCode}"};
    }
    final data = jsonDecode(res.body);
    if (data is Map && data['ok'] == true) {
      return {"status": "success", "message": data['message'] ?? "Booking cancelled"};
    }
    return {"success": false, "message": data['message'] ?? data['error'] ?? "Failed to cancel"};
  }
}
