import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notif;

  const NotificationCard({super.key, required this.notif});

  @override
  Widget build(BuildContext context) {
    final type = (notif['type'] ?? '').toString();
    final bool isRead = notif['is_read'].toString() == '1';
    final createdAt = notif['created_at'] ?? '';

    final icon = {
      'booking': Icons.event_available,
      'payment': Icons.payment,
      'message': Icons.message,
      'verification': Icons.verified_user,
      'system': Icons.info_outline,
    }[type] ?? Icons.notifications;

    final formattedDate = createdAt.isNotEmpty
        ? DateFormat('MMM d, yyyy • hh:mm a').format(DateTime.parse(createdAt))
        : '';

    return Card(
      elevation: 0.8,
      color: isRead ? Colors.white : Colors.blue.shade50,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueAccent),
        title: Text(
          notif['title'] ?? 'Notification',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notif['message'] ?? ''),
            const SizedBox(height: 4),
            Text(
              formattedDate,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
