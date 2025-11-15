import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:carenta/service/util_service/session_manager_service.dart';
import 'package:carenta/user/user_home_screen/booking_payment_screen/service/booking_payment_service.dart';
import 'package:carenta/user/user_home_screen/booking_payment_screen/widget/payment_method_tile.dart';
import 'package:carenta/user/user_home_screen/booking_payment_screen/widget/payment_summary_card.dart';
import 'package:carenta/user/booking_screen/user_booking_screen.dart';

class BookingPaymentScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  const BookingPaymentScreen({super.key, required this.booking});

  @override
  State<BookingPaymentScreen> createState() => _BookingPaymentScreenState();
}

class _BookingPaymentScreenState extends State<BookingPaymentScreen>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _currencyFmt = NumberFormat('#,##0.##');
  final _paymentSvc = BookingPaymentService();

  String _selectedMethod = '';
  String _selectedPhase = 'deposit';
  bool _loading = false;

  Timer? _pollTimer;
  bool _isPolling = false;
  int _pollSeconds = 0;
  String? _referenceNo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _paymentSvc.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        !_isPolling &&
        _referenceNo != null) {
      _startPollingPaymentStatus(_referenceNo!);
    }
  }

  void _onMethodSelected(String method) {
    setState(() => _selectedMethod = method);
  }

  // ============================================================
  // 🔥 CONFIRM PAYMENT — CREATE CHECKOUT SESSION
  // ============================================================
  Future<void> _onConfirm() async {
    if (_selectedMethod.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a payment method.")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final booking = widget.booking;

      // ✅ FIX: Get userId from SessionAccount object
      final session = await SessionManagerService.getSession();
      if (session == null || session.userId == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Session error. Please log in again.")),
        );
        return;
      }
      final userId = session.userId;

      final total = double.tryParse(booking['total_amount'].toString()) ?? 0.0;

      final amount = _selectedPhase == 'deposit' ? (total * 0.3) : total;

      // 🔗 Create PayMongo checkout session
      final result = await _paymentSvc.createCheckout(
        userId: userId,
        carId: booking['car_id'],
        startDate: booking['start_date'],
        startTime: booking['start_time'],
        endDate: booking['end_date'],
        endTime: booking['end_time'],
        pickupLocation: booking['pickup_location'],
        dropoffLocation: booking['dropoff_location'],
        amount: amount,
        method: _selectedMethod,
        phase: _selectedPhase,
        depositPercent: 30.0,
      );

      final checkoutUrl = result['checkoutUrl'];
      _referenceNo = result['referenceNo'];

      if (checkoutUrl == null || checkoutUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to create checkout session.")),
        );
        return;
      }

      // 🧭 Open PayMongo checkout page
      await _openCheckout(checkoutUrl);

      // Start polling
      _startPollingPaymentStatus(_referenceNo!);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openCheckout(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.inAppWebView);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to open checkout: $e")));
    }
  }

  // ============================================================
  // 🔄 POLL PAYMENT STATUS UNTIL PAID
  // ============================================================
  void _startPollingPaymentStatus(String referenceNo) {
    if (_isPolling) return;

    _isPolling = true;
    _pollSeconds = 0;

    _pollTimer = Timer.periodic(const Duration(seconds: 3), (t) async {
      _pollSeconds += 3;

      try {
        final status = await _paymentSvc.checkPaymentStatus(referenceNo);

        if (status == 'paid') {
          t.cancel();
          _isPolling = false;

          if (!mounted) return;

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("✅ Payment confirmed!")));

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const UserBookingScreen()),
            (route) => false,
          );
        }
      } catch (_) {}

      if (_pollSeconds >= 120) {
        t.cancel();
        _isPolling = false;

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Payment still pending. Check your bookings."),
          ),
        );

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const UserBookingScreen()),
          (route) => false,
        );
      }
    });
  }

  // ============================================================
  // UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;

    final total = double.tryParse(booking['total_amount'].toString()) ?? 0.0;

    final displayTotal = _selectedPhase == 'deposit' ? (total * 0.3) : total;

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
            onPressed: _loading ? null : _onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5722),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child:
                _loading
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                    : const Text(
                      'Confirm Payment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            PaymentSummaryCard(
              carName: booking['car_name'],
              days: booking['days'],
              pickup: booking['pickup_location'],
              dropoff: booking['dropoff_location'],
              total: displayTotal,
              currency: currency,
              currencyFmt: _currencyFmt,
            ),
            const SizedBox(height: 20),

            const Text(
              "Select Payment Option",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text("Pay 30% Deposit"),
                    value: "deposit",
                    groupValue: _selectedPhase,
                    onChanged: (val) {
                      setState(() => _selectedPhase = val!);
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text("Pay Full Amount"),
                    value: "full",
                    groupValue: _selectedPhase,
                    onChanged: (val) {
                      setState(() => _selectedPhase = val!);
                    },
                  ),
                ),
              ],
            ),

            const Divider(height: 32),

            const Text(
              "Select Payment Method",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),

            PaymentMethodTile(
              label: "GCash",
              icon: Icons.account_balance_wallet,
              selected: _selectedMethod == 'gcash',
              onTap: () => _onMethodSelected('gcash'),
            ),
            PaymentMethodTile(
              label: "Credit / Debit Card",
              icon: Icons.credit_card,
              selected: _selectedMethod == 'card',
              onTap: () => _onMethodSelected('card'),
            ),
          ],
        ),
      ),
    );
  }
}
