import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookingCarHeader extends StatelessWidget {
  final Map<String, dynamic> car;
  final double dailyRate;
  const BookingCarHeader({super.key, required this.car, required this.dailyRate});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.##');
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${car['manufacturer']} ${car['model']}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('${car['type']} • ${car['year']}'),
            const Divider(height: 16),
            Text('₱${fmt.format(dailyRate)} / day',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
