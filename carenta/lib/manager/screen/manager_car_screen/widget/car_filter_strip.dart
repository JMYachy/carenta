// lib/manager/manager_car_screen/widget/car_filter_strip.dart
import 'package:flutter/material.dart';

class CarFilterStrip extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const CarFilterStrip({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF0077B6);
    final filters = ['all', 'available', 'rented', 'maintenance', 'inactive'];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final label = filters[index];
          final isSelected = selected == label;

          return ChoiceChip(
            label: Text(label[0].toUpperCase() + label.substring(1)),
            selected: isSelected,
            onSelected: (_) => onSelect(label),
            selectedColor: accent.withOpacity(0.15),
            labelStyle: TextStyle(
              color: isSelected ? accent : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
            backgroundColor: Colors.white,
            side: const BorderSide(color: Colors.black12),
          );
        },
      ),
    );
  }
}
