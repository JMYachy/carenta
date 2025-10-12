// lib/service/admin/admin_booking_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ✅ Import your central base URL config
import 'package:carenta/service/config/service_base_url.dart';

class AdminBookingService {
  // ✅ Define all endpoints using ServiceBaseUrl
  static final String _fetchUrl = ServiceBaseUrl.endpoint('admin_bookings.php');
  static final String _actionUrl = ServiceBaseUrl.endpoint('admin_booking_action.php');
  static final String _timelineUrl = ServiceBaseUrl.endpoint('admin_dashboard_booking_timelines.php');
  static final String _activityUrl = ServiceBaseUrl.endpoint('admin_dashboard_recent_activity.php');

  /// ✅ Fetch all bookings (optionally filtered by status)
  Future<Map<String, dynamic>> fetchBookings({
    String? status,
    int limit = 100,
    int offset = 0,
    String order = 'desc',
  }) async {
    final uri = Uri.parse(_fetchUrl).replace(
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
      final bookings = raw.map<Map<String, dynamic>>((row) {
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
      "message": (data is Map ? (data['message'] ?? data['error']) : "Unknown error"),
    };
  }

  /// ✅ Approve booking
  Future<Map<String, dynamic>> approveBooking({
    required int rentalId,
    required int adminId,
  }) async {
    final uri = Uri.parse(_actionUrl);
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
    final uri = Uri.parse(_actionUrl);
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
    final res = await http.get(Uri.parse(_timelineUrl));
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
    final res = await http.get(Uri.parse(_activityUrl));
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
