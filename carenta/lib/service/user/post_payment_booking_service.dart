import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:carenta/service/config/service_base_url.dart';

class PostPaymentBookingResult {
  final bool success;
  final String message;
  final int? rentalId;
  final int? paymentId;

  PostPaymentBookingResult({
    required this.success,
    required this.message,
    this.rentalId,
    this.paymentId,
  });

  factory PostPaymentBookingResult.fromJson(Map<String, dynamic> json) {
    return PostPaymentBookingResult(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      rentalId: json['rentalid'],
      paymentId: json['paymentid'],
    );
  }
}

class UserPostPaymentBookingService {
  final http.Client _client;
  UserPostPaymentBookingService({http.Client? client}) : _client = client ?? http.Client();

  Future<PostPaymentBookingResult> submit(Map<String, dynamic> payload) async {
    final url = ServiceBaseUrl.endpoint('post_payment_booking.php');
    final res = await _client.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (res.statusCode != 200) {
      return PostPaymentBookingResult(success: false, message: 'HTTP ${res.statusCode}');
    }

    final data = jsonDecode(res.body);
    return PostPaymentBookingResult.fromJson(data);
  }
}
