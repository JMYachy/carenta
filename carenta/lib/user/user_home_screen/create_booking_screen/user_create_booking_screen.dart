// lib/user/create_booking/user_create_booking_screen.dart

import 'package:carenta/user/user_home_screen/create_booking_screen/widgets/booking_date_selection_widget.dart';
import 'package:carenta/user/user_home_screen/create_booking_screen/widgets/booking_footer_summary_widget.dart';
import 'package:carenta/user/user_home_screen/create_booking_screen/widgets/booking_trip_form_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:carenta/main/splash_screen.dart';
import 'package:carenta/service/util_service/session_manager_service.dart';
import 'package:carenta/service/user/booking_validation_service.dart';
import 'package:carenta/user/user_home_screen/booking_payment_screen/booking_payment_screen.dart';
import 'widgets/booking_car_header_widget.dart';


class UserCreateBookingscreen extends StatefulWidget {
  final Map<String, dynamic> car;
  const UserCreateBookingscreen({super.key, required this.car});

  @override
  State<UserCreateBookingscreen> createState() =>
      _UserCreateBookingscreenState();
}

class _UserCreateBookingscreenState extends State<UserCreateBookingscreen> {
  final _formKey = GlobalKey<FormState>();
  final _pickupC = TextEditingController();
  final _dropoffC = TextEditingController();
  final _validationService = BookingValidationService();

  int? _userId;
  bool _checkingSession = true;
  bool _loading = false;

  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _pickupTime;
  TimeOfDay? _dropoffTime;

  List<UnavailableRange> _blocked = [];
  final _dateFmt = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final res = await SessionManagerService.checkSession();
    if (res['success'] == true) {
      _userId = res['data']?['userid'];
      await _loadUnavailable();
      if (mounted) setState(() => _checkingSession = false);
    } else {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SplashScreen()),
        );
      }
    }
  }

  Future<void> _loadUnavailable() async {
    final carId = int.tryParse('${widget.car['carid']}') ?? 0;
    try {
      final result = await _validationService.fetchUnavailableRanges(carId);
      if (!mounted) return;
      setState(() => _blocked = result);
    } catch (e) {
      debugPrint("⚠️ Failed to load unavailable dates: $e");
    }
  }


  double get _dailyRate {
    final v = widget.car['daily_rate'] ?? widget.car['price'] ?? 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  int get _rentalDays {
    if (_startDate == null || _endDate == null) return 0;
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  double get _total => _dailyRate * _rentalDays;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null || _pickupTime == null) {
      _showError('Complete all fields');
      return;
    }

    final carId = int.tryParse('${widget.car['carid']}') ?? 0;
    final available = await _validationService.isRangeAvailable(
      carId,
      _startDate!,
      _endDate!,
    );

    if (!available) {
      _showError('Selected dates are unavailable');
      return;
    }

    // ✅ Navigate to payment screen (do not save yet)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingPaymentScreen(
          booking: {
            "carid": carId,
            "userId": _userId,
            "car_name": "${widget.car['manufacturer']} ${widget.car['model']}",
            "days": _rentalDays,
            "pickup_location": _pickupC.text.trim(),
            "dropoff_location": _dropoffC.text.trim(),
            "total_amount": _total,
            "currency": widget.car['currency'] ?? 'PHP',
            "start_date": _dateFmt.format(_startDate!),
            "end_date": _dateFmt.format(_endDate!),
            "pickup_time": _formatTime(_pickupTime!),
            "dropoff_time":
                _dropoffTime != null ? _formatTime(_dropoffTime!) : '00:00',
          },
        ),
      ),
    );
  }


  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _pickupC.dispose();
    _dropoffC.dispose();
    _validationService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSession) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Booking'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BookingCarHeader(car: widget.car, dailyRate: _dailyRate),
          const SizedBox(height: 16),
          BookingTripForm(formKey: _formKey, pickupC: _pickupC, dropoffC: _dropoffC),
          const SizedBox(height: 16),
          BookingDateSelection(
  blocked: _blocked,
  startDate: _startDate,
  endDate: _endDate,
  pickupTime: _pickupTime,
  dropoffTime: _dropoffTime,
  onRangeSelected: (start, end) {
    setState(() {
      _startDate = start;
      _endDate = end;
    });
  },
  onSelectTime: (isStart, time) {
    setState(() {
      if (isStart) {
        _pickupTime = time;
      } else {
        _dropoffTime = time;
      }
    });
  },
),

        ],
      ),
      bottomNavigationBar: BookingFooterSummary(
        rentalDays: _rentalDays,
        totalAmount: _total,
        currencySymbol: '₱',
        loading: _loading,
        onConfirm: _submit,
      ),
    );
  }
}
