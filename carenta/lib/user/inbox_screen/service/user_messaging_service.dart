import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:carenta/service/config/service_base_url.dart';

class UserMessage {
  final int id;
  final String senderRole;
  final String receiverRole;
  final String message;
  final DateTime sentAt;
  final bool isUser;

  UserMessage({
    required this.id,
    required this.senderRole,
    required this.receiverRole,
    required this.message,
    required this.sentAt,
    required this.isUser,
  });

  factory UserMessage.fromJson(Map<String, dynamic> json) {
    final role = json['sender_role'] ?? 'renter';
    return UserMessage(
      id: int.tryParse(json['message_id'].toString()) ?? 0,
      senderRole: role,
      receiverRole: json['receiver_role'] ?? '',
      message: json['message_text'] ?? '',
      sentAt: DateTime.tryParse(json['sent_at'].toString()) ?? DateTime.now(),
      isUser: role == 'renter',
    );
  }
}

class UserMessageService {
  final http.Client _client;
  UserMessageService({http.Client? client}) : _client = client ?? http.Client();

  // ✅ Fetch conversation for the user
  Future<List<UserMessage>> fetchConversation(int userId) async {
    final threadId = 'USER-$userId';
    final url = ServiceBaseUrl.endpoint('fetch_conversation.php?thread_id=$threadId');

    final res = await _client.get(Uri.parse(url));
    if (res.statusCode != 200) throw Exception('Failed to load messages');

    final data = jsonDecode(res.body);
    if (data['success'] != true) throw Exception(data['message']);

    final list = (data['messages'] as List).map((e) => UserMessage.fromJson(e)).toList();
    return list;
  }

  // ✅ Send a new message
  Future<bool> sendMessage(int userId, String message) async {
    final url = ServiceBaseUrl.endpoint('user_send_message.php');
    final body = jsonEncode({'user_id': userId, 'message': message});

    final res = await _client.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (res.statusCode != 200) return false;
    final data = jsonDecode(res.body);
    return data['success'] == true;
  }

  void close() => _client.close();
}
