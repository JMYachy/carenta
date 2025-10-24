import 'dart:convert';
import 'dart:io';
import 'package:carenta/service/config/service_base_url.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ReviewService {
  final String base = ServiceBaseUrl.endpoint(''); // Uses your endpoint helper

  /// 🟢 Fetch all reviews for a specific car
  Future<Map<String, dynamic>> getReviews(int carId) async {
    try {
      final uri = Uri.parse(
        ServiceBaseUrl.endpoint('user_get_reviews.php?carid=$carId'),
      );

      final res = await http.get(uri);
      if (res.statusCode != 200) {
        return {'status': 'fail', 'message': 'HTTP ${res.statusCode}'};
      }

      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        return {'status': 'success', 'data': data['data'] ?? []};
      } else {
        return {
          'status': 'fail',
          'message': data['message'] ?? 'No reviews found',
        };
      }
    } catch (e) {
      return {'status': 'fail', 'message': 'Error: $e'};
    }
  }

  /// 🟠 Add new review (supports optional image or video)
  Future<Map<String, dynamic>> addReview({
    required int userId,
    required int carId,
    required int rating,
    required String comment,
    File? mediaFile,
  }) async {
    try {
      final uri = Uri.parse(ServiceBaseUrl.endpoint('user_add_review.php'));
      var request = http.MultipartRequest('POST', uri);

      request.fields['user_id'] = '$userId';
      request.fields['car_id'] = '$carId';
      request.fields['rating'] = '$rating';
      request.fields['comment'] = comment;

      // 🔗 Optional image or video file
      if (mediaFile != null) {
        final mime =
            mediaFile.path.endsWith('.mp4') ? 'video/mp4' : 'image/jpeg';

        request.files.add(
          await http.MultipartFile.fromPath(
            'media',
            mediaFile.path,
            contentType: MediaType.parse(mime),
          ),
        );
      }

      final response = await request.send();
      final resBody = await response.stream.bytesToString();
      final data = jsonDecode(resBody);

      if (data['ok'] == true) {
        return {'status': 'success', 'message': data['message']};
      } else {
        return {
          'status': 'fail',
          'message': data['message'] ?? 'Upload failed',
        };
      }
    } catch (e) {
      return {'status': 'fail', 'message': 'Error: $e'};
    }
  }

  /// 🔒 Check if a user can post a review (after completed rental)
  Future<bool> canUserReview(int userId, int carId) async {
    try {
      final uri = Uri.parse(
        ServiceBaseUrl.endpoint(
          'user_can_review.php?userid=$userId&carid=$carId',
        ),
      );

      final res = await http.get(uri);
      if (res.statusCode != 200) return false;

      final data = jsonDecode(res.body);
      return data['ok'] == true && data['canReview'] == true;
    } catch (_) {
      return false;
    }
  }
}
