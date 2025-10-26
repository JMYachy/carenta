import 'package:flutter/material.dart';

class BookingCarHeaderSection extends StatelessWidget {
  final Map<String, dynamic> booking;
  const BookingCarHeaderSection({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final image = booking['image_url'] ?? booking['media_url'] ?? '';
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            image.isNotEmpty
                ? image
                : 'https://via.placeholder.com/120x80?text=No+Image',
            width: 120,
            height: 80,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '${booking['manufacturer'] ?? ''} ${booking['model'] ?? ''}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
      ],
    );
  }
}
