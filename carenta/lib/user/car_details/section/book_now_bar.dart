import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookNowBar extends StatelessWidget {
  final dynamic dailyRate;
  final String currency;
  final VoidCallback onBook;

  const BookNowBar({
    super.key,
    required this.dailyRate,
    required this.currency,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final rate =
        (dailyRate is num)
            ? dailyRate.toDouble()
            : double.tryParse(dailyRate.toString()) ?? 0;
    final priceFmt = NumberFormat('#,##0.##');
    final symbol =
        currency.toUpperCase() == 'USD'
            ? '\$'
            : currency.toUpperCase() == 'EUR'
            ? '€'
            : '₱';

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black87),
                  children: [
                    const TextSpan(
                      text: 'From ',
                      style: TextStyle(fontSize: 12),
                    ),
                    TextSpan(
                      text: '$symbol${priceFmt.format(rate)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const TextSpan(
                      text: '/day',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5722),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: onBook,
              child: const Text(
                'Book Now',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
