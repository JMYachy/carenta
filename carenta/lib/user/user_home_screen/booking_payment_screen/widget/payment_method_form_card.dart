import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  void dispose() {
    _cardNo.dispose();
    _expiry.dispose();
    _cvv.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          // 💳 Card Number
          TextFormField(
            controller: _cardNo,
            decoration: const InputDecoration(
              labelText: 'Card Number',
              hintText: '1234 5678 9012 3456',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _CardNumberFormatter(),
            ],
            validator: (v) {
              final digits = v?.replaceAll(RegExp(r'\s+'), '') ?? '';
              if (digits.isEmpty) return 'Enter card number';
              if (digits.length != 16) return 'Must be 16 digits';
              return null;
            },
            onChanged: (_) => _update(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // 🗓️ Expiry
              Expanded(
                child: TextFormField(
                  controller: _expiry,
                  decoration: const InputDecoration(
                    labelText: 'Expiry',
                    hintText: 'MM/YY',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _ExpiryFormatter(),
                  ],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter expiry';
                    if (!RegExp(r'^(0[1-9]|1[0-2])\/\d{2}$').hasMatch(v)) {
                      return 'Invalid expiry';
                    }
                    return null;
                  },
                  onChanged: (_) => _update(),
                ),
              ),
              const SizedBox(width: 10),
              // 🔐 CVV
              Expanded(
                child: TextFormField(
                  controller: _cvv,
                  decoration: const InputDecoration(labelText: 'CVV'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter CVV';
                    if (v.length != 3) return '3 digits only';
                    return null;
                  },
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
    final number = _cardNo.text.replaceAll(RegExp(r'\s+'), '').trim();
    String masked = '';
    if (number.length >= 4) {
      masked = "**** ${number.substring(number.length - 4)}";
    } else if (number.isNotEmpty) {
      masked = "**** $number";
    } else {
      masked = "****";
    }

    widget.onChanged({
      "method": "Card",
      "account_no": masked,
      "bank_name": "Credit / Debit Card",
      "status": "paid",
      "remarks": "Simulated card payment"
    });
  }
}

/// 🧩 Improved Card Number Formatter (keeps cursor position)
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      final nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != digits.length) {
        buffer.write(' ');
      }
    }

    final formatted = buffer.toString();
    int baseOffset = newValue.selection.baseOffset;
    int offset = formatted.length - newValue.text.length + baseOffset;
    if (offset < 0) offset = 0;
    if (offset > formatted.length) offset = formatted.length;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}

/// 🧩 Improved Expiry Formatter (keeps cursor position)
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 4) digits = digits.substring(0, 4);

    String formatted = '';
    if (digits.length >= 3) {
      formatted = '${digits.substring(0, 2)}/${digits.substring(2)}';
    } else {
      formatted = digits;
    }

    int baseOffset = newValue.selection.baseOffset;
    int offset = formatted.length - newValue.text.length + baseOffset;
    if (offset < 0) offset = 0;
    if (offset > formatted.length) offset = formatted.length;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
