import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:carenta/service/config/service_base_url.dart';

/// ===============================================================
/// 🧩 ManagerBookingService
/// Handles all CRUD and status-cycle operations for manager bookings:
///   pending → confirmed → ongoing → completed / cancelled
///
/// PHP endpoints used:
///   - manager_bookings.php (GET)
///   - manager_booking_action.php (POST: confirm | cancel)
///   - manager_record_pickup.php (POST: pickup)
///   - manager_record_dropoff.php (POST: dropoff)
/// ===============================================================
class ManagerBookingService {
  final http.Client _client;
  ManagerBookingService({http.Client? client})
    : _client = client ?? http.Client();

  // === API endpoints ===
  String get fetchUrl => ServiceBaseUrl.endpoint("manager_bookings.php");
  String get actionUrl => ServiceBaseUrl.endpoint("manager_booking_action.php");
  String get pickupUrl => ServiceBaseUrl.endpoint("manager_record_pickup.php");
  String get dropoffUrl =>
      ServiceBaseUrl.endpoint("manager_record_dropoff.php");

  // ============================================================
  // ✅ Fetch Bookings (optionally by status)
  // ============================================================
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

    try {
      final res = await _client.get(uri);
      if (res.statusCode != 200) {
        return {"ok": false, "message": "Server error: ${res.statusCode}"};
      }

      final data = jsonDecode(res.body);
      if (data is Map && data['ok'] == true) {
        final List bookings = (data['data'] ?? []) as List;
        return {
          "ok": true,
          "count": data['count'] ?? bookings.length,
          "message": "Bookings fetched successfully",
          "data": bookings,
        };
      }
      return {
        "ok": false,
        "message":
            data is Map
                ? (data['message'] ?? data['error'] ?? "Unknown error")
                : "Unexpected server response",
      };
    } catch (e, st) {
      if (kDebugMode) debugPrint("fetchBookings error: $e\n$st");
      return {"ok": false, "message": "Exception: $e"};
    }
  }

  // ============================================================
  // ✅ Common POST action handler
  // ============================================================
  Future<Map<String, dynamic>> _post(
    String url,
    Map<String, String> body, {
    String successMsg = 'Action successful',
  }) async {
    debugPrint('[POST] $url  BODY=$body');
    try {
      final res = await _client.post(Uri.parse(url), body: body);
      debugPrint('[RESP] ${res.statusCode}: ${res.body}');
      if (res.statusCode != 200) {
        return {"ok": false, "message": "Server error: ${res.statusCode}"};
      }

      final data = jsonDecode(res.body);
      if (data is Map && data['ok'] == true) {
        return {
          "ok": true,
          "status": data['status'],
          "message": data['message'] ?? successMsg,
        };
      }
      return {
        "ok": false,
        "message":
            data is Map
                ? (data['message'] ?? data['error'] ?? "Unknown response")
                : "Invalid response",
      };
    } catch (e, st) {
      if (kDebugMode) debugPrint("_post error: $e\n$st");
      return {"ok": false, "message": "Exception: $e"};
    }
  }

  // ============================================================
  // ✅ Confirm Booking (Pending → Confirmed)
  // ============================================================
  Future<Map<String, dynamic>> confirmBooking({
    required int rentalId,
    required int managerId,
  }) async {
    return _post(actionUrl, {
      'rental_id': '$rentalId',
      'admin_id': '$managerId',
      'action': 'confirm',
    }, successMsg: 'Booking confirmed');
  }

  // ============================================================
  // ✅ Cancel Booking (any stage before completion)
  // ============================================================
  Future<Map<String, dynamic>> cancelBooking({
    required int rentalId,
    required int managerId,
    String? reason,
  }) async {
    return _post(actionUrl, {
      'rental_id': '$rentalId',
      'admin_id': '$managerId',
      'action': 'cancel',
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    }, successMsg: 'Booking cancelled');
  }

  // ============================================================
  // ✅ Record Pickup (Confirmed → Ongoing)
  // ============================================================
  Future<Map<String, dynamic>> recordPickup({
    required int rentalId,
    required int managerId,
    String? remark,
  }) async {
    return _post(pickupUrl, {
      'rental_id': '$rentalId',
      'manager_id': '$managerId',
      'action': 'pickup',
      if (remark != null && remark.isNotEmpty) 'remark': remark,
    }, successMsg: 'Pickup recorded successfully');
  }

  // ============================================================
  // ✅ Record Dropoff (Ongoing → Completed → Maintenance)
  // ============================================================
  Future<Map<String, dynamic>> recordDropoff({
    required int rentalId,
    required int managerId,
    String? remark,
  }) async {
    return _post(dropoffUrl, {
      'rental_id': '$rentalId',
      'manager_id': '$managerId',
      'action': 'dropoff',
      if (remark != null && remark.isNotEmpty) 'remark': remark,
    }, successMsg: 'Drop-off recorded successfully');
  }

  void close() => _client.close();
}
