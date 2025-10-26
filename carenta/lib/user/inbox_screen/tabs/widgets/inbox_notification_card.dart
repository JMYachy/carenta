import 'package:flutter/material.dart';

class InboxNotificationCard extends StatelessWidget {
  final String type;
  final String title;
  final String subtitle;
  final String time;
  final VoidCallback onTap;

  const InboxNotificationCard({
    super.key,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.onTap,
  });

  IconData _getIcon() {
    switch (type) {
      case 'notification':
        return Icons.event_available;
      case 'advisory':
        return Icons.campaign;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(_getIcon(), color: const Color(0xFF0077B6), size: 30),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        onTap: onTap,
      ),
    );
  }
}
