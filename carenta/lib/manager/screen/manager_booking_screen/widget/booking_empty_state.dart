// lib/manager/manager_booking_screen/widget/booking_empty_state.dart
import 'package:flutter/material.dart';

class BookingEmptyState extends StatelessWidget {
  const BookingEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 40),
      child: Column(
        children: const [
          Icon(Icons.inbox_rounded, size: 64, color: Colors.grey),
          SizedBox(height: 8),
          Text('No bookings found', style: TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}
