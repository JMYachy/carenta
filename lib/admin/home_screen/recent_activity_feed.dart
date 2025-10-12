// lib/admin/home_screen/recent_activity_feed.dart
import 'package:flutter/material.dart';
import 'package:carenta/service/admin/admin_booking_service.dart';

// ✅ file-level singleton (not static methods)
final AdminBookingService _bookingSvc = AdminBookingService();
//const _bookingSvc = AdminBookingService();
class ActivityFeed extends StatelessWidget {
  const ActivityFeed({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _bookingSvc.fetchRecentActivity(), // ✅ instance call
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text("Error: ${snap.error}"));
        }
        final activities = snap.data ?? [];
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
