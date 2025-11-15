import 'dart:io';
import 'package:carenta/manager/screen/manager_car_screen/manager_add_car/model/manager_add_car_form_model.dart';
import 'package:carenta/manager/screen/manager_car_screen/manager_add_car/service/manager_add_car_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class ManagerAddCarScreen extends StatefulWidget {
  const ManagerAddCarScreen({super.key});

  @override
  State<ManagerAddCarScreen> createState() => _ManagerAddCarScreenState();
}

class _ManagerAddCarScreenState extends State<ManagerAddCarScreen> {
  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();
  final form = ManagerAddCarFormModel();
  final picker = ImagePicker();

  static const _primary = Color(0xFF2563EB);
  static const _textOnPrimary = Colors.white;

  bool _submitting = false;
  int _stepIndex = 0;

  Future<void> _pickImages() async {
    final picks = await picker.pickMultiImage(imageQuality: 90);
    if (picks.isNotEmpty) {
      setState(() => form.imageFiles.addAll(picks.map((x) => File(x.path))));
    }
  }

  Future<void> _pickVideo() async {
    final picked = await picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) setState(() => form.videoFile = File(picked.path));
  }

  void _nextStep() {
    final formKey =
        _stepIndex == 0
            ? _formKeyStep1
            : _stepIndex == 1
            ? _formKeyStep2
            : null;
    if (formKey != null && !(formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_stepIndex < 2) {
      setState(() => _stepIndex++);
    } else {
      _submit();
    }
  }

  void _prevStep() {
    if (_stepIndex > 0) setState(() => _stepIndex--);
  }

  Future<void> _submit() async {
    // Validate all forms first
    final valid1 = _formKeyStep1.currentState?.validate() ?? false;
    final valid2 = _formKeyStep2.currentState?.validate() ?? false;
    if (!valid1 || !valid2) return;

    if (form.imageFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please add at least one image before finishing."),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final res = await ManagerAddCarService.addCar(form);

      if (!mounted) return;
      setState(() => _submitting = false);

      if (res.success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("✅ ${res.message}")));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "❌ ${res.message.isNotEmpty ? res.message : "Error submitting car"}",
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Submission failed: ${e.toString()}")),
      );
    }
  }

  Widget _field({
    required String label,
    required Function(String) onChanged,
    TextInputType type = TextInputType.text,
    IconData? icon,
    List<TextInputFormatter>? formatters,
  }) {
    return TextFormField(
      keyboardType: type,
      inputFormatters: formatters,
      validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: _primary, width: 1.6),
        ),
      ),
      onChanged: onChanged,
    );
  }

  Widget _row2(Widget a, Widget b) {
    return Row(
      children: [
        Expanded(child: a),
        const SizedBox(width: 12),
        Expanded(child: b),
      ],
    );
  }

  Widget _controls({required bool isLast}) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_stepIndex > 0)
            TextButton(onPressed: _prevStep, child: const Text("Back")),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _submitting ? null : (isLast ? _submit : _nextStep),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: _textOnPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
            child:
                _submitting
                    ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _textOnPrimary,
                      ),
                    )
                    : Text(isLast ? "Finish" : "Next"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Vehicle"),
        backgroundColor: _primary,
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Stepper(
          type: StepperType.horizontal,
          currentStep: _stepIndex,
          physics: const ClampingScrollPhysics(),
          onStepTapped: (index) {
            if (index <= _stepIndex) setState(() => _stepIndex = index);
          },
          onStepContinue: _nextStep,
          onStepCancel: _prevStep,
          controlsBuilder: (context, details) => const SizedBox.shrink(),
          steps: [
            // STEP 1 --------------------------
            Step(
              title: const Text("Car Details"),
              isActive: _stepIndex >= 0,
              state: _stepIndex > 0 ? StepState.complete : StepState.indexed,
              content: Form(
                key: _formKeyStep1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _row2(
                      _field(
                        label: "Year",
                        onChanged: (v) => form.year = v,
                        type: TextInputType.number,
                        icon: Icons.event,
                        formatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                      _field(
                        label: "Type",
                        onChanged: (v) => form.type = v,
                        icon: Icons.category,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _field(label: "Model", onChanged: (v) => form.model = v),
                    const SizedBox(height: 12),
                    _row2(
                      _field(
                        label: "License Plate",
                        onChanged: (v) => form.licensePlate = v,
                      ),
                      _field(label: "Color", onChanged: (v) => form.color = v),
                    ),
                    const SizedBox(height: 12),
                    _field(
                      label: "Manufacturer",
                      onChanged: (v) => form.manufacturer = v,
                    ),
                    const SizedBox(height: 12),
                    _row2(
                      _field(
                        label: "Transmission",
                        onChanged: (v) => form.transmission = v,
                      ),
                      _field(
                        label: "Fuel Type",
                        onChanged: (v) => form.fuelType = v,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _row2(
                      _field(
                        label: "Mileage (km)",
                        onChanged: (v) => form.milage = v,
                        type: TextInputType.number,
                      ),
                      _field(
                        label: "Seating Capacity",
                        onChanged: (v) => form.seatingCap = v,
                        type: TextInputType.number,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: form.withDriver,
                      decoration: const InputDecoration(
                        labelText: "With Driver",
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Yes', child: Text("Yes")),
                        DropdownMenuItem(value: 'No', child: Text("No")),
                      ],
                      onChanged: (v) => form.withDriver = v ?? 'No',
                    ),
                    _controls(isLast: false),
                  ],
                ),
              ),
            ),
            // STEP 2 --------------------------
            Step(
              title: const Text("Pricing"),
              isActive: _stepIndex >= 1,
              state: _stepIndex > 1 ? StepState.complete : StepState.indexed,
              content: Form(
                key: _formKeyStep2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _row2(
                      _field(
                        label: "Daily Rate (₱)",
                        onChanged: (v) => form.dailyRate = v,
                        type: TextInputType.number,
                      ),
                      _field(
                        label: "Promo 1 Discount (%)",
                        onChanged: (v) => form.promo1 = v,
                        type: TextInputType.number,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _row2(
                      _field(
                        label: "Promo 2 Discount (%)",
                        onChanged: (v) => form.promo2 = v,
                        type: TextInputType.number,
                      ),
                      _field(
                        label: "Promo 3 Discount (%)",
                        onChanged: (v) => form.promo3 = v,
                        type: TextInputType.number,
                      ),
                    ),
                    _controls(isLast: false),
                  ],
                ),
              ),
            ),
            // STEP 3 --------------------------
            Step(
              title: const Text("Media"),
              isActive: _stepIndex >= 2,
              state: _stepIndex == 2 ? StepState.indexed : StepState.complete,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickImages,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: _textOnPrimary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.image, size: 22),
                          label: const Text(
                            "Add Images",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (form.imageFiles.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children:
                                form.imageFiles
                                    .map(
                                      (f) => Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.file(
                                              f,
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: GestureDetector(
                                              onTap:
                                                  () => setState(
                                                    () => form.imageFiles
                                                        .remove(f),
                                                  ),
                                              child: Container(
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.black54,
                                                ),
                                                padding: const EdgeInsets.all(
                                                  2,
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  size: 14,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                    .toList(),
                          ),
                        const SizedBox(height: 30),
                        ElevatedButton.icon(
                          onPressed: _pickVideo,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.videocam, size: 22),
                          label: const Text(
                            "Add Video",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        if (form.videoFile != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              "📹 Selected: ${form.videoFile!.path.split('/').last}",
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _controls(isLast: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
