import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:carenta/service/config/service_base_url.dart';

class AdminInsightsService {
  final String _url = ServiceBaseUrl.endpoint('admin_insights.php');

  /// Fetch summary (supports optional filters)
  Future<Map<String, dynamic>> fetchInsights({
    String? start,
    String? end,
    String? location,
    String filter = 'monthly',
  }) async {
    final params = {
      'action': 'summary',
      'filter': filter,
      if (start != null) 'start': start,
      if (end != null) 'end': end,
      if (location != null && location.isNotEmpty) 'location': location,
    };
    final uri = Uri.parse(
      ServiceBaseUrl.endpoint('admin_insights.php'),
    ).replace(queryParameters: params);
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return body;
    }
    throw Exception('Failed to load insights');
  }

  /// Export report CSV
  Future<Uri> buildExportCsvUri({
    required String start,
    required String end,
    String granularity = 'month',
  }) async {
    return Uri.parse(_url).replace(
      queryParameters: {
        'action': 'export_csv',
        'start': start,
        'end': end,
        'granularity': granularity,
      },
    );
  }
}
