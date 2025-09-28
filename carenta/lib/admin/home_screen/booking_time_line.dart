import 'package:flutter/material.dart';

class BookingTimeline extends StatelessWidget {
  const BookingTimeline({super.key});

  @override
  Widget build(BuildContext context) {
    final bookings = [
      {"time": "09:00 AM", "car": "Toyota Vios", "status": "Confirmed"},
      {"time": "12:30 PM", "car": "Honda Civic", "status": "Ongoing"},
      {"time": "03:00 PM", "car": "Mitsubishi Xpander", "status": "Completed"},
    ];

    return Column(
      children: bookings.map((b) {
        return ListTile(
          leading: const Icon(Icons.access_time, color: Colors.blue),
          title: Text(b["car"] as String),
          subtitle: Text(b["status"] as String),
          trailing: Text(b["time"] as String),
        );
      }).toList(),
    );
  }
}
