// lib/manager/screen/manager_car_screen/widget/car_info_section.dart
import 'package:flutter/material.dart';

class CarInfoSection extends StatelessWidget {
  final TextEditingController model;
  final TextEditingController manufacturer;
  final TextEditingController color;
  final TextEditingController license;
  final TextEditingController mileage;
  final TextEditingController rate;
  final bool editable;

  const CarInfoSection({
    super.key,
    required this.model,
    required this.manufacturer,
    required this.color,
    required this.license,
    required this.mileage,
    required this.rate,
    required this.editable,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _row2(
          _input("Manufacturer", manufacturer, editable),
          _input("Model", model, editable),
        ),
        const SizedBox(height: 12),
        _row2(
          _input("Color", color, editable),
          _input("License Plate", license, editable),
        ),
        const SizedBox(height: 12),
        _row2(
          _input("Mileage (km)", mileage, editable, type: TextInputType.number),
          _input("Daily Rate (₱)", rate, editable, type: TextInputType.number),
        ),
      ],
    );
  }

  Widget _row2(Widget a, Widget b) => Row(
    children: [
      Expanded(child: a),
      const SizedBox(width: 12),
      Expanded(child: b),
    ],
  );

  Widget _input(
    String label,
    TextEditingController ctrl,
    bool enabled, {
    TextInputType type = TextInputType.text,
  }) {
    return TextFormField(
      controller: ctrl,
      enabled: enabled,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: !enabled,
        fillColor: !enabled ? Colors.grey.shade100 : null,
      ),
    );
  }
}
