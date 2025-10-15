import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:carenta/service/config/service_base_url.dart';

class CarScheduleService {
  final String baseUrl = ServiceBaseUrl.baseUrl; // centralized API base URL

  /// Fetches the schedule for a specific car.
  Future<List<Map<String, dynamic>>> fetchSchedule(int carId) async {
    final uri = Uri.parse("${baseUrl}user_get_car_schedule.php?carid=$carId");

    try {
      final res = await http.get(uri);

      if (res.statusCode != 200) {
        throw Exception("Server returned status ${res.statusCode}");
      }

      final body = res.body.trim();
      if (!(body.startsWith('{') || body.startsWith('['))) {
        throw Exception("Unexpected server response");
      }

      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['ok'] == true) {
        final List<dynamic> schedule = decoded['schedule'] ?? [];
        return List<Map<String, dynamic>>.from(schedule);
      } else {
        throw Exception(decoded['message'] ?? "Invalid data format");
      }
    } catch (e) {
      throw Exception("Failed to load car schedule: $e");
    }
  }
}
