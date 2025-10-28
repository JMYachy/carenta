import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentSummaryCard extends StatelessWidget {
  final String carName;
  final int days;
  final String pickup;
  final String dropoff;
  final double total;
  final String currency;
  final NumberFormat currencyFmt;

  const PaymentSummaryCard({
    super.key,
    required this.carName,
    required this.days,
    required this.pickup,
    required this.dropoff,
    required this.total,
    required this.currency,
    required this.currencyFmt,
  });

  String get symbol => switch (currency) {
        'USD' => '\$',
        'EUR' => '€',
        _ => '₱',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Booking Summary',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _row('Car', carName),
          _row('Rental Days', '$days'),
          _row('Pickup', pickup),
          _row('Dropoff', dropoff),
          const Divider(),
          _row('Total', '$symbol${currencyFmt.format(total)}',
              isBold: true, color: const Color(0xFFFF5722)),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
