import 'package:flutter/material.dart';

class BookingLoadingState extends StatelessWidget {
  const BookingLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(top: 48),
        child: CircularProgressIndicator(),
      ),
    );
  }
}
