import 'package:flutter/material.dart';
import 'package:carenta/service/config/service_base_url.dart';

class BookingHeaderImage extends StatelessWidget {
  final String? imageUrl;
  final String carName;

  const BookingHeaderImage({
    super.key,
    required this.imageUrl,
    required this.carName,
  });

  @override
  Widget build(BuildContext context) {
    // 🧠 Process image URL - handle both absolute and relative paths
    final String displayUrl = _processImageUrl(imageUrl);

    return Stack(
      children: [
        // 🖼️ Car image (same logic as booking card)
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            displayUrl,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                height: 200,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey.shade200,
                ),
                child: const CircularProgressIndicator(
                  color: Colors.blueAccent,
                  strokeWidth: 2,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              // 🐛 Debug: print error
              debugPrint('❌ Image load error: $error');
              debugPrint('📍 URL attempted: $displayUrl');

              return Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey[200],
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.directions_car_filled_rounded,
                  size: 64,
                  color: Colors.grey,
                ),
              );
            },
          ),
        ),

        // 🏷️ Car name overlay
        Positioned(
          bottom: 12,
          left: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              carName.isNotEmpty ? carName : 'Unknown Vehicle',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  String _processImageUrl(String? url) {
  String? finalUrl = url?.trim();

  // If empty → fallback placeholder under /uploads/
  if (finalUrl == null || finalUrl.isEmpty) {
    return ServiceBaseUrl.file('uploads/placeholder_car.jpg');
  }

  // If already absolute URL → return as-is
  if (finalUrl.startsWith('http://') || finalUrl.startsWith('https://')) {
    return finalUrl.replaceAll('//', '/').replaceFirst(':/', '://');
  }

  // ✅ Relative path → build using correct base (NOT /api/)
  return ServiceBaseUrl.file(finalUrl);
}


}
