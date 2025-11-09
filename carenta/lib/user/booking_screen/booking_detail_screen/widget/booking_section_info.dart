import 'package:flutter/material.dart';

class BookingSectionInfo extends StatelessWidget {
  final String label;
  final dynamic value;

  const BookingSectionInfo({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label, style: const TextStyle(color: Colors.black54))),
          Expanded(flex: 3, child: Text(value?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
