import 'package:flutter/material.dart';

class PaymentMethodFormCash extends StatelessWidget {
  final Function(Map<String, dynamic>) onChanged;
  const PaymentMethodFormCash({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onChanged({
        "method": "Cash",
        "bank_name": "Cash",
        "status": "pending",
        "remarks": "Cash on pickup"
      });
    });

    return const Padding(
      padding: EdgeInsets.only(top: 12),
      child: Text(
        "Please prepare the exact amount upon pickup.",
        style: TextStyle(color: Colors.black54),
      ),
    );
  }
}
