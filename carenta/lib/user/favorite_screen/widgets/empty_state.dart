import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border_rounded, size: 56, color: cs.primary),
          const SizedBox(height: 12),
          Text('No favorites yet',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          Text('Save cars to see them here', style: TextStyle(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}
