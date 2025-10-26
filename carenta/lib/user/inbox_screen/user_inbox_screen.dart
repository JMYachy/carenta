import 'package:carenta/user/inbox_screen/tabs/inbox_notification_tab.dart';
import 'package:flutter/material.dart';
import 'tabs/inbox_messages_tab.dart';

class UserInboxScreen extends StatefulWidget {
  const UserInboxScreen({super.key});

  @override
  State<UserInboxScreen> createState() => _UserInboxScreenState();
}

class _UserInboxScreenState extends State<UserInboxScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFFFF5722),
            labelColor: const Color(0xFF0077B6),
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: "Messages"),
              Tab(text: "Notifications"),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              InboxMessagesTab(),
              InboxNotificationsTab(),
            ],
          ),
        ),
      ],
    );
  }
}
