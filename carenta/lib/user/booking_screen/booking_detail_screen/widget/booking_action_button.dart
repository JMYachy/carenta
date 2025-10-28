import 'package:flutter/material.dart';

class BookingActionButtons extends StatelessWidget {
  final bool canCancel;
  final bool canExtend;
  final bool canReview;
  final bool working;

  final VoidCallback onCancel;
  final VoidCallback onExtend;
  final VoidCallback onReview;
  final VoidCallback onRebook;

  const BookingActionButtons({
    super.key,
    required this.canCancel,
    required this.canExtend,
    required this.canReview,
    required this.working,
    required this.onCancel,
    required this.onExtend,
    required this.onReview,
    required this.onRebook,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        if (canCancel)
          FilledButton.icon(
            onPressed: working ? null : onCancel,
            icon: const Icon(Icons.cancel_schedule_send_rounded),
            label: const Text('Cancel Booking'),
          ),
        if (canExtend)
          OutlinedButton.icon(
            onPressed: working ? null : onExtend,
            icon: const Icon(Icons.chat_rounded),
            label: const Text('Request Extension'),
          ),
        if (canReview)
          OutlinedButton.icon(
            onPressed: working ? null : onReview,
            icon: const Icon(Icons.star_rate_rounded),
            label: const Text('Leave a Review'),
          ),
        TextButton.icon(
          onPressed: working ? null : onRebook,
          icon: const Icon(Icons.restart_alt_rounded),
          label: const Text('Rebook this Car'),
        ),
      ],
    );
  }
}
