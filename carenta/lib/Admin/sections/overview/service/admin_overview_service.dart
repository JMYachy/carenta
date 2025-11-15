import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:carenta/service/config/service_base_url.dart';
import 'package:flutter/material.dart';

class DashboardService {
  /// Fetch live dashboard data from backend
  Future<Map<String, dynamic>> fetchDashboard() async {
    final uri = Uri.parse(
      ServiceBaseUrl.endpoint('admin_dashboard_overview.php'),
    );
    final res = await http.get(uri);
    final j = jsonDecode(res.body);

    if (res.statusCode != 200 || j['ok'] != true) {
      throw Exception(j['message'] ?? 'Failed to load dashboard');
    }

    final stats = Map<String, dynamic>.from(j['stats'] ?? {});
    final activities =
        (j['activities'] as List? ?? []).map((e) {
          final a = Map<String, dynamic>.from(e);
          return {
            'icon': Icons.notifications,
            'title': a['title'] ?? '',
            'subtitle': a['date_text'] ?? '',
            'status': a['status'] ?? 'Completed',
          };
        }).toList();

    return {'stats': stats, 'activities': activities};
  }

  Future<Map<String, dynamic>> fetchRevenue({String period = 'monthly'}) async {
    final uri = Uri.parse(
      ServiceBaseUrl.endpoint('admin_revenue_overview.php'),
    ).replace(queryParameters: {'period': period});

    final res = await http.get(uri);
    final j = jsonDecode(res.body);

    if (res.statusCode != 200 || j['ok'] != true) {
      throw Exception(j['message'] ?? 'Failed to load revenue');
    }

    return {
      'total': j['total_revenue'],
      'period': j['period'],
      'data':
          (j['data'] as List)
              .map(
                (e) => {
                  'label': e['period_label'],
                  'value': double.tryParse(e['total'].toString()) ?? 0.0,
                },
              )
              .toList(),
    };
  }
}
