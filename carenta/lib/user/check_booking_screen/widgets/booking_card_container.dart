// lib/user/bookings/widget/booking_card_container.dart

import 'package:flutter/material.dart';

class BookingCardContainer extends StatelessWidget {
  final Widget child;
  const BookingCardContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(borderRadius: BorderRadius.circular(16), child: child);
  }
}
