// lib/feature/manager/dashboard/service/manager_dashboard_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:carenta/service/config/service_base_url.dart';
import '../model/manager_dashboard_model.dart';

class ManagerDashboardService {
  Future<Map<String, dynamic>> fetchDashboardData() async {
    final url = Uri.parse(ServiceBaseUrl.endpoint('dashboard_summary.php'));
    final res = await http.get(url);

    if (res.statusCode != 200) {
      throw Exception('Server returned ${res.statusCode}');
    }

    final json = jsonDecode(res.body);
    if (json['ok'] != true) throw Exception('Invalid server response');

    final overview =
        DashboardOverview.fromJson(json['overview'] ?? {});
    final charts = (json['charts']?['top_models'] as List?)
            ?.map((e) => TopModelData.fromJson(e))
            .toList() ??
        [];
    final messages = (json['messages'] as List?)
            ?.map((e) => DashboardMessage.fromJson(e))
            .toList() ??
        [];
    final feedback = (json['feedback'] as List?)
            ?.map((e) => DashboardFeedback.fromJson(e))
            .toList() ??
        [];

    return {
      'overview': overview,
      'charts': charts,
      'messages': messages,
      'feedback': feedback,
    };
  }
}
