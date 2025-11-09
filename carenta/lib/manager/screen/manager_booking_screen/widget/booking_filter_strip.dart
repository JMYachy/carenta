// lib/manager/manager_booking_screen/widget/booking_filter_strip.dart
import 'package:flutter/material.dart';

class FilterSpec {
  final String label;
  final String? status;
  final IconData icon;
  const FilterSpec(this.label, this.status, this.icon);
}

class BookingFilterStrip extends StatelessWidget {
  final List<FilterSpec> filters;
  final int selected;
  final ValueChanged<int> onSelect;

  const BookingFilterStrip({
    super.key,
    required this.filters,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF0077B6);

    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, i) {
          final f = filters[i];
          final isSel = selected == i;
          return ChoiceChip(
            avatar: Icon(f.icon, size: 18, color: isSel ? accent : Colors.black54),
            label: Text(f.label),
            selected: isSel,
            onSelected: (_) => onSelect(i),
            selectedColor: accent.withOpacity(0.14),
            labelStyle: TextStyle(
              color: isSel ? accent : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
            backgroundColor: Colors.white,
            side: const BorderSide(color: Colors.black12),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: filters.length,
      ),
    );
  }
}
