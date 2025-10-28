import 'package:carenta/manager/booking_screen/admin_booking_screen.dart';
import 'package:flutter/material.dart';

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
    return SizedBox(
      height: 64,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final isSelected = i == selected;
          return ChoiceChip(
            label: Row(
              children: [
                Icon(filters[i].icon, size: 18),
                const SizedBox(width: 6),
                Text(filters[i].label),
              ],
            ),
            selected: isSelected,
            onSelected: (_) => onSelect(i),
          );
        },
      ),
    );
  }
}
