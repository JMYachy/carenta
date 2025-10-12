import 'dart:convert';
import 'package:carenta/service/config/service_base_url.dart';
import 'package:http/http.dart' as http;

class CarScheduleService {

  Future<List<Map<String, dynamic>>> fetchSchedule(int carId) async {
    final url = Uri.parse("${ServiceBaseUrl.endpoint('user_get_car_schedule.php')}?carid=$carId");
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
