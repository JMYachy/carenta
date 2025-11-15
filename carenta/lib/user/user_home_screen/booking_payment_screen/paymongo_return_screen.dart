import 'package:carenta/user/user_home_screen/booking_payment_screen/booking_reciept_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:carenta/service/config/service_base_url.dart';
import 'package:carenta/user/booking_screen/user_booking_screen.dart';

class PaymongoReturnScreen extends StatefulWidget {
  final String referenceNo;
  final bool failed;

  const PaymongoReturnScreen({
    super.key,
    required this.referenceNo,
    this.failed = false,
  });

  @override
  State<PaymongoReturnScreen> createState() => _PaymongoReturnScreenState();
}

class _PaymongoReturnScreenState extends State<PaymongoReturnScreen> {
  @override
  void initState() {
    super.initState();
    _checkPaymentStatus();
  }

  Future<void> _checkPaymentStatus() async {
    if (widget.failed) {
      _goToError("Payment was cancelled.");
      return;
    }

    try {
      final url = ServiceBaseUrl.endpoint(
        "payment_status.php?ref=${Uri.encodeQueryComponent(widget.referenceNo)}",
      );

      final res = await http.get(Uri.parse(url));

      if (res.statusCode != 200) {
        _goToError("Unable to connect to server.");
        return;
      }

      final data = json.decode(res.body);

      if (data["success"] != true) {
        _goToError("Payment not found.");
        return;
      }

      final payment = data["payment"];
      final rental = data["rental"] ?? {};

      final status = payment["status"].toString().toLowerCase();

      if (status == "paid") {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder:
                (_) => BookingReceiptScreen(payment: payment, rental: rental),
          ),
        );
        return;
      }

      _goToError("Payment not completed.");
    } catch (e) {
      _goToError("Error checking payment status.");
    }
  }

  void _goToError(String message) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder:
            (_) =>
                PaymentFailedScreen(message: message, ref: widget.referenceNo),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class PaymentFailedScreen extends StatelessWidget {
  final String message;
  final String ref;

  const PaymentFailedScreen({
    super.key,
    required this.message,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payment Failed")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Reference: $ref"),
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const UserBookingScreen()),
                );
              },
              child: const Text("Return to Bookings"),
            ),
          ],
        ),
      ),
    );
  }
}
