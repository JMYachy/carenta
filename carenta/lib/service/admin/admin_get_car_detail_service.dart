import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:carenta/service/config/service_base_url.dart';
import 'package:carenta/widget/admin_widget/car_model.dart';

class AdminGetCarDetailsService {
  static final String _endpoint = ServiceBaseUrl.endpoint("admin_get_car_details.php");

  static Future<CarModel?> fetchCarById(int carId) async {
    try {
      final uri = Uri.parse("$_endpoint?carid=$carId");
      final response = await http.get(uri, headers: {
        "Content-Type": "application/json",
      });

      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return CarModel.fromJson(data['data']);
      } else {
        return null;
      }
    } catch (e) {
      print("Error fetching car details: $e");
      return null;
    }
  }
}
