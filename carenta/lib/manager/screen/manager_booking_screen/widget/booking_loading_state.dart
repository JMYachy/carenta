// lib/manager/manager_booking_screen/widget/booking_loading_state.dart
import 'package:flutter/material.dart';

class BookingLoadingState extends StatelessWidget {
  const BookingLoadingState({super.key});
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 40, 16, 40),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
