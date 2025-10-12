// lib/widget/safe_car_image.dart
import 'package:flutter/material.dart';

class SafeCarImage extends StatelessWidget {
  final String? imageUrl;
  final double borderRadius;
  final double aspectRatio;
  final double? height;

  const SafeCarImage({
    super.key,
    this.imageUrl,
    this.borderRadius = 16,
    this.aspectRatio = 16 / 9,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child:
            imageUrl != null && imageUrl!.isNotEmpty
                ? Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  height: height,
                  width: double.infinity,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  },
                  errorBuilder: (context, error, stack) {
                    return Container(
                      color: const Color(0xFF0F284E),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.directions_car_filled,
                        color: Colors.white24,
                        size: 48,
                      ),
                    );
                  },
                )
                : Container(
                  color: const Color(0xFF0F284E),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.directions_car,
                    size: 80,
                    color: Colors.white24,
                  ),
                ),
      ),
    );
  }
}
