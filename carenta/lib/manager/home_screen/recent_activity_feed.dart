// lib/admin/home_screen/recent_activity_feed.dart
import 'package:flutter/material.dart';
import 'package:carenta/service/admin/admin_booking_service.dart';

/// ✅ Single shared service instance (uses ServiceBaseUrl internally)
final AdminBookingService _bookingSvc = AdminBookingService();

class ActivityFeed extends StatelessWidget {
  const ActivityFeed({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _bookingSvc.fetchRecentActivity(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "⚠️ Failed to load activity feed:\n${snapshot.error}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          );
        }

        final activities = snapshot.data ?? [];
        if (activities.isEmpty) {
          return const Center(
            child: Text(
              "No recent activity.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          shrinkWrap: true,
          itemCount: activities.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final a = activities[index];

            final activity = (a["activity"] ?? "Unknown activity").toString();
            final timestamp = (a["timestamp"] ?? "").toString();

            return ListTile(
              leading: const Icon(Icons.history, color: Colors.orange),
              title: Text(
                activity,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                timestamp,
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
            );
          },
        );
      },
    );
  }
}
