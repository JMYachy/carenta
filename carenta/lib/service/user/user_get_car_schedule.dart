import 'dart:convert';
import 'package:http/http.dart' as http;

class CarScheduleService {
  final String baseUrl = "http://10.0.2.2/carenta/api";

  Future<List<Map<String, dynamic>>> fetchSchedule(int carId) async {
    final url = Uri.parse("$baseUrl/user_get_car_schedule.php?carid=$carId");
    final res = await http.get(url);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data["ok"] == true) {
        return List<Map<String, dynamic>>.from(data["schedule"]);
      }
    }
    throw Exception("Failed to load car schedule");
  }
}
