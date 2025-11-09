import 'package:carenta/service/config/service_base_url.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserFeedbackService {
  final String _endpoint = ServiceBaseUrl.endpoint("feedback_service.php");

  Future<Map<String, dynamic>> saveFeedback({
    required int userId,
    required int carId,
    required int rating,
    required String title,
    required String comment,
    int? feedbackId,
  }) async {
    try {
      final res = await http.post(
        Uri.parse(_endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userid': userId,
          'carid': carId,
          'rating': rating,
          'title': title,
          'comment': comment,
          if (feedbackId != null) 'feedbackid': feedbackId,
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
