import 'package:flutter/material.dart';

class BookingCancelledNotice extends StatelessWidget {
  final String? reason;
  const BookingCancelledNotice({super.key, this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.cancel, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              reason?.isNotEmpty == true
                  ? "Cancelled: $reason"
                  : "Booking was cancelled.",
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
