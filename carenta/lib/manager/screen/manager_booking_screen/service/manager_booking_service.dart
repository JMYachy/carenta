// lib/service/manager/manager_booking_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:carenta/service/config/service_base_url.dart';

/// 🔹 ManagerBookingService
/// Handles all CRUD actions for manager bookings, including:
/// - Fetching bookings by status
/// - Approving / Cancelling bookings
/// - Recording Pickup / Dropoff events
class ManagerBookingService {
  final http.Client _client;

  ManagerBookingService({http.Client? client})
      : _client = client ?? http.Client();

  // 🧩 API endpoints
  String get fetchUrl => ServiceBaseUrl.endpoint("manager_bookings.php");
  String get actionUrl => ServiceBaseUrl.endpoint("manager_booking_action.php");
  String get pickupUrl => ServiceBaseUrl.endpoint("manager_record_pickup.php");
  String get dropoffUrl => ServiceBaseUrl.endpoint("manager_record_dropoff.php");

  /// ✅ Fetch bookings (optionally filtered by status)
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

    try {
      final res = await _client.get(uri);
      if (res.statusCode != 200) {
        return {"success": false, "message": "Server error: ${res.statusCode}"};
      }

      final data = jsonDecode(res.body);
      if (data is Map && (data['ok'] == true || data['status'] == 'success')) {
        final List raw = (data['data'] ?? []) as List;
        final bookings = raw.map<Map<String, dynamic>>((row) {
          final r = Map<String, dynamic>.from(row);
          r['cancellation_reason'] = r['cancellation_reason'] ?? '';
          r['cancelled_by'] = r['cancelled_by'] ?? '';
          r['cancelled_at'] = r['cancelled_at'] ?? '';
          r['admin_notes'] = r['admin_notes'] ?? '';
          r['pickup_location'] = r['pickup_location'] ?? '';
          r['dropoff_location'] = r['dropoff_location'] ?? '';
          r['start_date'] = r['start_date'] ?? '';
          r['start_time'] = r['start_time'] ?? '';
          r['end_date'] = r['end_date'] ?? '';
          r['end_time'] = r['end_time'] ?? '';
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
        "message": data is Map
            ? (data['message'] ?? data['error'] ?? "Unknown error")
            : "Unexpected server response",
      };
    } catch (e, st) {
      if (kDebugMode) debugPrint("fetchBookings error: $e\n$st");
      return {"success": false, "message": "Exception: $e"};
    }
  }

  /// ✅ Approve booking (Confirm)
  Future<Map<String, dynamic>> approveBooking({
    required int rentalId,
    required int managerId,
  }) async {
    final uri = Uri.parse(actionUrl);
    final body = {
      'rental_id': '$rentalId',
      'action': 'confirm',
      'admin_id': '$managerId',
    };
    debugPrint('POST $uri  body=$body');

    try {
      final res = await _client.post(uri, body: body);
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
        "message":
            data['message'] ?? data['error'] ?? "Failed to confirm booking",
      };
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  /// ✅ Cancel booking
  Future<Map<String, dynamic>> cancelBooking({
    required int rentalId,
    required int managerId,
    String? reason,
  }) async {
    final uri = Uri.parse(actionUrl);
    final body = {
      'rental_id': '$rentalId',
      'action': 'cancel',
      'admin_id': '$managerId',
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    };
    debugPrint('POST $uri  body=$body');

    try {
      final res = await _client.post(uri, body: body);
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
        "message":
            data['message'] ?? data['error'] ?? "Failed to cancel booking",
      };
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  /// ✅ Record car pickup (set to ongoing)
  Future<Map<String, dynamic>> recordPickup({
    required int rentalId,
    required int managerId,
    String? remark,
  }) async {
    final uri = Uri.parse(pickupUrl);
    final body = {
      'rental_id': '$rentalId',
      'manager_id': '$managerId',
      'action': 'pickup',
      if (remark != null && remark.isNotEmpty) 'remark': remark,
    };
    debugPrint('POST $uri  body=$body');

    try {
      final res = await _client.post(uri, body: body);
      debugPrint('RESP ${res.statusCode}: ${res.body}');
      if (res.statusCode != 200) {
        return {"success": false, "message": "Server error: ${res.statusCode}"};
      }

      final data = jsonDecode(res.body);
      if (data is Map && (data['ok'] == true || data['status'] == 'success')) {
        return {
          "status": "success",
          "message": data['message'] ?? "Pickup recorded successfully",
        };
      }
      return {
        "success": false,
        "message": data['message'] ?? data['error'] ?? "Failed to record pickup",
      };
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  /// ✅ Record car dropoff (set to completed)
  Future<Map<String, dynamic>> recordDropoff({
    required int rentalId,
    required int managerId,
    String? remark,
  }) async {
    final uri = Uri.parse(dropoffUrl);
    final body = {
      'rental_id': '$rentalId',
      'manager_id': '$managerId',
      'action': 'dropoff',
      if (remark != null && remark.isNotEmpty) 'remark': remark,
    };
    debugPrint('POST $uri  body=$body');

    try {
      final res = await _client.post(uri, body: body);
      debugPrint('RESP ${res.statusCode}: ${res.body}');
      if (res.statusCode != 200) {
        return {"success": false, "message": "Server error: ${res.statusCode}"};
      }

      final data = jsonDecode(res.body);
      if (data is Map && (data['ok'] == true || data['status'] == 'success')) {
        return {
          "status": "success",
          "message": data['message'] ?? "Drop-off recorded successfully",
        };
      }
      return {
        "success": false,
        "message":
            data['message'] ?? data['error'] ?? "Failed to record drop-off",
      };
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  void close() => _client.close();
}
