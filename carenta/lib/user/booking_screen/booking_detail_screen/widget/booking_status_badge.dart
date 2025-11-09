import 'package:flutter/material.dart';

class BookingStatusBadge extends StatelessWidget {
  final int rentalId;
  final String status;
  final BuildContext context;

  const BookingStatusBadge({
    super.key,
    required this.rentalId,
    required this.status,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'confirmed':
        color = Colors.blue;
        break;
      case 'ongoing':
        color = Colors.teal;
        break;
      case 'completed':
        color = Colors.green;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Rental #$rentalId',
            style: Theme.of(context).textTheme.titleLarge),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: color.withOpacity(0.1),
            border: Border.all(color: color, width: 1),
          ),
          child: Row(
            children: [
              Icon(Icons.circle, color: color, size: 10),
              const SizedBox(width: 6),
              Text(status.toUpperCase(),
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}
