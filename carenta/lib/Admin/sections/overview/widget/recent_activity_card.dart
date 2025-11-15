import 'package:flutter/material.dart';

class RecentActivityCard extends StatelessWidget {
  final Map<String, dynamic> activity;
  const RecentActivityCard({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    switch (activity['status']) {
      case 'Completed':
        badgeColor = Colors.green;
        break;
      case 'Pending':
        badgeColor = Colors.orange;
        break;
      case 'Failed':
        badgeColor = Colors.redAccent;
        break;
      default:
        badgeColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: badgeColor.withOpacity(0.1),
          child: Icon(activity['icon'], color: badgeColor),
        ),
        title: Text(
          activity['title'],
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          activity['subtitle'],
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            activity['status'],
            style: TextStyle(color: badgeColor, fontSize: 12),
          ),
        ),
      ),
    );
  }
}
