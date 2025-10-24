import 'package:carenta/widget/shared/car_image_carousel.dart';
import 'package:flutter/material.dart';

class CarHeaderSection extends StatelessWidget {
  final Map<String, dynamic> car;
  const CarHeaderSection({super.key, required this.car});

  @override
  Widget build(BuildContext context) {
    // 🧠 Extract any valid image data (list or single)
    final dynamic imageData =
        car['media'] ?? car['media_url'] ?? car['image_url'];

    final manufacturer = (car['manufacturer'] ?? '').toString();
    final model = (car['model'] ?? '').toString();
    final year = (car['year'] ?? '').toString();
    final plate = (car['license_plate'] ?? '').toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ Carousel that handles both List and String types internally
        CarImageCarousel(imageData: imageData),

        const SizedBox(height: 16),

        // 🏷️ Car title
        Text(
          '$manufacturer $model${year.isNotEmpty ? ' ($year)' : ''}',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),

        // 🚘 Optional license plate
        if (plate.isNotEmpty)
          Text('Plate: $plate', style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}
