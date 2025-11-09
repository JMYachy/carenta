import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardStatsCard extends StatelessWidget {
  final String title;
  final num value; // ✅ Accepts both int or double
  final IconData icon;
  final Color color;
  final bool isCurrency; // ✅ Optional toggle

  const DashboardStatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isCurrency = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = isCurrency
        ? NumberFormat.currency(symbol: '₱', decimalDigits: 0).format(value)
        : value.toString();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 38, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(
                    displayValue,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
