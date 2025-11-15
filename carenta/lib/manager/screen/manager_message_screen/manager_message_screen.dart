import 'package:flutter/material.dart';
import 'service/manager_message_service.dart';
import 'widget/chat_list_tile.dart';
import 'widget/chat_bubble.dart';
import 'widget/message_input_bar.dart';

class ManagerMessageScreen extends StatefulWidget {
  final int adminId;

  const ManagerMessageScreen({super.key, required this.adminId});

  @override
  State<ManagerMessageScreen> createState() => _ManagerMessageScreenState();
}

enum _View { inbox, chat }

class _ManagerMessageScreenState extends State<ManagerMessageScreen> {
  final _svc = ManagerMessageService();

  _View _view = _View.inbox;

  // Inbox state
  bool _loading = true;
  List<Map<String, dynamic>> _threads = [];

  // Chat state
  final TextEditingController _msgCtl = TextEditingController();
  final ScrollController _scrollCtl = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  int? _chatUserId;
  String _chatUsername = '';
  bool _chatLoading = false;

  @override
  void initState() {
    super.initState();
    _loadThreads();
  }

  @override
  void dispose() {
    _msgCtl.dispose();
    _scrollCtl.dispose();
    _svc.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Inbox
  // ---------------------------------------------------------------------------

  Future<void> _loadThreads() async {
    setState(() => _loading = true);

    try {
      final data = await _svc.fetchThreads();
      if (!mounted) return;
      setState(() {
        _threads = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading threads: $e')));
    }
  }

  void _openChat({required int userId, required String username}) async {
    setState(() {
      _view = _View.chat;
      _chatUserId = userId;
      _chatUsername = username;
      _chatLoading = true;
      _messages.clear();
    });

    try {
      final msgs = await _svc.fetchConversation('USER-$userId');
      if (!mounted) return;
      setState(() {
        _messages = msgs;
        _chatLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => _chatLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading chat: $e')));
    }
  }

  // ---------------------------------------------------------------------------
  // Chat
  // ---------------------------------------------------------------------------

  Future<void> _sendMessage() async {
    final text = _msgCtl.text.trim();
    final uid = _chatUserId;

    if (text.isEmpty || uid == null) return;

    // Optimistic UI
    setState(() {
      _messages.add({
        'sender_role': 'manager',
        'message_text': text,
        'sent_at': DateTime.now().toIso8601String(),
      });
      _msgCtl.clear();
    });
    _scrollToBottom();

    final sent = await _svc.sendMessage(
      adminId: widget.adminId,
      userId: uid,
      message: text,
    );

    if (!sent && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to send message')));
      return;
    }

    // Ensure we are in sync with server
    await Future.delayed(const Duration(milliseconds: 300));
    await _refreshChat();
  }

  Future<void> _refreshChat() async {
    final uid = _chatUserId;
    if (uid == null) return;

    try {
      final msgs = await _svc.fetchConversation('USER-$uid');
      if (!mounted) return;
      setState(() => _messages = msgs);
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Refresh failed: $e')));
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtl.hasClients) return;
      _scrollCtl.jumpTo(_scrollCtl.position.maxScrollExtent);
    });
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _view == _View.inbox ? _buildInbox() : _buildChat(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isChat = _view == _View.chat;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: const BoxDecoration(
        color: Color(0xFF0077B6),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment:
            isChat ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          if (isChat)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                setState(() => _view = _View.inbox);
                _loadThreads();
              },
            ),
          Text(
            isChat ? _chatUsername : 'Messages',
            style: const TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (isChat) const Spacer(),
          if (isChat)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _refreshChat,
            ),
        ],
      ),
    );
  }

  Widget _buildInbox() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_threads.isEmpty) {
      return const Center(
        child: Text('No messages yet.', style: TextStyle(color: Colors.grey)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadThreads,
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        separatorBuilder: (_, __) => const Divider(height: 0),
        itemCount: _threads.length,
        itemBuilder: (context, i) {
          final t = _threads[i];
          final username = (t['username'] ?? 'User ${t['userid']}').toString();
          final last = (t['last_message'] ?? '').toString();
          final unread = int.tryParse('${t['unread_count'] ?? 0}') ?? 0;
          final userId = int.tryParse('${t['userid']}') ?? 0;

          return ChatListTile(
            leadingLetter: username.substring(0, 1).toUpperCase(),
            title: username,
            subtitle: last,
            unread: unread,
            onTap: () => _openChat(userId: userId, username: username),
          );
        },
      ),
    );
  }

  Widget _buildChat() {
    if (_chatLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollCtl,
            padding: const EdgeInsets.all(12),
            itemCount: _messages.length,
            itemBuilder: (context, i) {
              final m = _messages[i];
              final isMe = (m['sender_role']?.toString() ?? '') == 'manager';
              final text = (m['message_text'] ?? '').toString();
              return ChatBubble(isMe: isMe, text: text);
            },
          ),
        ),
        MessageInputBar(controller: _msgCtl, onSend: _sendMessage),
      ],
    );
  }
}
