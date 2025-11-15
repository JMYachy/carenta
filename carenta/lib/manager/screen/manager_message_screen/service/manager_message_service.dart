import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:carenta/service/config/service_base_url.dart';

class ManagerMessageService {
  final http.Client _client;

  ManagerMessageService({http.Client? client})
    : _client = client ?? http.Client();

  /// Fetch all threads (inbox)
  Future<List<Map<String, dynamic>>> fetchThreads() async {
    final uri = Uri.parse(ServiceBaseUrl.endpoint('manager_fetch_threads.php'));
    final res = await _client.get(uri);

    if (res.statusCode != 200) {
      throw Exception('Failed to load threads (HTTP ${res.statusCode})');
    }

    final data = jsonDecode(res.body);
    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'Failed to load threads');
    }

    return List<Map<String, dynamic>>.from(data['threads'] ?? []);
  }

  /// Fetch conversation for a given thread
  Future<List<Map<String, dynamic>>> fetchConversation(String threadId) async {
    final uri = Uri.parse(
      ServiceBaseUrl.endpoint('manager_fetch_conversation.php'),
    ).replace(queryParameters: {'thread_id': threadId});

    final res = await _client.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Failed to load conversation (HTTP ${res.statusCode})');
    }

    final data = jsonDecode(res.body);
    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'Failed to load conversation');
    }

    return List<Map<String, dynamic>>.from(data['messages'] ?? []);
  }

  /// Send a message from manager -> user
  Future<bool> sendMessage({
    required int adminId,
    required int userId,
    required String message,
  }) async {
    final uri = Uri.parse(ServiceBaseUrl.endpoint('manager_send_messages.php'));

    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'admin_id': adminId,
        'user_id': userId,
        'message': message,
      }),
    );

    if (res.statusCode != 200) return false;

    final data = jsonDecode(res.body);
    return data['success'] == true;
  }

  void dispose() => _client.close();
}
