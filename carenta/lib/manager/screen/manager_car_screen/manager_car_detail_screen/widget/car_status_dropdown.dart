import 'package:flutter/material.dart';

class CarStatusDropdown extends StatelessWidget {
  final String status;
  final bool editable;
  final ValueChanged<String>? onChanged;

  const CarStatusDropdown({
    super.key,
    required this.status,
    required this.editable,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: status,
      decoration: const InputDecoration(
        labelText: "Status",
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'available', child: Text("Available")),
        DropdownMenuItem(value: 'rented', child: Text("Rented")),
        DropdownMenuItem(value: 'maintenance', child: Text("Maintenance")),
        DropdownMenuItem(value: 'inactive', child: Text("Inactive")),
      ],
      onChanged:
          editable
              ? (String? value) {
                if (value != null && onChanged != null) {
                  onChanged!(value);
                }
              }
              : null,
    );
  }
}
