import 'package:carenta/service/user/post_payment_booking_service.dart';
import 'package:carenta/user/booking_screen/user_booking_screen.dart';
import 'package:carenta/user/user_home_screen/booking_payment_screen/widget/payment_method_form_card.dart';
import 'package:carenta/user/user_home_screen/booking_payment_screen/widget/payment_method_form_cash.dart';
import 'package:carenta/user/user_home_screen/booking_payment_screen/widget/payment_method_form_gcash.dart';
import 'package:carenta/user/user_home_screen/booking_payment_screen/widget/payment_method_tile.dart';
import 'package:carenta/user/user_home_screen/booking_payment_screen/widget/payment_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// ===============================================================
///  BOOKING PAYMENT SCREEN (PARENT)
/// ===============================================================
class BookingPaymentScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  const BookingPaymentScreen({super.key, required this.booking});

  @override
  State<BookingPaymentScreen> createState() => _BookingPaymentScreenState();
}

class _BookingPaymentScreenState extends State<BookingPaymentScreen> {
  String _selectedMethod = '';
  final _formKey = GlobalKey<FormState>();
  final _currencyFmt = NumberFormat('#,##0.##');

  Map<String, dynamic> _paymentData = {};

  bool _loading = false;

  void _onMethodSelected(String method) {
    setState(() {
      _selectedMethod = method;
      _paymentData.clear();
    });
  }

  void _onFormDataChanged(Map<String, dynamic> data) {
    _paymentData = data;
  }

  Future<void> _onConfirm() async {
    if (_selectedMethod.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a payment method.")),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    // 🧾 Review confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final booking = widget.booking;
        final total = (booking['total_amount'] ?? 0).toDouble();
        final currency = (booking['currency'] ?? 'PHP').toString().toUpperCase();
        final symbol = switch (currency) {
          'USD' => '\$',
          'EUR' => '€',
          _ => '₱',
        };

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text("Review & Pay"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Car: ${booking['car_name']}", style: const TextStyle(fontWeight: FontWeight.w600)),
              Text("Duration: ${booking['days']} day(s)"),
              const Divider(),
              Text("Payment Method: ${_paymentData['method']}"),
              if (_paymentData['account_no'] != null)
                Text("Account: ${_paymentData['account_no']}"),
              if (_paymentData['bank_name'] != null)
                Text("Provider: ${_paymentData['bank_name']}"),
              const Divider(),
              Text(
                "Total: $symbol${NumberFormat('#,##0.##').format(total)}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722)),
              child: const Text("Confirm Payment"),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    // 🟠 Prepare booking + payment payload
    final booking = widget.booking;
    final payload = {
      "carid": booking["carid"],
      "userid": booking["userId"],
      "start_date": booking["start_date"],
      "end_date": booking["end_date"],
      "start_time": booking["pickup_time"],
      "end_time": booking["dropoff_time"],
      "pickup_location": booking["pickup_location"],
      "dropoff_location": booking["dropoff_location"],
      "total_amount": booking["total_amount"],
      "payment": _paymentData,
    };

    // 🟢 Submit booking + payment
    setState(() => _loading = true);
    final svc = UserPostPaymentBookingService();
    final result = await svc.submit(payload);
    setState(() => _loading = false);

    if (!mounted) return;

    if (result.success) {
      // ✅ Success → show confirmation and go to booking list
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ ${result.message}")),
      );

      await Future.delayed(const Duration(milliseconds: 600));

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const UserBookingScreen()),
        (route) => false, // clear navigation stack
      );
    } else {
      // ❌ Failure → show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ ${result.message}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final total = (booking['total_amount'] ?? 0).toDouble();
    final currency = (booking['currency'] ?? 'PHP').toString().toUpperCase();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text('Complete Your Payment'),
      ),
      backgroundColor: Colors.white,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5722),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Confirm Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            PaymentSummaryCard(
              carName: booking['car_name'] ?? '',
              days: booking['days'] ?? 0,
              pickup: booking['pickup_location'] ?? '',
              dropoff: booking['dropoff_location'] ?? '',
              total: total,
              currency: currency,
              currencyFmt: _currencyFmt,
            ),
            const SizedBox(height: 20),
            const Text("Select Payment Method", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),

            PaymentMethodTile(
              label: "GCash",
              icon: Icons.account_balance_wallet,
              selected: _selectedMethod == 'gcash',
              onTap: () => _onMethodSelected('gcash'),
            ),
            PaymentMethodTile(
              label: "PayMaya",
              icon: Icons.phone_android,
              selected: _selectedMethod == 'paymaya',
              onTap: () => _onMethodSelected('paymaya'),
            ),
            PaymentMethodTile(
              label: "Credit / Debit Card",
              icon: Icons.credit_card,
              selected: _selectedMethod == 'card',
              onTap: () => _onMethodSelected('card'),
            ),
            PaymentMethodTile(
              label: "Cash on Pickup",
              icon: Icons.money,
              selected: _selectedMethod == 'cash',
              onTap: () => _onMethodSelected('cash'),
            ),

            const SizedBox(height: 20),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: switch (_selectedMethod) {
                'gcash' => PaymentMethodFormGcash(
                    key: const ValueKey('gcash'),
                    label: 'GCash Number',
                    onChanged: _onFormDataChanged,
                  ),
                'paymaya' => PaymentMethodFormGcash(
                    key: const ValueKey('paymaya'),
                    label: 'PayMaya Number',
                    onChanged: _onFormDataChanged,
                  ),
                'card' => PaymentMethodFormCard(
                    key: const ValueKey('card'),
                    onChanged: _onFormDataChanged,
                  ),
                'cash' => PaymentMethodFormCash(
                    key: const ValueKey('cash'),
                    onChanged: _onFormDataChanged,
                  ),
                _ => const SizedBox.shrink(),
              },
            ),
          ],
        ),
      ),
    );
  }
}