import 'package:carenta/service/admin/admin_edit_car_service.dart';
import 'package:carenta/service/admin/admin_get_car_detail_service.dart';
import 'package:flutter/material.dart';
import 'package:carenta/widget/admin_widget/car_model.dart';

class CarInfoSection extends StatefulWidget {
  CarModel car;
  final void Function(CarModel updated)? onCarUpdated; // ✅ notify parent (CarDetailScreen)

  CarInfoSection({
    super.key,
    required this.car,
    this.onCarUpdated,
  });

  @override
  State<CarInfoSection> createState() => _CarInfoSectionState();
}

class _CarInfoSectionState extends State<CarInfoSection> {
  bool _editing = false;
  bool _loading = false; // ✅ loading state for save

  // Controllers
  late TextEditingController _yearCtrl;
  late TextEditingController _manufacturerCtrl;
  late TextEditingController _modelCtrl;
  late TextEditingController _typeCtrl;
  late TextEditingController _licenseCtrl;
  late TextEditingController _colorCtrl;
  late TextEditingController _transmissionCtrl;
  late TextEditingController _fuelTypeCtrl;
  late TextEditingController _milageCtrl;
  late TextEditingController _seatingCtrl;
  late TextEditingController _withDriverCtrl;
  late TextEditingController _dailyRateCtrl;
  late TextEditingController _weeklyRateCtrl;
  late TextEditingController _monthlyRateCtrl;
  late TextEditingController _promoCodeCtrl;
  late TextEditingController _discountCtrl;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final car = widget.car;
    _yearCtrl = TextEditingController(text: car.year);
    _manufacturerCtrl = TextEditingController(text: car.manufacturer);
    _modelCtrl = TextEditingController(text: car.model);
    _typeCtrl = TextEditingController(text: car.type);
    _licenseCtrl = TextEditingController(text: car.licensePlate ?? '');
    _colorCtrl = TextEditingController(text: car.color);
    _transmissionCtrl = TextEditingController(text: car.transmission);
    _fuelTypeCtrl = TextEditingController(text: car.fuelType);
    _milageCtrl = TextEditingController(text: car.milage ?? '');
    _seatingCtrl = TextEditingController(text: car.seatingCap ?? '');
    _withDriverCtrl = TextEditingController(text: car.withDriver);
    _dailyRateCtrl = TextEditingController(text: car.dailyRate?.toString() ?? '');
    _weeklyRateCtrl = TextEditingController(text: car.weeklyRate?.toString() ?? '');
    _monthlyRateCtrl = TextEditingController(text: car.monthlyRate?.toString() ?? '');
    _promoCodeCtrl = TextEditingController(text: car.promoCode ?? '');
    _discountCtrl = TextEditingController(text: car.discountPercent?.toString() ?? '');
  }

  Future<void> _saveChanges() async {
    setState(() => _loading = true);

    final carResponse = await AdminEditCarService.updateCarDetails(
      carId: widget.car.carId,
      fields: {
        'year': _yearCtrl.text.trim(),
        'manufacturer': _manufacturerCtrl.text.trim(),
        'model': _modelCtrl.text.trim(),
        'type': _typeCtrl.text.trim(),
        'license_plate': _licenseCtrl.text.trim(),
        'color': _colorCtrl.text.trim(),
        'transmission': _transmissionCtrl.text.trim(),
        'fueltype': _fuelTypeCtrl.text.trim(),
        'milage': _milageCtrl.text.trim(),
        'seatingcap': _seatingCtrl.text.trim(),
        'withDriver': _withDriverCtrl.text.trim(),
      },
    );

    final priceResponse = await AdminEditCarService.updateCarDetails(
      carId: widget.car.carId,
      fields: {
        'daily_rate': _dailyRateCtrl.text.trim(),
        'weekly_rate': _weeklyRateCtrl.text.trim(),
        'monthly_rate': _monthlyRateCtrl.text.trim(),
        'promo_code': _promoCodeCtrl.text.trim(),
        'discount_percent': _discountCtrl.text.trim(),
      },
    );

    if (carResponse['success'] == true || priceResponse['success'] == true) {
      // ✅ Fetch updated record from backend for true sync
      final refreshedCar =
          await AdminGetCarDetailsService.fetchCarById(widget.car.carId);

      if (refreshedCar != null) {
        setState(() {
          widget.car = refreshedCar;
          _editing = false;
          _loading = false;
        });

        // ✅ notify parent (CarDetailScreen)
        if (widget.onCarUpdated != null) {
          widget.onCarUpdated!(refreshedCar);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Car info updated and synced ✅')),
      );
    } else {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(carResponse['message'] ??
              priceResponse['message'] ??
              'Update failed'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Car Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              _loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: Icon(
                        _editing ? Icons.check : Icons.edit,
                        color: _editing ? Colors.green : Colors.blue,
                      ),
                      onPressed: () =>
                          _editing ? _saveChanges() : setState(() => _editing = true),
                    ),
            ],
          ),
          const SizedBox(height: 8),
          _editing ? _buildEditableFields() : _buildStaticInfo(),
        ]),
      ),
    );
  }

  /// --- Static (View) Mode ---
  Widget _buildStaticInfo() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _infoRow('Year', widget.car.year),
      _infoRow('Manufacturer', widget.car.manufacturer),
      _infoRow('Model', widget.car.model),
      _infoRow('Type', widget.car.type),
      _infoRow('License Plate', widget.car.licensePlate ?? 'N/A'),
      _infoRow('Color', widget.car.color),
      _infoRow('Transmission', widget.car.transmission),
      _infoRow('Fuel Type', widget.car.fuelType),
      _infoRow('Mileage', '${widget.car.milage ?? '0'} km'),
      _infoRow('Seating Capacity', widget.car.seatingCap ?? 'N/A'),
      _infoRow('With Driver', widget.car.withDriver),
      const Divider(height: 30),
      const Text(
        'Pricing Information',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      _infoRow('Daily Rate', '₱${widget.car.dailyRate ?? 0}'),
      _infoRow('Weekly Rate', '₱${widget.car.weeklyRate ?? 0}'),
      _infoRow('Monthly Rate', '₱${widget.car.monthlyRate ?? 0}'),
      if (widget.car.promoCode != null && widget.car.promoCode!.isNotEmpty)
        _infoRow(
          'Promo Code',
          '${widget.car.promoCode} (${widget.car.discountPercent ?? 0}% OFF)',
        ),
    ]);
  }

  /// --- Editable Mode ---
  Widget _buildEditableFields() {
    return Column(children: [
      _editableField('Year', _yearCtrl),
      _editableField('Manufacturer', _manufacturerCtrl),
      _editableField('Model', _modelCtrl),
      _editableField('Type', _typeCtrl),
      _editableField('License Plate', _licenseCtrl),
      _editableField('Color', _colorCtrl),
      _editableField('Transmission', _transmissionCtrl),
      _editableField('Fuel Type', _fuelTypeCtrl),
      _editableField('Mileage (km)', _milageCtrl,
          keyboard: TextInputType.number),
      _editableField('Seating Capacity', _seatingCtrl,
          keyboard: TextInputType.number),
      _editableField('With Driver (Yes/No)', _withDriverCtrl),
      const Divider(height: 30),
      const Text('Pricing Information',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      _editableField('Daily Rate (₱)', _dailyRateCtrl,
          keyboard: TextInputType.number),
      _editableField('Weekly Rate (₱)', _weeklyRateCtrl,
          keyboard: TextInputType.number),
      _editableField('Monthly Rate (₱)', _monthlyRateCtrl,
          keyboard: TextInputType.number),
      _editableField('Promo Code', _promoCodeCtrl),
      _editableField('Discount (%)', _discountCtrl,
          keyboard: TextInputType.number),
    ]);
  }

  Widget _editableField(String label, TextEditingController controller,
      {TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(color: Colors.black54, fontSize: 14)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style:
                    const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
