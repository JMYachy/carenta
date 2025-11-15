import 'dart:convert';
import 'package:carenta/Admin/sections/managers/widget/manager_model.dart';
import 'package:http/http.dart' as http;
import 'package:carenta/service/config/service_base_url.dart';

class ManagerService {
  /// 🧩 fetch all managers (search + filter)
  Future<({int total, List<ManagerModel> rows})> list({
    String q = '',
    String status = 'All',
    int limit = 50,
    int offset = 0,
    String orderBy = 'created_at',
    String dir = 'desc',
  }) async {
    final uri = Uri.parse(
      ServiceBaseUrl.endpoint('admin_manager_list.php'),
    ).replace(
      queryParameters: {
        if (q.isNotEmpty) 'q': q,
        if (status != 'All') 'status': status.toLowerCase(),
        'limit': '$limit',
        'offset': '$offset',
        'orderBy': orderBy,
        'dir': dir,
      },
    );

    final res = await http.get(uri);
    final j = jsonDecode(res.body);
    if (res.statusCode != 200 || j['ok'] != true) {
      throw Exception(j['message'] ?? 'Failed to fetch managers');
    }
    final rows =
        (j['rows'] as List).map((e) => ManagerModel.fromJson(e)).toList();
    return (total: j['total'] as int, rows: rows);
  }

  /// 🧩 create manager
  Future<ManagerModel> create({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
    String status = 'active',
  }) async {
    final uri = Uri.parse(ServiceBaseUrl.endpoint('admin_manager_create.php'));
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        'phone_number': phoneNumber,
        'status': status,
      }),
    );
    final j = jsonDecode(res.body);
    if (res.statusCode != 200 || j['ok'] != true) {
      throw Exception(j['message'] ?? 'Create failed');
    }
    return ManagerModel.fromJson(j['row']);
  }

  /// 🧩 update manager
  Future<ManagerModel> update({
    required int adminid,
    String? username,
    String? email,
    String? password,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? status,
  }) async {
    final uri = Uri.parse(ServiceBaseUrl.endpoint('admin_manager_update.php'));
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'adminid': adminid,
        if (username != null) 'username': username,
        if (email != null) 'email': email,
        if (password != null && password.isNotEmpty) 'password': password,
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (status != null) 'status': status,
      }),
    );
    final j = jsonDecode(res.body);
    if (res.statusCode != 200 || j['ok'] != true) {
      throw Exception(j['message'] ?? 'Update failed');
    }
    return ManagerModel.fromJson(j['row']);
  }

  /// 🧩 toggle active/inactive
  Future<void> toggleStatus({
    required int adminid,
    required bool active,
  }) async {
    final uri = Uri.parse(
      ServiceBaseUrl.endpoint('admin_manager_toggle_status.php'),
    );
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'adminid': adminid, 'active': active}),
    );
    final j = jsonDecode(res.body);
    if (res.statusCode != 200 || j['ok'] != true) {
      throw Exception(j['message'] ?? 'Toggle failed');
    }
  }
}
