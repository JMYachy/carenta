import 'package:carenta/service/config/service_base_url.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserBookingActionService {
  final String _endpoint = ServiceBaseUrl.endpoint("user_rental_action.php");

  Future<Map<String, dynamic>> updateStatus(
    int rentalId,
    String action, {
    String? reason,
  }) async {
    try {
      final res = await http.post(
        Uri.parse(_endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'rental_id': rentalId,
          'action': action,
          if (reason != null) 'reason': reason,
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
