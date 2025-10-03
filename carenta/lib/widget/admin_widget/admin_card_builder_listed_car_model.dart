import 'package:flutter/material.dart';

class AdminBuildercardListedcarmodel extends StatelessWidget {
  final String carName;
  final String brand;
  final String imageUrl;
  final int seats;
  final String transmission;
  final String pricePerDay;
  final String currency; // e.g., "PHP" or "USD"

  const AdminBuildercardListedcarmodel({
    super.key,
    required this.carName,
    required this.brand,
    required this.imageUrl,
    required this.seats,
    required this.transmission,
    required this.pricePerDay,
    this.currency = 'PHP',
  });

  String get _currencySymbol {
    switch (currency.toUpperCase()) {
      case 'PHP':
        return '₱';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      default:
        return ''; // fallback to no symbol
    }
  }

  @override
  Widget build(BuildContext context) {
    const gap10 = SizedBox(height: 10);
    const gap12 = SizedBox(height: 12);

    return Semantics(
      label:
          '$brand $carName, $seats seats, $transmission, '
          '${_currencySymbol.isEmpty ? '' : _currencySymbol}$pricePerDay per day',
      button: false,
      child: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0C1C3A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row (❌ heart removed for admin)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  carName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  brand,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),

            gap10,

            // Image with proper aspect ratio + error handling
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
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
                ),
              ),
            ),

            gap12,

            // Footer stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Stat(icon: Icons.person, label: '$seats'),
                _Stat(icon: Icons.settings, label: transmission),
                Text(
                  '${_currencySymbol.isEmpty ? '' : _currencySymbol}$pricePerDay/d',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Stat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.greenAccent, size: 18),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
