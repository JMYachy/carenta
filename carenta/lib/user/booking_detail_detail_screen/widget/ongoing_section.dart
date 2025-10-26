// lib/user/booking_detail/widgets/ongoing_section.dart
import 'package:flutter/material.dart';

class OngoingSection extends StatelessWidget {
  final Map<String, dynamic> booking;
  const OngoingSection({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final pickup = booking['pickup_location'] ?? 'Unknown';
    final dropoff = booking['dropoff_location'] ?? 'Unknown';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Ongoing Rental",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text("Pickup: $pickup"),
            Text("Drop-off: $dropoff"),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Tracking coming soon!")),
                );
              },
              icon: const Icon(Icons.location_on),
              label: const Text("Track Vehicle"),
            ),
          ],
        ),
      ),
    );
  }
}
