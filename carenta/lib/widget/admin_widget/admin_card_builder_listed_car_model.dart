import 'package:flutter/material.dart';
import 'package:carenta/widget/admin_widget/car_model.dart';

class AdminBuildercardListedcarmodel extends StatelessWidget {
  final CarModel car;
  const AdminBuildercardListedcarmodel({super.key, required this.car});

  String get _currencySymbol {
    switch (car.currency.toUpperCase()) {
      case 'PHP':
        return '₱';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      default:
        return '';
    }
  }

  Color get statusColor {
    switch (car.status.toLowerCase()) {
      case 'available':
        return Colors.greenAccent;
      case 'rented':
        return Colors.redAccent;
      default:
        return Colors.orangeAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1C3A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🏷️ Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${car.manufacturer} ${car.model}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  car.status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Text(
            '${car.year} • ${car.type}',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),

          const SizedBox(height: 10),

          // 🖼️ Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                car.imageUrls.isNotEmpty
                    ? (car.imageUrls.first.startsWith('http')
                        ? car.imageUrls.first
                        : 'https://carentaph.com/${car.imageUrls.first}')
                    : 'https://via.placeholder.com/600x400?text=No+Image',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) {
                  return Container(
                    color: const Color(0xFF0F284E),
                    alignment: Alignment.center,
                    child: const Icon(Icons.directions_car, color: Colors.white24, size: 50),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ⚙️ Info Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Info(icon: Icons.settings, label: car.transmission),
              _Info(icon: Icons.local_gas_station, label: car.fuelType),
              _Info(icon: Icons.people, label: '${car.seatingCap} Seats'),
            ],
          ),

          const SizedBox(height: 8),

          // 💰 Prices
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Price(label: 'Daily', value: '${_currencySymbol}${car.dailyRate ?? 0}'),
              _Price(label: 'Weekly', value: '${_currencySymbol}${car.weeklyRate ?? 0}'),
              _Price(label: 'Monthly', value: '${_currencySymbol}${car.monthlyRate ?? 0}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Info({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.greenAccent, size: 16),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
      ],
    );
  }
}

class _Price extends StatelessWidget {
  final String label;
  final String value;
  const _Price({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(
          value,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ],
    );
  }
}
