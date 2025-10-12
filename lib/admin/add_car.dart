import 'dart:io';
import 'package:carenta/service/admin/admin_add_car_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class AddCar extends StatefulWidget {
  const AddCar({super.key});

  @override
  State<AddCar> createState() => _AddCarState();
}

class _AddCarState extends State<AddCar> {
  final _formKey = GlobalKey<FormState>();

  // --- Car Details Controllers ---
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

  // --- Car Status ---
  String _status = 'available';
  String _withDriver = 'No';

  // --- Media ---
  final List<File> _images = [];
  File? _video;

  final _picker = ImagePicker();
  bool _submitting = false;

  Future<void> _pickImages() async {
    try {
      final picks = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );
      if (picks.isNotEmpty) {
        setState(() => _images.addAll(picks.map((x) => File(x.path))));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Image pick failed: $e')));
    }
  }

  Future<void> _pickVideo() async {
    try {
      final x = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 3),
      );
      if (x != null) setState(() => _video = File(x.path));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Video pick failed: $e')));
    }
  }

  // --- Car Schedule ---
  final Map<String, bool> _days = {
    'Monday': false,
    'Tuesday': false,
    'Wednesday': false,
    'Thursday': false,
    'Friday': false,
    'Saturday': false,
    'Sunday': false,
  };

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  Future<TimeOfDay?> _pickTime(TimeOfDay? initial) async {
    return await showTimePicker(
      context: context,
      initialTime: initial ?? TimeOfDay.now(),
    );
  }

  // --- Pricing (single set only) ---
  final _daily = TextEditingController();
  final _weekly = TextEditingController();
  final _monthly = TextEditingController();
  final _promo = TextEditingController();
  final _discount = TextEditingController();

  // --- Helpers ---
  Widget _sectionTitle(String title, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) Icon(icon, color: Colors.deepOrange),
          if (icon != null) const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _textField(
    String label,
    TextEditingController controller, {
    TextInputType type = TextInputType.text,
    List<TextInputFormatter>? formatters,
    String? hint,
    IconData? icon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      inputFormatters: formatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 12,
        ),
      ),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
    );
  }

  Widget _card({required Widget child}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Add Vehicle'),
        backgroundColor: Color(0xFF0077B6),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 720;
          final gap = const SizedBox(height: 12);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Car Media ---
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Car Media', icon: Icons.perm_media),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _pickImages,
                              icon: const Icon(Icons.image),
                              label: const Text('Add Images'),
                            ),
                            ElevatedButton.icon(
                              onPressed: _pickVideo,
                              icon: const Icon(Icons.videocam),
                              label: const Text('Add Video'),
                            ),
                          ],
                        ),
                        gap,
                        if (_images.isNotEmpty)
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _images.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isWide ? 6 : 3,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                            itemBuilder:
                                (context, i) => Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.file(
                                        _images[i],
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      right: 6,
                                      top: 6,
                                      child: GestureDetector(
                                        onTap:
                                            () => setState(
                                              () => _images.removeAt(i),
                                            ),
                                        child: const CircleAvatar(
                                          radius: 12,
                                          backgroundColor: Colors.black54,
                                          child: Icon(
                                            Icons.close,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                          ),
                        if (_video != null) ...[
                          gap,
                          Container(
                            height: 160,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.black12,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.play_circle_fill,
                                size: 60,
                                color: Colors.black45,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // --- Car Details ---
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle(
                          'Car Details',
                          icon: Icons.directions_car,
                        ),
                        isWide
                            ? Row(
                              children: [
                                Expanded(
                                  child: _textField(
                                    'Year',
                                    _year,
                                    type: TextInputType.number,
                                    formatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    icon: Icons.event,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _textField(
                                    'Type',
                                    _type,
                                    icon: Icons.category,
                                  ),
                                ),
                              ],
                            )
                            : Column(
                              children: [
                                _textField(
                                  'Year',
                                  _year,
                                  type: TextInputType.number,
                                  formatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  icon: Icons.event,
                                ),
                                gap,
                                _textField('Type', _type, icon: Icons.category),
                              ],
                            ),
                        gap,
                        _textField(
                          'Manufacturer',
                          _manufacturer,
                          icon: Icons.factory,
                        ),
                        gap,
                        _textField(
                          'Model',
                          _model,
                          icon: Icons.directions_car_filled,
                        ),
                        gap,
                        _textField(
                          'License Plate',
                          _plate,
                          icon: Icons.confirmation_number,
                        ),
                        gap,
                        isWide
                            ? Row(
                              children: [
                                Expanded(
                                  child: _textField(
                                    'Color',
                                    _color,
                                    icon: Icons.color_lens,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _textField(
                                    'Transmission',
                                    _transmission,
                                    icon: Icons.settings,
                                  ),
                                ),
                              ],
                            )
                            : Column(
                              children: [
                                _textField(
                                  'Color',
                                  _color,
                                  icon: Icons.color_lens,
                                ),
                                gap,
                                _textField(
                                  'Transmission',
                                  _transmission,
                                  icon: Icons.settings,
                                ),
                              ],
                            ),
                        gap,
                        isWide
                            ? Row(
                              children: [
                                Expanded(
                                  child: _textField(
                                    'Fuel Type',
                                    _fuel,
                                    icon: Icons.local_gas_station,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _textField(
                                    'Mileage (km)',
                                    _milage,
                                    type: TextInputType.number,
                                    formatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    icon: Icons.speed,
                                  ),
                                ),
                              ],
                            )
                            : Column(
                              children: [
                                _textField(
                                  'Fuel Type',
                                  _fuel,
                                  icon: Icons.local_gas_station,
                                ),
                                gap,
                                _textField(
                                  'Mileage (km)',
                                  _milage,
                                  type: TextInputType.number,
                                  formatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  icon: Icons.speed,
                                ),
                              ],
                            ),
                        gap,
                        _textField(
                          'Seating Capacity',
                          _seating,
                          type: TextInputType.number,
                          formatters: [FilteringTextInputFormatter.digitsOnly],
                          icon: Icons.event_seat,
                        ),
                        gap,
                        DropdownButtonFormField<String>(
                          value: _status,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Status',
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 12,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'available',
                              child: Text('Available'),
                            ),
                            DropdownMenuItem(
                              value: 'under maintenance',
                              child: Text('Under Maintenance'),
                            ),
                          ],
                          onChanged:
                              (v) => setState(() => _status = v ?? 'available'),
                        ),
                        gap,
                        DropdownButtonFormField<String>(
                          value: _withDriver,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'With Driver',
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 12,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Yes', child: Text('Yes')),
                            DropdownMenuItem(value: 'No', child: Text('No')),
                          ],
                          onChanged:
                              (v) => setState(() => _withDriver = v ?? 'No'),
                        ),
                      ],
                    ),
                  ),

                  // --- Pricing (single set only) ---
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle(
                          'Rental Pricing',
                          icon: Icons.price_change,
                        ),
                        _textField(
                          "Daily Rate (₱)",
                          _daily,
                          type: TextInputType.number,
                          formatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.]'),
                            ),
                          ],
                          icon: Icons.today,
                        ),
                        const SizedBox(height: 12),
                        _textField(
                          "Weekly Rate (₱)",
                          _weekly,
                          type: TextInputType.number,
                          formatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.]'),
                            ),
                          ],
                          icon: Icons.date_range,
                        ),
                        const SizedBox(height: 12),
                        _textField(
                          "Monthly Rate (₱)",
                          _monthly,
                          type: TextInputType.number,
                          formatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.]'),
                            ),
                          ],
                          icon: Icons.calendar_month,
                        ),
                        const SizedBox(height: 12),
                        _textField(
                          "Promo Code",
                          _promo,
                          icon: Icons.local_offer_outlined,
                        ),
                        const SizedBox(height: 12),
                        _textField(
                          "Discount %",
                          _discount,
                          type: TextInputType.number,
                          formatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.]'),
                            ),
                          ],
                          icon: Icons.percent,
                        ),
                      ],
                    ),
                  ),

                  // --- Car Schedule ---
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Car Schedule', icon: Icons.schedule),
                        ..._days.keys.map((day) {
                          return CheckboxListTile(
                            value: _days[day],
                            title: Text(day),
                            onChanged: (val) {
                              setState(() => _days[day] = val ?? false);
                            },
                          );
                        }).toList(),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  final t = await _pickTime(_startTime);
                                  if (t != null) setState(() => _startTime = t);
                                },
                                child: Text(
                                  _startTime == null
                                      ? "Start Time"
                                      : "Start: ${_startTime!.format(context)}",
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  final t = await _pickTime(_endTime);
                                  if (t != null) setState(() => _endTime = t);
                                },
                                child: Text(
                                  _endTime == null
                                      ? "End Time"
                                      : "End: ${_endTime!.format(context)}",
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // --- Submit ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          _submitting
                              ? null
                              : () async {
                                if (!_formKey.currentState!.validate()) return;

                                if (_daily.text.isEmpty &&
                                    _weekly.text.isEmpty &&
                                    _monthly.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please enter at least one rental price.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                setState(() => _submitting = true);

                                final prices = {
                                  "daily": _daily.text.trim(),
                                  "weekly": _weekly.text.trim(),
                                  "monthly": _monthly.text.trim(),
                                  "promo": _promo.text.trim(),
                                  "discount": _discount.text.trim(),
                                };

                                final schedule =
                                    _days.entries
                                        .where((e) => e.value == true)
                                        .map(
                                          (e) => {
                                            "day": e.key,
                                            "start_time":
                                                _startTime?.format(context) ??
                                                "08:00",
                                            "end_time":
                                                _endTime?.format(context) ??
                                                "17:00",
                                          },
                                        )
                                        .toList();

                                final res = await AdminAddCarService.addCar(
                                  year: _year.text.trim(),
                                  manufacturer: _manufacturer.text.trim(),
                                  model: _model.text.trim(),
                                  type: _type.text.trim(),
                                  licensePlate: _plate.text.trim(),
                                  color: _color.text.trim(),
                                  transmission: _transmission.text.trim(),
                                  fuelType: _fuel.text.trim(),
                                  milage: _milage.text.trim(),
                                  seatingCap: _seating.text.trim(),
                                  status: _status,
                                  withDriver: _withDriver,
                                  prices: prices,
                                  schedule: schedule,
                                  adminId: null,
                                  imageFiles: _images,
                                  videoFile: _video,
                                );

                                setState(() => _submitting = false);

                                if (res['success'] == true) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Car added successfully!'),
                                    ),
                                  );
                                  _formKey.currentState!.reset();
                                  setState(() {
                                    _images.clear();
                                    _video = null;
                                    _daily.clear();
                                    _weekly.clear();
                                    _monthly.clear();
                                    _promo.clear();
                                    _discount.clear();
                                    _status = 'available';
                                    _withDriver = 'No';
                                    _days.updateAll((_, __) => false);
                                    _startTime = null;
                                    _endTime = null;
                                  });
                                } else {
                                  final msg =
                                      res['message']?.toString() ??
                                      'Something went wrong';
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed: $msg')),
                                  );
                                }
                              },
                      icon:
                          _submitting
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Icon(Icons.add),
                      label: Text(
                        _submitting ? 'Submitting...' : 'Add Vehicle',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0077B6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _year.dispose();
    _manufacturer.dispose();
    _model.dispose();
    _type.dispose();
    _plate.dispose();
    _color.dispose();
    _transmission.dispose();
    _fuel.dispose();
    _milage.dispose();
    _seating.dispose();
    _daily.dispose();
    _weekly.dispose();
    _monthly.dispose();
    _promo.dispose();
    _discount.dispose();
    super.dispose();
  }
}
