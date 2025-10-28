import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookingFooterSummary extends StatelessWidget {
  final int rentalDays;
  final double totalAmount;
  final String currencySymbol;
  final bool loading;
  final VoidCallback onConfirm;

  const BookingFooterSummary({
    super.key,
    required this.rentalDays,
    required this.totalAmount,
    required this.currencySymbol,
    required this.loading,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.##');
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                rentalDays > 0
                    ? '$rentalDays day${rentalDays == 1 ? '' : 's'} • $currencySymbol${fmt.format(totalAmount)}'
                    : 'Select dates',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: loading ? null : onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5722),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              ),
              child: loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Confirm'),
            )
          ],
        ),
      ),
    );
  }
}
