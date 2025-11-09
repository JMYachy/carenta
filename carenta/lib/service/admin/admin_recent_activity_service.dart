/*import 'package:flutter/material.dart';
import 'package:carenta/manager/screen/manager_booking_screen/service/manager_booking_service.dart';

class ActivityFeed extends StatelessWidget {
  const ActivityFeed({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: AdminBookingService().fetchRecentActivity(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final activities = snapshot.data ?? [];
        if (activities.isEmpty) {
          return const Center(child: Text("No recent activity."));
        }

        return Column(
          children:
              activities.map((a) {
                return ListTile(
                  leading: const Icon(Icons.history, color: Colors.orange),
                  title: Text(a["activity"].toString()),
                  subtitle: Text(a["timestamp"].toString()),
                );
              }).toList(),
        );
      },
    );
  }
}
*/