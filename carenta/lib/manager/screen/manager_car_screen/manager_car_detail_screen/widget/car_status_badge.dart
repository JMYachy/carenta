import 'package:flutter/material.dart';

class CarStatusBadge extends StatelessWidget {
  final String text; // Available, Reserved, Rented, Maintenance, Inactive
  const CarStatusBadge({super.key, required this.text});

  static String effectiveStatus({
    required String carStatus,
    required String
    rentalStatus, // none | pending | confirmed | ongoing | completed | cancelled
  }) {
    final cs = carStatus.toLowerCase().trim();
    final rs = rentalStatus.toLowerCase().trim();

    if (rs == 'ongoing') return 'Rented';
    if (rs == 'pending' || rs == 'confirmed') return 'Reserved';
    if (cs == 'maintenance') return 'Maintenance';
    if (cs == 'inactive') return 'Inactive';
    return 'Available';
  }

  Color _bg(BuildContext ctx) {
    switch (text) {
      case 'Available':
        return Colors.green.withOpacity(0.12);
      case 'Reserved':
        return Colors.orange.withOpacity(0.12);
      case 'Rented':
        return Colors.amber.withOpacity(0.18);
      case 'Maintenance':
        return Colors.blueGrey.withOpacity(0.14);
      case 'Inactive':
        return Colors.black.withOpacity(0.10);
      default:
        return Theme.of(ctx).colorScheme.surfaceVariant.withOpacity(0.5);
    }
  }

  Color _fg(BuildContext ctx) {
    switch (text) {
      case 'Available':
        return Colors.green.shade700;
      case 'Reserved':
        return Colors.orange.shade700;
      case 'Rented':
        return Colors.amber.shade900;
      case 'Maintenance':
        return Colors.blueGrey.shade700;
      case 'Inactive':
        return Colors.grey.shade800;
      default:
        return Theme.of(ctx).colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _bg(context),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.w700, color: _fg(context)),
      ),
    );
  }
}
