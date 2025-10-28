import 'package:flutter/material.dart';

class BookingStatusBanner extends StatelessWidget {
  final String status;
  const BookingStatusBanner({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = "Pending Approval";
        break;
      case 'confirmed':
        color = Colors.blue;
        label = "Confirmed & Scheduled";
        break;
      case 'ongoing':
        color = Colors.green;
        label = "Ongoing Rental";
        break;
      case 'completed':
        color = Colors.teal;
        label = "Completed Trip";
        break;
      case 'cancelled':
        color = Colors.redAccent;
        label = "Cancelled Booking";
        break;
      default:
        color = Colors.grey;
        label = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
