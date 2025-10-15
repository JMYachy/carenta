import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:carenta/service/config/service_base_url.dart';

class OwnerService {
  Future<Map<String, dynamic>?> fetchOwner(int carId) async {
    final uri = Uri.parse(
      ServiceBaseUrl.endpoint("user_get_owner_info.php"),
    ).replace(queryParameters: {'carid': '$carId'});
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data['ok'] == true) return data['data'];
    }
    return null;
  }
}
