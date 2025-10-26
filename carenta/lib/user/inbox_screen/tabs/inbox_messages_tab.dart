import 'package:carenta/service/Shared/messages_service.dart';
import 'package:carenta/service/util_service/navigation_helper.dart';
import 'package:carenta/user/inbox_screen/tabs/widgets/inbox_message_card.dart';
import 'package:carenta/user/message_screen/user_messages_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InboxMessagesTab extends StatefulWidget {
  const InboxMessagesTab({super.key});

  @override
  State<InboxMessagesTab> createState() => _InboxMessagesTabState();
}

class _InboxMessagesTabState extends State<InboxMessagesTab> {
  final _svc = MessageService();
  bool _loading = true;
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _loading = true);
    final data = await _svc.fetchInboxMessages();
    setState(() {
      _messages = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_messages.isEmpty) return const Center(child: Text("No messages yet"));

    return ListView.builder(
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final time = DateFormat('MMM d, h:mm a').format(DateTime.parse(msg['sent_at']));
        return InboxMessageCard(
          title: msg['admin_name'] ?? 'Carenta Manager',
          subtitle: msg['message_text'] ?? '',
          time: time,
          onTap: () {
            // ✅ Clean, readable navigation
            Nav.to(context, UserMessagesScreen(
              key: UniqueKey(),
              adminId: msg['admin_id'],
            ));
          },
        );
      },
    );
  }
}
