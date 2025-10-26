import 'package:flutter/material.dart';
import 'square_icon_button.dart';

class SortButton extends StatelessWidget {
  final String value;
  final ValueChanged<String> onSelected;

  const SortButton({super.key, required this.value, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    const items = [
      'Recently added',
      'Price: low to high',
      'Price: high to low',
      'Top rated',
    ];

    return PopupMenuButton<String>(
      tooltip: 'Sort',
      initialValue: value,
      onSelected: onSelected,
      itemBuilder: (ctx) =>
          items.map((e) => PopupMenuItem<String>(value: e, child: Text(e))).toList(),
      child: const SquareIconButton(
        icon: Icons.sort_rounded,
        tooltip: 'Sort',
        onTap: null,
      ),
    );
  }
}
