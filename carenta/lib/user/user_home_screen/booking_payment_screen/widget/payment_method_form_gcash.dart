import 'package:flutter/material.dart';

class PaymentMethodFormGcash extends StatefulWidget {
  final String label;
  final Function(Map<String, dynamic>) onChanged;

  const PaymentMethodFormGcash({super.key, required this.label, required this.onChanged});

  @override
  State<PaymentMethodFormGcash> createState() => _PaymentMethodFormGcashState();
}

class _PaymentMethodFormGcashState extends State<PaymentMethodFormGcash> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextFormField(
        controller: _controller,
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: '09XXXXXXXXX',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Please enter ${widget.label}';
          if (v.length < 10) return 'Invalid number';
          return null;
        },
        onChanged: (v) {
          widget.onChanged({
            "method": widget.label.contains('GCash') ? 'GCash' : 'PayMaya',
            "account_no": v,
            "bank_name": widget.label,
            "status": "paid",
            "remarks": "Simulated e-wallet transaction"
          });
        },
      ),
    );
  }
}
