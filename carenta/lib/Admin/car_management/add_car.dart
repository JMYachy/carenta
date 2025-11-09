import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:carenta/service/admin/admin_add_car_service.dart';

class AddCar extends StatefulWidget {
  const AddCar({super.key});

  @override
  State<AddCar> createState() => _AddCarState();
}

class _AddCarState extends State<AddCar> {
  final _formKey = GlobalKey<FormState>();
  int _stepIndex = 0;

  // --- Car Fields ---
  final _year = TextEditingController();
  final _manufacturer = TextEditingController();
  final _model = TextEditingController();
  final _type = TextEditingController();
  final _plate = TextEditingController();
  final _color = TextEditingController();
  final _transmission = TextEditingController();
  final _fuel = TextEditingController();
  final _milage = TextEditingController();
  final _seating = TextEditingController();

  // --- Status ---
  String _status = 'available';
  String _withDriver = 'No';

  // --- Pricing ---
  final _dailyRate = TextEditingController();
  final _promo1 = TextEditingController(text: "10");
  final _promo2 = TextEditingController(text: "15");
  final _promo3 = TextEditingController(text: "20");

  // --- Schedule ---
  final Map<String, bool> _days = {
    'Monday': true,
    'Tuesday': true,
    'Wednesday': true,
    'Thursday': true,
    'Friday': true,
    'Saturday': false,
    'Sunday': false,
  };
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  // --- Media ---
  final List<File> _images = [];
  File? _video;
  final _picker = ImagePicker();

  bool _submitting = false;

  Future<void> _pickImages() async {
    final picks = await _picker.pickMultiImage(imageQuality: 90);
    if (picks.isNotEmpty) {
      setState(() => _images.addAll(picks.map((x) => File(x.path))));
    }
  }

  Future<void> _pickVideo() async {
    final picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) setState(() => _video = File(picked.path));
  }

  Future<void> _selectTime(bool isStart) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (t != null) {
      setState(() {
        if (isStart) {
          _startTime = t;
        } else {
          _endTime = t;
        }
      });
    }
  }

  Widget _input(String label, TextEditingController c,
      {TextInputType type = TextInputType.text,
      IconData? icon,
      List<TextInputFormatter>? formatters}) {
    return TextFormField(
      controller: c,
      keyboardType: type,
      inputFormatters: formatters,
      validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _nextStep() {
    if (_formKey.currentState!.validate()) {
      if (_stepIndex < 2) {
        setState(() => _stepIndex++);
      } else {
        _submit();
      }
    }
  }

  void _prevStep() {
    if (_stepIndex > 0) setState(() => _stepIndex--);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload at least one image.")),
      );
      return;
    }

    setState(() => _submitting = true);

    final schedule = _days.entries.map((e) {
      return {
        "day": e.key,
        "start_time": _startTime?.format(context) ?? "08:00",
        "end_time": _endTime?.format(context) ?? "17:00",
        "is_available": e.value ? 1 : 0,
        "notes": null,
      };
    }).toList();

    final res = await AdminAddCarService.addCar(
      year: _year.text,
      manufacturer: _manufacturer.text,
      model: _model.text,
      type: _type.text,
      licensePlate: _plate.text,
      color: _color.text,
      transmission: _transmission.text,
      fuelType: _fuel.text,
      milage: _milage.text,
      seatingCap: _seating.text,
      status: _status,
      withDriver: _withDriver,
      dailyRate: _dailyRate.text,
      promo1: _promo1.text,
      promo2: _promo2.text,
      promo3: _promo3.text,
      schedule: schedule,
      adminId: null,
      imageFiles: _images,
      videoFile: _video,
    );

    setState(() => _submitting = false);

    if (res['success'] == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Car added successfully!")),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ ${res['message']}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Vehicle"),
        backgroundColor: const Color(0xFF0077B6),
        centerTitle: true,
      ),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _stepIndex,
        onStepContinue: _nextStep,
        onStepCancel: _prevStep,
        controlsBuilder: (context, details) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_stepIndex > 0)
              OutlinedButton(onPressed: _prevStep, child: const Text("Back")),
            ElevatedButton(
              onPressed: _submitting ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0077B6),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(_stepIndex == 2 ? "Submit" : "Next"),
            )
          ],
        ),
        steps: [
          Step(
            title: const Text("Details"),
            isActive: _stepIndex >= 0,
            content: Column(
              children: [
                _input("Year", _year,
                    type: TextInputType.number,
                    icon: Icons.event,
                    formatters: [FilteringTextInputFormatter.digitsOnly]),
                const SizedBox(height: 10),
                _input("Manufacturer", _manufacturer, icon: Icons.factory),
                const SizedBox(height: 10),
                _input("Model", _model, icon: Icons.directions_car),
                const SizedBox(height: 10),
                _input("Type", _type, icon: Icons.category),
                const SizedBox(height: 10),
                _input("License Plate", _plate, icon: Icons.confirmation_number),
                const SizedBox(height: 10),
                _input("Color", _color, icon: Icons.color_lens),
                const SizedBox(height: 10),
                _input("Transmission", _transmission, icon: Icons.settings),
                const SizedBox(height: 10),
                _input("Fuel Type", _fuel, icon: Icons.local_gas_station),
                const SizedBox(height: 10),
                _input("Mileage (km)", _milage,
                    type: TextInputType.number,
                    icon: Icons.speed,
                    formatters: [FilteringTextInputFormatter.digitsOnly]),
                const SizedBox(height: 10),
                _input("Seating Capacity", _seating,
                    type: TextInputType.number,
                    icon: Icons.event_seat,
                    formatters: [FilteringTextInputFormatter.digitsOnly]),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(labelText: "Status"),
                  items: const [
                    DropdownMenuItem(
                        value: 'available', child: Text("Available")),
                    DropdownMenuItem(
                        value: 'maintenance',
                        child: Text("Under Maintenance")),
                  ],
                  onChanged: (v) => setState(() => _status = v ?? 'available'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _withDriver,
                  decoration: const InputDecoration(labelText: "With Driver"),
                  items: const [
                    DropdownMenuItem(value: 'Yes', child: Text("Yes")),
                    DropdownMenuItem(value: 'No', child: Text("No")),
                  ],
                  onChanged: (v) => setState(() => _withDriver = v ?? 'No'),
                ),
              ],
            ),
          ),
          Step(
            title: const Text("Pricing"),
            isActive: _stepIndex >= 1,
            content: Column(
              children: [
                _input("Daily Rate (₱)", _dailyRate,
                    type: TextInputType.number, icon: Icons.price_change),
                const SizedBox(height: 10),
                _input("Promo 1 Discount %", _promo1,
                    type: TextInputType.number, icon: Icons.local_offer),
                const SizedBox(height: 10),
                _input("Promo 2 Discount %", _promo2,
                    type: TextInputType.number, icon: Icons.local_offer),
                const SizedBox(height: 10),
                _input("Promo 3 Discount %", _promo3,
                    type: TextInputType.number, icon: Icons.discount),
              ],
            ),
          ),
          Step(
            title: const Text("Media"),
            isActive: _stepIndex >= 2,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.image),
                  label: const Text("Add Images"),
                ),
                const SizedBox(height: 10),
                if (_images.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    children: _images
                        .map((f) => Image.file(f, width: 80, height: 80))
                        .toList(),
                  ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _pickVideo,
                  icon: const Icon(Icons.videocam),
                  label: const Text("Add Video"),
                ),
                if (_video != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text("📹 Video selected: ${_video!.path.split('/').last}"),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
