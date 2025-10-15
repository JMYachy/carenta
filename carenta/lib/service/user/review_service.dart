import 'dart:convert';
import 'package:http/http.dart' as http;

class ReviewService {
  final String apiRoot;
  const ReviewService({this.apiRoot = 'http://10.0.2.2/carenta/api'});

  Future<Map<String, dynamic>> getReviews(int carId) async {
    final uri = Uri.parse('$apiRoot/user_get_reviews.php?carid=$carId');
    final res = await http.get(uri);

    if (res.statusCode != 200) {
      return {"success": false, "message": "HTTP ${res.statusCode}"};
    }

    final raw = res.body.trim();
    final data = jsonDecode(raw);

    if (data is Map && data['ok'] == true) {
      return {"status": "success", "data": data['data'] ?? []};
    } else {
      return {"success": false, "message": data['message'] ?? "No reviews"};
    }
  }

  Future<Map<String, dynamic>> addReview({
    required int userId,
    required int carId,
    required int rating,
    required String comment,
  }) async {
    final uri = Uri.parse('$apiRoot/user_add_review.php');
    final res = await http.post(
      uri,
      body: {
        'user_id': '$userId',
        'car_id': '$carId',
        'rating': '$rating',
        'comment': comment,
      },
    );

    if (res.statusCode != 200) {
      return {"success": false, "message": "HTTP ${res.statusCode}"};
    }

    final data = jsonDecode(res.body);
    if (data['ok'] == true) {
      return {"status": "success", "message": data['message']};
    }
    return {"success": false, "message": data['message'] ?? "Failed"};
  }
}
