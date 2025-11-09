// lib/manager/manager_booking_screen/widget/booking_card_container.dart
import 'package:flutter/material.dart';

class BookingCardContainer extends StatelessWidget {
  final Widget child;
  const BookingCardContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: child,
    );
  }
}
