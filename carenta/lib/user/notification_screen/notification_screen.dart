import 'package:carenta/user/notification_screen/widgets/notification_card.dart';
import 'package:flutter/material.dart';
import 'package:carenta/service/util_service/session_manager_service.dart';
import 'package:carenta/service/user/user_notification_service.dart';

class UserNotificationsScreen extends StatefulWidget {
  const UserNotificationsScreen({super.key});

  @override
  State<UserNotificationsScreen> createState() =>
      _UserNotificationsScreenState();
}

class _UserNotificationsScreenState extends State<UserNotificationsScreen> {
  final _svc = UserNotificationService();
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final session = await SessionManagerService.checkSession();
    if (session['success'] == true) {
      _userId = session['data']['userid'];
      await _fetchNotifications();
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchNotifications() async {
    if (_userId == null) return;
    try {
      final data = await _svc.list(userId: _userId!);
      setState(() {
        _notifications = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading notifications: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchNotifications,
              child: _notifications.isEmpty
                  ? const Center(child: Text('No notifications yet'))
                  : ListView.builder(
                      itemCount: _notifications.length,
                      itemBuilder: (context, i) {
                        return NotificationCard(notif: _notifications[i]);
                      },
                    ),
            ),
    );
  }
}
