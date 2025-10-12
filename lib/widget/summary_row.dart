import 'package:flutter/material.dart';

/// A reusable row for displaying booking/payment details in "Label : Value" format.
/// Example: "Pickup Location : General Santos"
class SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const SummaryRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        Text(value, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}
