import 'package:carenta/service/Shared/notification_service.dart';
import 'package:carenta/user/inbox_screen/tabs/widgets/inbox_notification_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InboxNotificationsTab extends StatefulWidget {
  const InboxNotificationsTab({super.key});

  @override
  State<InboxNotificationsTab> createState() => _InboxNotificationsTabState();
}

class _InboxNotificationsTabState extends State<InboxNotificationsTab> {
  final _svc = NotificationService();
  bool _loading = true;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _loading = true);
    final data = await _svc.fetchNotifications();
    setState(() {
      _notifications = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_notifications.isEmpty) return const Center(child: Text("No notifications yet"));

    return ListView.builder(
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final note = _notifications[index];
        final time = DateFormat('MMM d, h:mm a').format(DateTime.parse(note['created_at']));
        return InboxNotificationCard(
          type: note['type'] ?? 'notification',
          title: note['title'] ?? '',
          subtitle: note['content'] ?? '',
          time: time,
          onTap: () {
            if (note['type'] == 'advisory') {
              Navigator.pushNamed(context, '/advisory-details', arguments: note);
            } else {
              Navigator.pushNamed(context, '/notification-details', arguments: note);
            }
          },
        );
      },
    );
  }
}
