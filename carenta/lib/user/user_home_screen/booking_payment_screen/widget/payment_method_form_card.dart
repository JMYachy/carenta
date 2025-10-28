import 'package:flutter/material.dart';

class PaymentMethodFormCard extends StatefulWidget {
  final Function(Map<String, dynamic>) onChanged;
  const PaymentMethodFormCard({super.key, required this.onChanged});

  @override
  State<PaymentMethodFormCard> createState() => _PaymentMethodFormCardState();
}

class _PaymentMethodFormCardState extends State<PaymentMethodFormCard> {
  final _cardNo = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          TextFormField(
            controller: _cardNo,
            decoration: const InputDecoration(labelText: 'Card Number', hintText: '1234 5678 9012 3456'),
            keyboardType: TextInputType.number,
            validator: (v) => (v == null || v.isEmpty) ? 'Enter card number' : null,
            onChanged: (_) => _update(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _expiry,
                  decoration: const InputDecoration(labelText: 'Expiry', hintText: 'MM/YY'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Enter expiry' : null,
                  onChanged: (_) => _update(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _cvv,
                  decoration: const InputDecoration(labelText: 'CVV'),
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || v.isEmpty) ? 'Enter CVV' : null,
                  onChanged: (_) => _update(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _update() {
    widget.onChanged({
      "method": "Card",
      "account_no": "****${_cardNo.text.trim().substring(_cardNo.text.length - 4)}",
      "bank_name": "Card",
      "status": "paid",
      "remarks": "Simulated card payment"
    });
  }
}
