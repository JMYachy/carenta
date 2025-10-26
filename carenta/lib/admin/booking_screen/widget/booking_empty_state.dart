import 'package:flutter/material.dart';

class BookingEmptyState extends StatelessWidget {
  const BookingEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Icon(Icons.inbox_rounded, size: 56, color: scheme.primary),
        const SizedBox(height: 12),
        Text(
          'No bookings in this view',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}
  