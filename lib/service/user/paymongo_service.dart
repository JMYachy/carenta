import 'dart:convert';
import 'package:carenta/service/config/service_base_url.dart';
import 'package:http/http.dart' as http;

class PayMongoService {
  final String backendUrl = ServiceBaseUrl.endpoint('create_payment.php');

  Future<Map<String, dynamic>> createPayment({
    required double amount,
    String currency = "PHP",
    String method = "gcash", // gcash, card, grab_pay, paymaya
  }) async {
    final res = await http.post(
      Uri.parse(backendUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "amount": amount,
        "currency": currency,
        "method": method,
      }),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Payment failed: ${res.body}");
    }
  }
}
