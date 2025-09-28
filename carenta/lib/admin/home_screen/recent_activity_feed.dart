import 'package:flutter/material.dart';

class ActivityFeed extends StatelessWidget {
  const ActivityFeed({super.key});

  @override
  Widget build(BuildContext context) {
    final activities = [
      "User John booked a Toyota Vios",
      "Car Honda Civic marked as returned",
      "Admin updated pricing for Mitsubishi Xpander",
    ];

    return Column(
      children: activities.map((a) {
        return ListTile(
          leading: const Icon(Icons.notifications, color: Colors.deepPurple),
          title: Text(a),
        );
      }).toList(),
    );
  }
}
