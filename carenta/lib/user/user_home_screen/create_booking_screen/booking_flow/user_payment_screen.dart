import 'package:carenta/main/splash_screen.dart';
import 'package:carenta/service/user/user_payment_service.dart';
import 'package:carenta/service/util_service/session_manager_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> booking;

  const PaymentScreen({super.key, required this.booking});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int? _userId;
  bool _checkingSession = true;
  String _selectedMethod = '';
  bool _loading = false;
  final _currencyFmt = NumberFormat('#,##0.##');

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  // ✅ Validate active session before allowing payment
  Future<void> _checkSession() async {
    try {
      final res = await SessionManagerService.checkSession();
      if (res['success'] == true) {
        setState(() {
          _userId = res['data']?['userid'];
          _checkingSession = false;
        });
      } else {
        _redirectToSplash();
      }
    } catch (_) {
      _redirectToSplash();
    }
  }

  void _redirectToSplash() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SplashScreen()),
    );
  }

  // ✅ Create payment transaction
  Future<void> _confirmPayment() async {
    if (_selectedMethod.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a payment method")),
      );
      return;
    }

    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Session expired. Please log in again.")),
      );
      return;
    }

    final rentalId =
        widget.booking['rentalid'] ?? widget.booking['rentalId'] ?? 0;
    final totalAmount = (widget.booking['total_amount'] ?? 0).toDouble();

    if (rentalId == 0 || totalAmount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid booking data.")));
      return;
    }

    setState(() => _loading = true);

    try {
      final paymentService = UserPaymentService();
      final result = await paymentService.createPayment(
        userId: _userId!,
        rentalId: rentalId,
        amount: totalAmount,
        method: _selectedMethod.toUpperCase(),
        referenceNo: "SIM-${DateTime.now().millisecondsSinceEpoch}",
        status: _selectedMethod.toLowerCase() == 'cash' ? 'Pending' : 'Paid',
      );

      if (!mounted) return;

      if (result['ok'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ ${result['message']}"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ ${result['message']}"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSession) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final booking = widget.booking;
    final totalAmount = (booking['total_amount'] ?? 0).toDouble();
    final currency = (booking['currency'] ?? 'PHP').toString().toUpperCase();

    final currencySymbol = switch (currency) {
      'USD' => '\$',
      'EUR' => '€',
      'PHP' || _ => '₱',
    };

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        title: const Text('Payment'),
      ),
      bottomNavigationBar: SafeArea(
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
                child: Text(
                  '$currencySymbol${_currencyFmt.format(totalAmount)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
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
                onPressed: _loading ? null : _confirmPayment,
                child:
                    _loading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Text(
                          'Confirm Payment',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        children: [
          // Booking Summary
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Booking Summary',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                _SummaryRow(label: 'Car', value: booking['car_name'] ?? '—'),
                const Divider(),
                _SummaryRow(
                  label: 'Rental Days',
                  value: '${booking['days'] ?? '—'}',
                ),
                const Divider(),
                _SummaryRow(
                  label: 'Pickup Location',
                  value: booking['pickup_location'] ?? '—',
                ),
                const Divider(),
                _SummaryRow(
                  label: 'Dropoff Location',
                  value: booking['dropoff_location'] ?? '—',
                ),
                const Divider(),
                _SummaryRow(
                  label: 'Total Amount',
                  value: '$currencySymbol${_currencyFmt.format(totalAmount)}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          const Text(
            'Payment Methods',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _Card(
            child: Column(
              children: [
                _MethodTile(
                  label: 'GCash',
                  icon: Icons.account_balance_wallet,
                  selected: _selectedMethod == 'gcash',
                  onTap: () => setState(() => _selectedMethod = 'gcash'),
                ),
                const Divider(),
                _MethodTile(
                  label: 'PayMaya',
                  icon: Icons.phone_android,
                  selected: _selectedMethod == 'paymaya',
                  onTap: () => setState(() => _selectedMethod = 'paymaya'),
                ),
                const Divider(),
                _MethodTile(
                  label: 'Credit / Debit Card',
                  icon: Icons.credit_card,
                  selected: _selectedMethod == 'card',
                  onTap: () => setState(() => _selectedMethod = 'card'),
                ),
                const Divider(),
                _MethodTile(
                  label: 'Cash on Pickup',
                  icon: Icons.money,
                  selected: _selectedMethod == 'cash',
                  onTap: () => setState(() => _selectedMethod = 'cash'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//
// --- UI COMPONENTS ---
//
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Text(value, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}

class _MethodTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _MethodTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF0077B6)),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing:
          selected
              ? const Icon(Icons.check_circle, color: Color(0xFFFF5722))
              : const Icon(Icons.circle_outlined, color: Colors.black26),
      onTap: onTap,
    );
  }
}
