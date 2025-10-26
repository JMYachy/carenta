import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:carenta/service/config/service_base_url.dart';

/// 🔹 Shared service for both renter and admin message interactions
class MessageService {
  // Endpoint path using your production-ready base config
  final String _endpoint = ServiceBaseUrl.endpoint('messages.php');

  /// ✅ Fetch all messages for the current session user (renter/admin)
  Future<List<Map<String, dynamic>>> fetchMessages({int? renterId}) async {
    final url = Uri.parse(
      renterId != null
          ? '$_endpoint?action=fetch&renter_id=$renterId'
          : '$_endpoint?action=fetch',
    );

    try {
      final response = await http.get(url);

      print('[FETCH] Status: ${response.statusCode}');
      print('[FETCH] Response: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);

        if (body['success'] == true && body['messages'] != null) {
          return List<Map<String, dynamic>>.from(body['messages']);
        } else {
          print('[FETCH] No messages found or API returned success=false');
        }
      } else {
        print(
          '[FETCH] Server returned unexpected status ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching messages: $e');
    }

    return [];
  }

  /// ✅ Send a new message
  /// Works for both session users (web) and mobile (requires renterId)
  Future<bool> sendMessage(String messageText, {int? renterId}) async {
    final url = Uri.parse('$_endpoint?action=send');

    // For mobile, renterId is required since PHP sessions don't persist
    final body = {
      'message_text': messageText,
      if (renterId != null) 'renter_id': renterId,
    };

    try {
      // Debug what’s being sent
      print('[SEND] Sending body: ${jsonEncode(body)}');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print('[SEND] Status: ${response.statusCode}');
      print('[SEND] Response: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          print('[SEND] Message sent successfully');
          return true;
        } else {
          print('[SEND] Error from API: ${data['message']}');
        }
      } else {
        print('[SEND] Unexpected status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending message: $e');
    }

    return false;
  }

  /// ✅ Mark message as read
  Future<bool> markAsRead(int messageId) async {
    final url = Uri.parse('$_endpoint?action=read');

    try {
      final body = jsonEncode({'message_id': messageId});
      print('[READ] Sending body: $body');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      print('[READ] Status: ${response.statusCode}');
      print('[READ] Response: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          print('[READ] Message marked as read successfully');
          return true;
        } else {
          print('[READ] API error: ${data['message']}');
        }
      } else {
        print('[READ] Unexpected status ${response.statusCode}');
      }
    } catch (e) {
      print('Error marking message as read: $e');
    }

    return false;
  }
}
