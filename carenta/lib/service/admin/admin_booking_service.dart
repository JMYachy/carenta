// lib/service/admin/admin_booking_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AdminBookingService {
  final String apiRoot;
  const AdminBookingService({this.apiRoot = 'http://10.0.2.2/carenta/api'});

  String get fetchUrl => '$apiRoot/admin_bookings.php';
  String get actionUrl => '$apiRoot/admin_booking_action.php';
  String get timelineUrl => '$apiRoot/admin_dashboard_booking_timelines.php';
  String get activityUrl => '$apiRoot/admin_dashboard_recent_activity.php';

  /// ✅ Fetch all bookings (optionally filtered by status)
  Future<Map<String, dynamic>> fetchBookings({
    String? status,
    int limit = 100,
    int offset = 0,
    String order = 'desc',
  }) async {
    final uri = Uri.parse(fetchUrl).replace(
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        'limit': '$limit',
        'offset': '$offset',
        'order': order,
      },
    );
    debugPrint('GET $uri');

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      return {"success": false, "message": "Server error: ${res.statusCode}"};
    }

    final data = jsonDecode(res.body);

    if (data is Map && (data['ok'] == true || data['status'] == 'success')) {
      final List raw = (data['data'] ?? []) as List;
      final bookings =
          raw.map<Map<String, dynamic>>((row) {
            final r = Map<String, dynamic>.from(row);

            // Normalize optional fields to avoid null-safety crashes in UI
            r['cancellation_reason'] = r['cancellation_reason'] ?? '';
            r['cancelled_by'] = r['cancelled_by'] ?? '';
            r['cancelled_at'] = r['cancelled_at'] ?? '';
            r['admin_notes'] = r['admin_notes'] ?? '';

            return r;
          }).toList();

      return {
        "status": "success",
        "message": "Bookings fetched",
        "count": data['count'] ?? bookings.length,
        "data": bookings,
      };
    }

    return {
      "success": false,
      "message":
          (data is Map ? (data['message'] ?? data['error']) : "Unknown error"),
    };
  }

  /// ✅ Approve booking
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
    if (data is Map && (data['ok'] == true || data['status'] == 'success')) {
      return {
        "status": "success",
        "message": data['message'] ?? "Booking confirmed",
      };
    }
    return {
      "success": false,
      "message": data['message'] ?? data['error'] ?? "Failed to confirm",
    };
  }

  /// ✅ Cancel booking
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
    if (data is Map && (data['ok'] == true || data['status'] == 'success')) {
      return {
        "status": "success",
        "message": data['message'] ?? "Booking cancelled",
      };
    }
    return {
      "success": false,
      "message": data['message'] ?? data['error'] ?? "Failed to cancel",
    };
  }

  /// ✅ Dashboard booking timeline
  Future<List<Map<String, dynamic>>> fetchTimeline() async {
    final res = await http.get(Uri.parse(timelineUrl));
    if (res.statusCode != 200) {
      throw Exception("Server error: ${res.statusCode}");
    }
    final data = jsonDecode(res.body);
    if (data is Map && data['status'] == 'success') {
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    }
    throw Exception(data['message'] ?? "Failed to fetch timeline");
  }

  /// ✅ Dashboard recent activity
  Future<List<Map<String, dynamic>>> fetchRecentActivity() async {
    final res = await http.get(Uri.parse(activityUrl));
    if (res.statusCode != 200) {
      throw Exception("Server error: ${res.statusCode}");
    }
    final data = jsonDecode(res.body);
    if (data is Map && data['status'] == 'success') {
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    }
    throw Exception(data['message'] ?? "Failed to fetch recent activity");
  }
}
