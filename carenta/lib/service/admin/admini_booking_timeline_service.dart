import 'package:flutter/material.dart';
import 'package:carenta/service/admin/admin_booking_service.dart';

class BookingTimeline extends StatelessWidget {
  const BookingTimeline({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: AdminBookingService().fetchTimeline(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final bookings = snapshot.data ?? [];
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
