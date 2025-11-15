// lib/manager/manager_car_screen/widget/car_stats_overview.dart
import 'package:flutter/material.dart';

class CarStatsOverview extends StatelessWidget {
  final int available;
  final int rented;
  final int maintenance;
  final int inactive;
  final ValueChanged<String> onFilterSelect;

  const CarStatsOverview({
    super.key,
    required this.available,
    required this.rented,
    required this.maintenance,
    required this.inactive,
    required this.onFilterSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _statCard('Available', available, Colors.green, 'available'),
          _statCard('Rented', rented, Colors.orange, 'rented'),
          _statCard('Maint.', maintenance, Colors.grey, 'maintenance'),
          _statCard('Inactive', inactive, Colors.redAccent, 'inactive'),
        ],
      ),
    );
  }

  Widget _statCard(String title, int value, Color color, String status) {
    return Expanded(
      child: InkWell(
        onTap: () => onFilterSelect(status),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Column(
            children: [
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
