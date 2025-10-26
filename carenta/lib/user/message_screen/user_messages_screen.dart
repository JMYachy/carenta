import 'package:carenta/service/Shared/messages_service.dart';
import 'package:carenta/user/message_screen/widget/message_app_bar.dart';
import 'package:carenta/user/message_screen/widget/message_input_bar.dart';
import 'package:carenta/user/message_screen/widget/message_list_item.dart';
import 'package:flutter/material.dart';

class UserMessagesScreen extends StatefulWidget {
  const UserMessagesScreen({super.key});

  @override
  State<UserMessagesScreen> createState() => _UserMessagesScreenState();
}

class _UserMessagesScreenState extends State<UserMessagesScreen> {
  final _messageService = MessageService();
  final TextEditingController _controller = TextEditingController();

  bool _isLoading = true;
  List<Map<String, dynamic>> _messages = [];

  // ✅ Change this to the logged-in user’s ID (Francis = 11)
  final int _currentUserId = 11;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final data = await _messageService.fetchMessages(
        renterId: _currentUserId,
      );
      debugPrint('Loaded messages: ${data.length}');
      setState(() => _messages = data);
    } catch (e) {
      debugPrint('Error loading messages: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // ✅ Send with renterId
    final ok = await _messageService.sendMessage(
      text,
      renterId: _currentUserId,
    );
    if (ok) {
      _controller.clear();
      // ✅ Instantly add to local list for smoother UX
      setState(() {
        _messages.insert(0, {
          'message_text': text,
          'sender_role': 'renter',
          'sent_at': DateTime.now().toString(),
        });
      });
    } else {
      debugPrint('Message send failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MessageAppBar(),
      body: Column(
        children: [
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _messages.isEmpty
                    ? const Center(
                      child: Text(
                        'No messages yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _messages.length,
                      reverse: true,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        return MessageListItem(
                          message: msg['message_text'] ?? '',
                          isUser: msg['sender_role'] == 'renter',
                          time: msg['sent_at'] ?? '',
                        );
                      },
                    ),
          ),
          MessageInputBar(controller: _controller, onSend: _sendMessage),
        ],
      ),
    );
  }
}
