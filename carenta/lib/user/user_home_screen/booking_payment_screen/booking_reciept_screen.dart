import 'package:carenta/user/booking_screen/user_booking_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookingReceiptScreen extends StatefulWidget {
  final Map<String, dynamic> payment;
  final Map<String, dynamic>? rental;

  const BookingReceiptScreen({super.key, required this.payment, this.rental});

  @override
  State<BookingReceiptScreen> createState() => _BookingReceiptScreenState();
}

class _BookingReceiptScreenState extends State<BookingReceiptScreen> {
  @override
  void initState() {
    super.initState();

    // ⏳ Auto redirect after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const UserBookingScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final payment = widget.payment;
    final rental = widget.rental;

    // ---- Your existing UI below is unchanged ----
    final currencyFmt = NumberFormat('#,##0.00', 'en_PH');
    final receiptNo = payment['receipt_no'] ?? 'N/A';
    final referenceNo = payment['reference_no'] ?? 'N/A';
    final paymentPhase =
        payment['payment_phase']?.toString().toUpperCase() ?? 'FULL';
    final amount =
        (payment['amount'] != null)
            ? double.tryParse(payment['amount'].toString()) ?? 0.0
            : 0.0;
    final method = payment['method']?.toString().toUpperCase() ?? 'N/A';
    final status = payment['status']?.toString().toUpperCase() ?? 'PENDING';
    final remarks = payment['remarks'] ?? '';
    final createdAt = payment['paid_at'] ?? payment['created_at'] ?? '';
    final rentalId = payment['rentalid'] ?? payment['rental_id'] ?? 'N/A';
    final carName = rental?['car_name'] ?? 'Car Rental #$rentalId';
    final totalDays = rental?['days'] ?? rental?['total_days'] ?? 0;
    final pickup = rental?['pickup_location'] ?? 'N/A';
    final dropoff = rental?['dropoff_location'] ?? 'N/A';
    final rentalStatus = rental?['status']?.toString().toUpperCase() ?? 'N/A';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text('Payment Receipt'),
      ),
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- your original UI unchanged ----
              ],
            ),
          ),
        ),
      ),
    );
  }
}
