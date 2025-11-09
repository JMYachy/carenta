import 'dart:async';
import 'package:carenta/service/user/user_messaging_service.dart';
import 'package:carenta/service/util_service/session_manager_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserMessagesScreen extends StatefulWidget {
  const UserMessagesScreen({super.key});

  @override
  State<UserMessagesScreen> createState() => _UserMessagesScreenState();
}

class _UserMessagesScreenState extends State<UserMessagesScreen> {
  final _svc = UserMessageService();
  final _msgC = TextEditingController();
  final _scrollC = ScrollController();

  List<UserMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  int? _userId;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final session = await SessionManagerService.checkSession();
    if (session['success'] == true) {
      _userId = session['data']['userid'];
      await _loadMessages();
      _startPolling();
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) => _loadMessages());
  }

  Future<void> _loadMessages() async {
    if (_userId == null) return;
    try {
      final msgs = await _svc.fetchConversation(_userId!);
      if (!mounted) return;
      setState(() {
        // reverse messages so latest appear at bottom
        _messages = msgs.reversed.toList();
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading messages: $e')),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollC.hasClients) {
        _scrollC.animateTo(
          0.0, // top of reversed list == bottom of chat
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_userId == null || _sending) return;
    final text = _msgC.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    final ok = await _svc.sendMessage(_userId!, text);
    setState(() => _sending = false);

    if (ok) {
      _msgC.clear();
      await _loadMessages();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message')),
      );
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _scrollC.dispose();
    _msgC.dispose();
    _svc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(child: Text("No messages yet"))
                    : ListView.builder(
                        reverse: true, // 👈 newest at bottom
                        controller: _scrollC,
                        padding: const EdgeInsets.all(12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final time = DateFormat('MMM d, h:mm a').format(msg.sentAt);
                          final isUser = msg.isUser;

                          return Align(
                            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(12),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.7,
                              ),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? cs.primary.withOpacity(0.9)
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: isUser
                                      ? const Radius.circular(16)
                                      : const Radius.circular(0),
                                  bottomRight: isUser
                                      ? const Radius.circular(0)
                                      : const Radius.circular(16),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msg.message,
                                    style: TextStyle(
                                      color: isUser ? Colors.white : Colors.black87,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    time,
                                    style: TextStyle(
                                      color:
                                          isUser ? Colors.white70 : Colors.black54,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Input field
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgC,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: "Type your message...",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _sending
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          onPressed: _sendMessage,
                          icon: const Icon(Icons.send_rounded,
                              color: Colors.deepOrange),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
