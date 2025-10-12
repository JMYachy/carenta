// lib/admin/home_screen/booking_time_line.dart
import 'package:flutter/material.dart';
import 'package:carenta/service/admin/admin_booking_service.dart';

// ✅ file-level singleton (not static methods)
final AdminBookingService _bookingSvc = AdminBookingService();
class BookingTimeline extends StatelessWidget {
  const BookingTimeline({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _bookingSvc.fetchTimeline(), // ✅ instance call
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text("Error: ${snap.error}"));
        }
        final bookings = snap.data ?? [];
        if (bookings.isEmpty) {
          return const Center(child: Text("No bookings today."));
        }

        return Column(
          children:
              bookings.map((b) {
                return ListTile(
                  leading: const Icon(Icons.access_time, color: Colors.blue),
                  title: Text("${b["manufacturer"]} ${b["car_model"]}"),
                  subtitle: Text(b["status"].toString()),
                  trailing: Text(b["time"].toString()),
                );
              }).toList(),
        );
      },
    );
  }
}
