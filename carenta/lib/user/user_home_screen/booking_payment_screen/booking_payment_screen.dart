import 'package:carenta/user/user_home_screen/booking_payment_screen/service/booking_payment_service.dart';
import 'package:carenta/user/user_home_screen/booking_payment_screen/widget/payment_method_tile.dart';
import 'package:carenta/user/user_home_screen/booking_payment_screen/widget/payment_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class BookingPaymentScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  const BookingPaymentScreen({super.key, required this.booking});

  @override
  State<BookingPaymentScreen> createState() => _BookingPaymentScreenState();
}

class _BookingPaymentScreenState extends State<BookingPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currencyFmt = NumberFormat('#,##0.##');

  String _selectedMethod = '';
  String _selectedPhase = 'deposit'; // default: deposit
  bool _loading = false;

  void _onMethodSelected(String method) {
    setState(() => _selectedMethod = method);
  }

  Future<void> _onConfirm() async {
    if (_selectedMethod.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a payment method.")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // Validate IDs
      final rentalIdRaw = widget.booking['rentalid'] ?? widget.booking['rental_id'];
      final userIdRaw = widget.booking['userid'] ?? widget.booking['user_id'];

      if (rentalIdRaw == null || userIdRaw == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Missing booking or user information.")),
        );
        setState(() => _loading = false);
        return;
      }

      final rentalId = int.tryParse(rentalIdRaw.toString()) ?? 0;
      final userId = int.tryParse(userIdRaw.toString()) ?? 0;

      if (rentalId == 0 || userId == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid booking data.")),
        );
        setState(() => _loading = false);
        return;
      }

      // 🔗 Create PayMongo checkout session
      final result = await BookingPaymentService.createCheckout(
        rentalId: rentalId,
        userId: userId,
        phase: _selectedPhase,
        depositPercent: 30.0,
      );

      if (result.ok && result.checkoutUrl != null && result.checkoutUrl!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Redirecting to PayMongo Checkout...")),
        );

        // 🧭 Open the checkout link safely
        await _openCheckout(result.checkoutUrl!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${result.message ?? 'Failed to create checkout.'}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }


  Future<void> _openCheckout(String url) async {
    final uri = Uri.parse(url);

    // Try to open in an external browser (Chrome, etc.)
    try {
      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (launched) return;
      }

      // Fallback to in-app WebView if no external browser is available
      await launchUrl(uri, mode: LaunchMode.inAppWebView);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to open checkout: $e")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;

    // ✅ Safe fallbacks for missing data
    final total = double.tryParse(booking['total_amount']?.toString() ?? '0') ?? 0.0;
    final currency = (booking['currency'] ?? 'PHP').toString().toUpperCase();
    final days = int.tryParse(booking['days']?.toString() ?? '0') ?? 0;
    final carName = booking['car_name']?.toString() ?? 'Unknown Vehicle';
    final pickup = booking['pickup_location']?.toString() ?? 'N/A';
    final dropoff = booking['dropoff_location']?.toString() ?? 'N/A';

    // 🧮 Dynamic total depending on phase (deposit/full)
    final displayTotal = _selectedPhase == 'deposit'
        ? (total * 0.3)
        : total;

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
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Confirm Payment',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 🧾 Booking Summary
            PaymentSummaryCard(
              carName: carName,
              days: days,
              pickup: pickup,
              dropoff: dropoff,
              total: displayTotal,
              currency: currency,
              currencyFmt: _currencyFmt,
            ),
            const SizedBox(height: 20),

            // 💰 Payment Option
            const Text("Select Payment Option",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
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

            // 💳 Payment Method
            const Text("Select Payment Method",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
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
            PaymentMethodTile(
              label: "Cash on Pickup",
              icon: Icons.money,
              selected: _selectedMethod == 'cash',
              onTap: () => _onMethodSelected('cash'),
            ),
          ],
        ),
      ),
    );
  }
}
