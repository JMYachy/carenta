import 'dart:convert';
import 'package:carenta/service/config/service_base_url.dart';
import 'package:http/http.dart' as http;

class UserCancellationRequestService {
  final String _endpoint = ServiceBaseUrl.endpoint("cancellation_request_service.php");

  Future<Map<String, dynamic>> submitRequest({
    required int rentalId,
    required int userId,
    required String reason,
  }) async {
    try {
      final res = await http.post(
        Uri.parse(_endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'rental_id': rentalId,
          'user_id': userId,
          'reason': reason,
        }),
      );

      if (res.statusCode >= 400) {
        return {'success': false, 'message': 'Server error: ${res.statusCode}'};
      }

      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection failed: $e'};
    }
  }
}
