import 'package:carenta/service/Shared/messages_service.dart';
import 'package:carenta/service/util_service/session_manager_service.dart';
import 'package:carenta/user/inbox_screen/message_screen/widget/message_input_bar.dart';
import 'package:carenta/user/inbox_screen/message_screen/widget/message_list_item.dart';
import 'package:flutter/material.dart';

class UserMessagesScreen extends StatefulWidget {
  final int?
  adminId; // optional if you want to know which manager the renter is chatting with

  const UserMessagesScreen({super.key, this.adminId});

  @override
  State<UserMessagesScreen> createState() => _UserMessagesScreenState();
}

class _UserMessagesScreenState extends State<UserMessagesScreen> {
  final _messageService = MessageService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isSessionError = false;
  int? _userId;
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _initializeSessionAndMessages();
  }

  /// ✅ 1. Check session and load user ID
  Future<void> _initializeSessionAndMessages() async {
    setState(() {
      _isLoading = true;
      _isSessionError = false;
    });

    try {
      final session = await SessionManagerService.checkSession();
      if (session['success'] == true && session['data'] != null) {
        _userId = int.tryParse(session['data']['userid'].toString());
        await _loadMessages();
      } else {
        setState(() => _isSessionError = true);
      }
    } catch (e) {
      debugPrint('Session check failed: $e');
      setState(() => _isSessionError = true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// ✅ 2. Fetch messages for the current renter
  Future<void> _loadMessages() async {
    if (_userId == null) return;

    setState(() => _isLoading = true);
    try {
      final data = await _messageService.fetchMessages(renterId: _userId!);
      setState(() => _messages = data);
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error loading messages: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// ✅ 3. Send a message
  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _userId == null) return;

    final newMsg = await _messageService.sendMessage(text, renterId: _userId!);

    if (newMsg != null) {
      _controller.clear();
      setState(() {
        _messages.insert(0, {
          'message_text': text,
          'sender_role': 'renter',
          'sent_at': DateTime.now().toString(),
        });
      });
      _scrollToBottom();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to send message.')));
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.minScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isSessionError) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text(
                'Session expired or not logged in.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  SessionManagerService.clearSessionCookie();
                  if (mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (_) => false,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0077B6),
                ),
                child: const Text('Login Again'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 2,
        backgroundColor: const Color(0xFF0077B6),
        title: const Text(
          'Messages',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
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
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.all(12),
                      itemCount: _messages.length,
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
