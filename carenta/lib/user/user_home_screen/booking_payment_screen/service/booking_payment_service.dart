import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:carenta/service/config/service_base_url.dart';

/// BookingPaymentService
/// Handles PayMongo checkout creation and payment polling.
class BookingPaymentService {
  final http.Client _client;

  BookingPaymentService({http.Client? client})
    : _client = client ?? http.Client();

  /// ================================================================
  /// 🔵 CREATE PAYMONGO CHECKOUT SESSION
  /// Rental is NOT created here — only stored metadata for webhook.
  /// ================================================================
  Future<Map<String, dynamic>> createCheckout({
    required int userId,
    required int carId,
    required String startDate,
    required String startTime,
    required String endDate,
    required String endTime,
    required String pickupLocation,
    required String dropoffLocation,
    required double amount,
    required String method, // gcash | card
    String phase = 'full', // full | deposit
    double depositPercent = 30.0,
  }) async {
    final url = ServiceBaseUrl.endpoint("paymongo_create_checkout.php");

    // 🔥 IMPORTANT:
    // - `rentalid` is 0 because rental is created AFTER payment by webhook
    // - `userid`, `amount`, `method`, etc. match your PHP script
    // - extra booking fields used as metadata in PHP → PayMongo
    final body = {
      "rentalid": 0, // placeholder rental (real rental created after payment)
      "userid": userId,
      "amount": amount,
      "method": method.toLowerCase(),
      "payment_phase": phase,
      "deposit_percent": depositPercent,

      // Booking metadata for PHP / PayMongo metadata:
      "car_id": carId,
      "start_date": startDate,
      "start_time": startTime,
      "end_date": endDate,
      "end_time": endTime,
      "pickup_location": pickupLocation,
      "dropoff_location": dropoffLocation,
    };

    final res = await _client.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) {
      throw Exception("HTTP ${res.statusCode}: ${res.body}");
    }

    final decoded = jsonDecode(res.body);

    if (decoded is! Map || decoded["success"] != true) {
      throw Exception(decoded["message"] ?? "Failed to create checkout");
    }

    return {
      "success": true,
      "checkoutUrl": decoded["checkout_url"],
      "referenceNo": decoded["reference_no"],
      "paymentId": decoded["paymentid"],
      "transactionId": decoded["transaction_id"],
    };
  }

  /// ================================================================
  /// 🔵 CHECK PAYMENT STATUS
  /// Uses payment_status.php?ref=... (returns payment + rental)
  /// Returns: pending | paid | failed | refunded
  /// ================================================================
  Future<String> checkPaymentStatus(String referenceNo) async {
    if (referenceNo.isEmpty) {
      throw Exception("Reference number is required");
    }

    final uri = Uri.parse(
      ServiceBaseUrl.endpoint("payment_status.php?ref=$referenceNo"),
    );

    final res = await _client.get(uri);

    if (res.statusCode != 200) {
      throw Exception("HTTP ${res.statusCode}: ${res.body}");
    }

    final decoded = jsonDecode(res.body);

    if (decoded is! Map || decoded["success"] != true) {
      throw Exception(decoded["message"] ?? "Failed to fetch payment status");
    }

    final payment = decoded["payment"] ?? {};

    return (payment["status"] ?? "unknown").toString().toLowerCase();
  }

  /// ================================================================
  /// 🔵 Fetch full payment & rental detail (optional usage)
  /// ================================================================
  Future<Map<String, dynamic>?> fetchPaymentDetail(String referenceNo) async {
    final uri = Uri.parse(
      ServiceBaseUrl.endpoint("payment_status.php?ref=$referenceNo"),
    );

    final res = await _client.get(uri);
    if (res.statusCode != 200) return null;

    final decoded = jsonDecode(res.body);
    if (decoded is! Map || decoded["success"] != true) return null;

    return {"payment": decoded["payment"], "rental": decoded["rental"]};
  }

  void close() => _client.close();
}
