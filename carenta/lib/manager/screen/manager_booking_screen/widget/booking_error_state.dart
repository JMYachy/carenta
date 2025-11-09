// lib/manager/manager_booking_screen/widget/booking_error_state.dart
import 'package:flutter/material.dart';

class BookingErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const BookingErrorState({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 40),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, size: 64, color: Colors.redAccent),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
