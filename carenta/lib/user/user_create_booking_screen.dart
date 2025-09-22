import 'package:carenta/service/user/user_create_booking_service.dart';
import 'package:carenta/user/user_payment_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserCreateBookingscreen extends StatefulWidget {
  final Map<String, dynamic> car;
  const UserCreateBookingscreen({super.key, required this.car});

  @override
  State<UserCreateBookingscreen> createState() =>
      _UserCreateBookingscreenState();
}

class _UserCreateBookingscreenState extends State<UserCreateBookingscreen> {
  final _formKey = GlobalKey<FormState>();
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  final _bookingService = UserCreateBookingService();

  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _pickupTime;
  TimeOfDay? _dropoffTime;
  bool _loading = false;

  final _priceFmt = NumberFormat('#,##0.##');
  final _dateFmt = DateFormat('yyyy-MM-dd');

  double get _dailyRate {
    final v = widget.car['daily_rate'] ?? widget.car['price'] ?? 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  String get _currencySymbol {
    final c = (widget.car['currency'] ?? 'PHP').toString().toUpperCase();
    switch (c) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'PHP':
      default:
        return '₱';
    }
  }

  int get _rentalDays {
    if (_startDate == null || _endDate == null) return 0;
    final days = _endDate!.difference(_startDate!).inDays + 1;
    return days < 1 ? 0 : days;
  }

  double get _totalAmount => _dailyRate * _rentalDays;

  String _formatTimeOfDay(TimeOfDay t) {
    final dt = DateTime(0, 1, 1, t.hour, t.minute);
    return DateFormat('HH:mm').format(dt);
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial =
        isStart ? (_startDate ?? now) : (_endDate ?? (_startDate ?? now));
    final first = isStart ? now : (_startDate ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : initial,
      firstDate: first,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          _startDate ??= picked;
        }
      });
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final now = TimeOfDay.now();
    final initial = isStart ? (_pickupTime ?? now) : (_dropoffTime ?? now);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: isStart ? 'Select pickup time' : 'Select end time (optional)',
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _pickupTime = picked;
        } else {
          _dropoffTime = picked;
        }
      });
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submitBooking() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null || _endDate == null) {
      _showError('Please select start and end dates');
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      _showError('End date cannot be before start date');
      return;
    }
    if (_rentalDays == 0) {
      _showError('Invalid date range');
      return;
    }
    if (_dailyRate <= 0) {
      _showError('This car has no daily rate set');
      return;
    }
    if (_pickupTime == null) {
      _showError('Please select a pickup time');
      return;
    }

    setState(() => _loading = true);
    try {
      final carId = int.tryParse('${widget.car['carid']}') ?? 0;
      final userId = 1; // TODO: replace with logged-in user ID

      final startDate = _dateFmt.format(_startDate!);
      final endDate = _dateFmt.format(_endDate!);
      final startTime = _formatTimeOfDay(_pickupTime!);
      final endTime =
          _dropoffTime != null ? _formatTimeOfDay(_dropoffTime!) : "00:00";

      final result = await _bookingService.createBooking(
        carId: carId,
        userId: userId,
        startDate: startDate,
        startTime: startTime,
        endDate: endDate,
        endTime: endTime,
        totalAmount: _totalAmount,
        pickupLocation: _pickupController.text.trim(),
        dropoffLocation: _dropoffController.text.trim(),
      );

      if (!mounted) return;

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message.isEmpty ? 'Booking created' : result.message)),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentScreen(
              booking: {
                "car_name": "${widget.car['manufacturer']} ${widget.car['model']}",
                "days": _rentalDays,
                "pickup_location": _pickupController.text.trim(),
                "dropoff_location": _dropoffController.text.trim(),
                "total_amount": _totalAmount,
                "currency": widget.car['currency'] ?? 'PHP',
                "rental_id": result.rentalId,
                "status": result.status ?? 'pending',
              },
            ),
          ),
        );
      } else {
        _showError(result.message.isEmpty ? 'Booking failed' : result.message);
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final manufacturer = (widget.car['manufacturer'] ?? '').toString();
    final model = (widget.car['model'] ?? '').toString();
    final year = (widget.car['year'] ?? '').toString();
    final type = (widget.car['type'] ?? '—').toString();
    final seats = widget.car['seatingcap']?.toString() ??
        widget.car['seats']?.toString() ??
        '—';
    final transmission = (widget.car['transmission'] ?? '—').toString();
    final fuel = (widget.car['fueltype'] ?? '—').toString();
    final imageUrl =
        (widget.car['image_url'] ?? widget.car['media_url'])?.toString();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        title: const Text('Booking'),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -2))],
          ),
          child: Row(
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black87),
                    children: [
                      TextSpan(
                        text: _rentalDays > 0 ? '$_rentalDays day${_rentalDays == 1 ? '' : 's'} • ' : '',
                        style: const TextStyle(fontSize: 12),
                      ),
                      TextSpan(
                        text: _rentalDays > 0
                            ? '$_currencySymbol${_priceFmt.format(_totalAmount)}'
                            : 'Select dates',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      if (_rentalDays > 0)
                        const TextSpan(text: ' total', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _loading ? null : _submitBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5722),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Confirm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: (imageUrl != null && imageUrl.isNotEmpty)
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image, size: 80),
                      ),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Center(child: Icon(Icons.directions_car, size: 80)),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Text('$manufacturer $model${year.isNotEmpty ? ' ($year)' : ''}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pill(icon: Icons.category_rounded, label: type),
              _Pill(icon: Icons.event_seat, label: '$seats seats'),
              _Pill(icon: Icons.settings, label: transmission),
              _Pill(icon: Icons.local_gas_station, label: fuel),
            ],
          ),
          const SizedBox(height: 18),
          _Card(
            child: Row(
              children: [
                _PriceTile(
                  title: 'Daily',
                  price: '$_currencySymbol${_priceFmt.format(_dailyRate)}',
                  highlight: true,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    children: [
                      _PriceRow(label: 'Weekly', value: '—'),
                      SizedBox(height: 8),
                      _PriceRow(label: 'Monthly', value: '—'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          /// ✅ Trip Details full form
          Form(
            key: _formKey,
            child: _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Trip Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _pickupController,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecoration(label: 'Pickup Location', icon: Icons.my_location),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter pickup location' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _dropoffController,
                    textInputAction: TextInputAction.done,
                    decoration: _inputDecoration(label: 'Dropoff Location', icon: Icons.location_on),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter dropoff location' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickDate(isStart: true),
                          borderRadius: BorderRadius.circular(12),
                          child: _dateField(
                            label: 'Start Date',
                            value: _startDate == null ? 'Select' : _dateFmt.format(_startDate!),
                            icon: Icons.event,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickDate(isStart: false),
                          borderRadius: BorderRadius.circular(12),
                          child: _dateField(
                            label: 'End Date',
                            value: _endDate == null ? 'Select' : _dateFmt.format(_endDate!),
                            icon: Icons.event_available,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => _pickTime(isStart: true),
                    borderRadius: BorderRadius.circular(12),
                    child: _dateField(
                      label: 'Pickup Time',
                      value: _pickupTime == null ? 'Select' : _formatTimeOfDay(_pickupTime!),
                      icon: Icons.access_time_filled,
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => _pickTime(isStart: false),
                    borderRadius: BorderRadius.circular(12),
                    child: _dateField(
                      label: 'End Time (optional)',
                      value: _dropoffTime == null ? '—' : _formatTimeOfDay(_dropoffTime!),
                      icon: Icons.schedule,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF90E0EF).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.receipt_long, color: Color(0xFF0077B6)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _rentalDays > 0
                                ? '$_rentalDays day${_rentalDays == 1 ? '' : 's'} × $_currencySymbol${_priceFmt.format(_dailyRate)}'
                                : 'Select dates to see total',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          _rentalDays > 0 ? '$_currencySymbol${_priceFmt.format(_totalAmount)}' : '—',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Icon(icon, color: const Color(0xFF0077B6)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _dateField({required String label, required String value, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0077B6)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const Icon(Icons.keyboard_arrow_down, color: Colors.black45),
        ],
      ),
    );
  }
}

/// --- Inline UI widgets ---
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Pill({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFF5722).withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFF5722).withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFFF5722)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _PriceTile extends StatelessWidget {
  final String title;
  final String price;
  final bool highlight;
  const _PriceTile({required this.title, required this.price, this.highlight = false});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: highlight ? const Color(0xFFFF5722) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: highlight ? const Color(0xFFFF5722) : Colors.black12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: highlight ? Colors.white70 : Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              price,
              style: TextStyle(
                color: highlight ? Colors.white : Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  const _PriceRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
