import 'package:flutter/material.dart';

class BookingHeaderCard extends StatelessWidget {
  final String title;
  final String imageUrl;

  const BookingHeaderCard({
    super.key,
    required this.title,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    String resolved = imageUrl.trim();
    if (resolved.isNotEmpty && !resolved.startsWith('http')) {
      // your files live under public_html /uploads /images
      resolved = 'https://carentaph.com/$resolved';
    }

    final theme = Theme.of(context);

    final img = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: resolved.isNotEmpty
            ? Image.network(
                resolved,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                  child: const Center(
                    child: Icon(Icons.directions_car_filled_rounded, size: 42),
                  ),
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Icon(Icons.directions_car_filled_rounded, size: 42),
                ),
              ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        img,
        const SizedBox(height: 10),
        Text(
          title.isEmpty ? 'Car' : title,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
