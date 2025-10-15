import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:carenta/service/config/service_base_url.dart';

class UserPaymentService {
  /// Creates (simulates) a payment transaction for a rental.
  Future<Map<String, dynamic>> createPayment({
    required int userId,
    required int rentalId,
    required double amount,
    String method = 'Cash',
    String referenceNo = '',
    String status = 'Paid',
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      // ✅ Use production base URL (centralized)
      final uri = Uri.parse('${ServiceBaseUrl.baseUrl}create_payment.php');

      final body = {
        'user_id': '$userId',
        'rental_id': '$rentalId',
        'amount': amount.toStringAsFixed(2),
        'payment_method': method,
        'reference_no': referenceNo,
        'status': status,
      };

      // ✅ Log outgoing request for debugging
      print('📤 [UserPaymentService] Sending POST → $uri');
      print('🔸 Body: $body');

      // ✅ Execute POST request
      final response = await http.post(uri, body: body).timeout(timeout);

      print(
        '📥 [UserPaymentService] Response (${response.statusCode}): ${response.body}',
      );

      // ✅ Handle non-200 responses
      if (response.statusCode != 200) {
        return {
          "ok": false,
          "message": "HTTP ${response.statusCode}",
          "body": response.body,
        };
      }

      // ✅ Parse response safely
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        if (decoded['ok'] == true) {
          return {
            "ok": true,
            "message": decoded['message'] ?? "Payment success",
            "data": decoded['data'] ?? {},
          };
        } else {
          return {
            "ok": false,
            "message":
                decoded['message'] ?? decoded['error'] ?? "Payment failed",
            "body": decoded,
          };
        }
      }

      return {
        "ok": false,
        "message": "Unexpected response format",
        "body": response.body,
      };
    } on http.ClientException catch (e) {
      print('❌ [UserPaymentService] ClientException: $e');
      return {"ok": false, "message": "Network error: ${e.message}"};
    } on FormatException catch (e) {
      print('❌ [UserPaymentService] JSON Decode Error: $e');
      return {"ok": false, "message": "Invalid response format"};
    } on Exception catch (e) {
      print('❌ [UserPaymentService] Exception: $e');
      return {"ok": false, "message": "Exception: $e"};
    }
  }
}
