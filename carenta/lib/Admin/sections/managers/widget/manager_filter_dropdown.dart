import 'package:flutter/material.dart';

class ManagerFilterDropdown extends StatelessWidget {
  final String currentValue;
  final ValueChanged<String> onChanged;
  const ManagerFilterDropdown({
    super.key,
    required this.currentValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: currentValue,
      items: const [
        DropdownMenuItem(value: 'All Managers', child: Text('All Managers')),
        DropdownMenuItem(value: 'active', child: Text('Active')),
        DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}
