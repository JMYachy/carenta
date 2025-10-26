import 'package:flutter/material.dart';

class FilterSpec {
  final String label;
  final IconData icon;
  const FilterSpec(this.label, this.icon);
}

class FilterStrip extends StatelessWidget {
  final List<FilterSpec> filters;
  final int selected;
  final ValueChanged<int> onSelect;
  const FilterStrip({
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
              mainAxisSize: MainAxisSize.min,
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
