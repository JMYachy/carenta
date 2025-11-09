import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:carenta/service/config/service_base_url.dart';

class PayMongoCheckoutResult {
  final bool ok;
  final String? checkoutUrl;
  final int? paymentId;
  final String? referenceNo;
  final String? phase;
  final double? amount;
  final String? message;

  PayMongoCheckoutResult({
    required this.ok,
    this.checkoutUrl,
    this.paymentId,
    this.referenceNo,
    this.phase,
    this.amount,
    this.message,
  });

  factory PayMongoCheckoutResult.fromJson(Map<String, dynamic> json) {
    return PayMongoCheckoutResult(
      ok: json['ok'] ?? false,
      checkoutUrl: json['checkout_url'],
      paymentId: json['payment_id'],
      referenceNo: json['reference_no'],
      phase: json['phase'],
      amount: json['amount'] != null
          ? double.tryParse(json['amount'].toString())
          : null,
      message: json['message'],
    );
  }
}

class BookingPaymentService {
  static Future<PayMongoCheckoutResult> createCheckout({
    required int rentalId,
    required int userId,
    required String phase, // "deposit" or "full"
    double depositPercent = 30.0,
  }) async {
    final url = Uri.parse(ServiceBaseUrl.endpoint('paymongo_create_checkout.php'));

    // ✅ Send as form data (not JSON)
    final body = {
      'rental_id': rentalId.toString(),
      'user_id': userId.toString(),
      'payment_phase': phase,
      'deposit_percent': depositPercent.toString(),
    };

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'}, // ✅ changed
      body: body, // ✅ not jsonEncode()
    );

    print("📤 Sent PayMongo body: $body");
    print("📡 Response ${res.statusCode}: ${res.body}");

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return PayMongoCheckoutResult.fromJson(data);
    } else {
      throw Exception('HTTP ${res.statusCode}: ${res.reasonPhrase}');
    }
  }
}
