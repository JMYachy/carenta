import 'package:flutter/material.dart';

class CarPriceForm extends StatefulWidget {
  final Map<String, dynamic> price;
  final Future<void> Function(Map<String, dynamic> updatedPrice) onSaved;

  const CarPriceForm({super.key, required this.price, required this.onSaved});

  @override
  State<CarPriceForm> createState() => _CarPriceFormState();
}

class _CarPriceFormState extends State<CarPriceForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController currencyCtrl;
  late final TextEditingController dailyRateCtrl;
  late final TextEditingController min1Ctrl;
  late final TextEditingController disc1Ctrl;
  late final TextEditingController min2Ctrl;
  late final TextEditingController disc2Ctrl;
  late final TextEditingController min3Ctrl;
  late final TextEditingController disc3Ctrl;

  @override
  void initState() {
    super.initState();
    final p = widget.price;
    currencyCtrl = TextEditingController(text: '${p['currency'] ?? 'PHP'}');
    dailyRateCtrl = TextEditingController(text: '${p['daily_rate'] ?? ''}');
    min1Ctrl = TextEditingController(text: '${p['min_days_for_promo1'] ?? 3}');
    disc1Ctrl = TextEditingController(
      text: '${p['promo1_discount_percent'] ?? 10}',
    );
    min2Ctrl = TextEditingController(text: '${p['min_days_for_promo2'] ?? 7}');
    disc2Ctrl = TextEditingController(
      text: '${p['promo2_discount_percent'] ?? 15}',
    );
    min3Ctrl = TextEditingController(text: '${p['min_days_for_promo3'] ?? 30}');
    disc3Ctrl = TextEditingController(
      text: '${p['promo3_discount_percent'] ?? 20}',
    );
  }

  @override
  void dispose() {
    currencyCtrl.dispose();
    dailyRateCtrl.dispose();
    min1Ctrl.dispose();
    disc1Ctrl.dispose();
    min2Ctrl.dispose();
    disc2Ctrl.dispose();
    min3Ctrl.dispose();
    disc3Ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'Pricing',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  FilledButton(onPressed: _save, child: const Text('Save')),
                ],
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  _w(_tf('Currency', currencyCtrl, required: true)),
                  _w(
                    _tf(
                      'Daily Rate',
                      dailyRateCtrl,
                      required: true,
                      keyboard: TextInputType.number,
                    ),
                  ),
                  _w(
                    _tf(
                      'Min Days (Promo 1)',
                      min1Ctrl,
                      keyboard: TextInputType.number,
                    ),
                  ),
                  _w(
                    _tf(
                      'Discount % (Promo 1)',
                      disc1Ctrl,
                      keyboard: TextInputType.number,
                    ),
                  ),
                  _w(
                    _tf(
                      'Min Days (Promo 2)',
                      min2Ctrl,
                      keyboard: TextInputType.number,
                    ),
                  ),
                  _w(
                    _tf(
                      'Discount % (Promo 2)',
                      disc2Ctrl,
                      keyboard: TextInputType.number,
                    ),
                  ),
                  _w(
                    _tf(
                      'Min Days (Promo 3)',
                      min3Ctrl,
                      keyboard: TextInputType.number,
                    ),
                  ),
                  _w(
                    _tf(
                      'Discount % (Promo 3)',
                      disc3Ctrl,
                      keyboard: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _w(Widget child) => SizedBox(width: 320, child: child);

  Widget _tf(
    String label,
    TextEditingController c, {
    bool required = false,
    TextInputType? keyboard,
  }) {
    return TextFormField(
      controller: c,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (v) {
        if (required && (v == null || v.trim().isEmpty)) return 'Required';
        return null;
      },
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final updated = <String, dynamic>{
      'currency': currencyCtrl.text.trim(),
      'daily_rate': dailyRateCtrl.text.trim(),
      'min_days_for_promo1': min1Ctrl.text.trim(),
      'promo1_discount_percent': disc1Ctrl.text.trim(),
      'min_days_for_promo2': min2Ctrl.text.trim(),
      'promo2_discount_percent': disc2Ctrl.text.trim(),
      'min_days_for_promo3': min3Ctrl.text.trim(),
      'promo3_discount_percent': disc3Ctrl.text.trim(),
    };
    await widget.onSaved(updated);
  }
}
