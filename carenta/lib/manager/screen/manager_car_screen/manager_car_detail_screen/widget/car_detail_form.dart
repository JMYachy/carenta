import 'package:flutter/material.dart';

class CarDetailForm extends StatefulWidget {
  final Map<String, dynamic> car;
  final Future<void> Function(Map<String, dynamic> updatedFields) onSaved;

  const CarDetailForm({super.key, required this.car, required this.onSaved});

  @override
  State<CarDetailForm> createState() => _CarDetailFormState();
}

class _CarDetailFormState extends State<CarDetailForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController yearCtrl;
  late final TextEditingController makeCtrl;
  late final TextEditingController modelCtrl;
  late final TextEditingController typeCtrl;
  late final TextEditingController plateCtrl;
  late final TextEditingController colorCtrl;
  late final TextEditingController transCtrl;
  late final TextEditingController fuelCtrl;
  late final TextEditingController mileageCtrl;
  late final TextEditingController seatingCtrl;
  String withDriver = 'No'; // matches schema

  @override
  void initState() {
    super.initState();
    final c = widget.car;
    yearCtrl = TextEditingController(text: '${c['year'] ?? ''}');
    makeCtrl = TextEditingController(text: '${c['manufacturer'] ?? ''}');
    modelCtrl = TextEditingController(text: '${c['model'] ?? ''}');
    typeCtrl = TextEditingController(text: '${c['type'] ?? ''}');
    plateCtrl = TextEditingController(text: '${c['license_plate'] ?? ''}');
    colorCtrl = TextEditingController(text: '${c['color'] ?? ''}');
    transCtrl = TextEditingController(text: '${c['transmission'] ?? ''}');
    fuelCtrl = TextEditingController(text: '${c['fueltype'] ?? ''}');
    mileageCtrl = TextEditingController(text: '${c['milage'] ?? ''}');
    seatingCtrl = TextEditingController(text: '${c['seatingcap'] ?? ''}');
    withDriver = '${c['withDriver'] ?? 'No'}';
  }

  @override
  void dispose() {
    yearCtrl.dispose();
    makeCtrl.dispose();
    modelCtrl.dispose();
    typeCtrl.dispose();
    plateCtrl.dispose();
    colorCtrl.dispose();
    transCtrl.dispose();
    fuelCtrl.dispose();
    mileageCtrl.dispose();
    seatingCtrl.dispose();
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
                    'Car Details',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  FilledButton(onPressed: _save, child: const Text('Save')),
                ],
              ),
              const SizedBox(height: 12),

              // Grid-like layout with Wrap
              Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  _w(field: _tf('Year', yearCtrl, required: true)),
                  _w(field: _tf('Manufacturer', makeCtrl, required: true)),
                  _w(field: _tf('Model', modelCtrl, required: true)),
                  _w(field: _tf('Type', typeCtrl, required: true)),
                  _w(field: _tf('License Plate', plateCtrl, required: true)),
                  _w(field: _tf('Color', colorCtrl)),
                  _w(field: _tf('Transmission', transCtrl)),
                  _w(field: _tf('Fuel Type', fuelCtrl)),
                  _w(
                    field: _tf(
                      'Mileage',
                      mileageCtrl,
                      keyboard: TextInputType.number,
                    ),
                  ),
                  _w(
                    field: _tf(
                      'Seating Capacity',
                      seatingCtrl,
                      keyboard: TextInputType.number,
                    ),
                  ),
                  SizedBox(
                    width: 320,
                    child: DropdownButtonFormField<String>(
                      value: withDriver,
                      items: const [
                        DropdownMenuItem(value: 'No', child: Text('No Driver')),
                        DropdownMenuItem(
                          value: 'Yes',
                          child: Text('With Driver'),
                        ),
                      ],
                      onChanged: (v) => setState(() => withDriver = v ?? 'No'),
                      decoration: const InputDecoration(
                        labelText: 'With Driver',
                        border: OutlineInputBorder(),
                      ),
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

  Widget _w({required Widget field}) {
    return SizedBox(width: 320, child: field);
  }

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
    final fields = <String, dynamic>{
      'year': yearCtrl.text.trim(),
      'manufacturer': makeCtrl.text.trim(),
      'model': modelCtrl.text.trim(),
      'type': typeCtrl.text.trim(),
      'license_plate': plateCtrl.text.trim(),
      'color': colorCtrl.text.trim(),
      'transmission': transCtrl.text.trim(),
      'fueltype': fuelCtrl.text.trim(),
      'milage': mileageCtrl.text.trim(),
      'seatingcap': seatingCtrl.text.trim(),
      'withDriver': withDriver,
    };
    await widget.onSaved(fields);
  }
}
