import 'dart:convert';
import 'package:carenta/service/util_service/session_manager_service.dart';
import 'package:http/http.dart' as http;
import 'package:carenta/service/config/service_base_url.dart';

class MessageService {
  // Inbox (threads)
  final String _inboxUrl = ServiceBaseUrl.endpoint('fetch_inbox_messages.php');

  // Chat (full conversation)
  final String _fetchUrl = ServiceBaseUrl.endpoint('fetch_messages.php');
  final String _sendUrl  = ServiceBaseUrl.endpoint('send_messages.php');
  final String _readUrl  = ServiceBaseUrl.endpoint('read_messages.php');

  /// 📨 Fetch inbox threads (used in Inbox > Messages tab)
  Future<List<Map<String, dynamic>>> fetchInboxMessages() async {
    try {
      final session = await SessionManagerService.checkSession();
      final userId = session['data']?['userid'];
      if (userId == null) throw Exception('No active user session');

      final url = Uri.parse('$_inboxUrl?renter_id=$userId');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['messages'] != null) {
          return List<Map<String, dynamic>>.from(data['messages']);
        }
      }
    } catch (e) {
      print('Error fetching inbox threads: $e');
    }
    return [];
  }

  /// 💬 Fetch full conversation (used in UserMessagesScreen)
  Future<List<Map<String, dynamic>>> fetchMessages({required int renterId}) async {
    final url = Uri.parse('$_fetchUrl?renter_id=$renterId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['messages'] != null) {
          return List<Map<String, dynamic>>.from(data['messages']);
        }
      }
    } catch (e) {
      print('Error fetching conversation: $e');
    }
    return [];
  }

  /// ✉️ Send a chat message (used in UserMessagesScreen)
  Future<Map<String, dynamic>?> sendMessage(String messageText, {required int renterId}) async {
    final body = {'message_text': messageText, 'renter_id': renterId};
    try {
      final response = await http.post(
        Uri.parse(_sendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) return data['data'];
      }
    } catch (e) {
      print('Error sending message: $e');
    }
    return null;
  }

  /// ✅ Mark as read
  Future<bool> markAsRead(int messageId) async {
    try {
      final response = await http.post(
        Uri.parse(_readUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message_id': messageId}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
    } catch (e) {
      print('Error marking message as read: $e');
    }
    return false;
  }
}
