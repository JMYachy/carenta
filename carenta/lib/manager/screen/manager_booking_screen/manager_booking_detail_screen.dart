import 'package:carenta/manager/screen/manager_booking_screen/service/manager_booking_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:carenta/manager/screen/manager_booking_screen/manager_booking_types.dart';
import 'package:carenta/manager/screen/manager_booking_screen/widget/booking_card_container.dart';
import 'package:carenta/manager/screen/manager_booking_screen/widget/booking_status_badge.dart';

class ManagerBookingDetailScreen extends StatefulWidget {
  final BookingRow booking;
  final int managerId;

  const ManagerBookingDetailScreen({
    super.key,
    required this.booking,
    this.managerId = 1,
  });

  @override
  State<ManagerBookingDetailScreen> createState() =>
      _ManagerBookingDetailScreenState();
}

class _ManagerBookingDetailScreenState
    extends State<ManagerBookingDetailScreen> {
  final _svc = ManagerBookingService();
  late BookingRow _rental;

  @override
  void initState() {
    super.initState();
    _rental = Map<String, dynamic>.from(widget.booking);
  }

  String _status() => (_rental['status'] ?? '').toString().toLowerCase();

  // ✅ Handles both top-level and nested JSON structures (car, user, payment)
  dynamic _getValue(String key) {
    final car = _rental['car'] as Map?;
    final user = _rental['user'] as Map?;
    final payment = _rental['payment'] as Map?;

    return _rental[key] ??
        car?[key] ??
        user?[key] ??
        payment?[key] ??
        '-';
  }

  String _fmtDate(String? date, String? time) {
    if (date == null || date.isEmpty) return '-';
    final dt = DateTime.tryParse('$date ${time ?? '00:00:00'}');
    if (dt == null) return '$date ${time ?? ''}';
    return DateFormat('MMM d, yyyy • h:mm a').format(dt);
  }

  Widget _infoRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(top: 2.0, right: 8),
              child: Icon(icon, size: 18, color: Colors.black54),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500)),
                Text(value.isNotEmpty ? value : '-',
                    style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _recordPickup() async {
    final id = int.tryParse('${_rental['rentalid'] ?? 0}') ?? 0;
    if (id == 0) return;

    final res = await _svc.recordPickup(
      rentalId: id,
      managerId: widget.managerId,
    );
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res['message'] ?? 'Pickup recorded.'),
        backgroundColor: res['ok'] == true ? Colors.green : Colors.red,
      ),
    );

    if (res['ok'] == true || res['status'] == 'success') {
      setState(() => _rental['status'] = 'ongoing');
    }
  }

  Future<void> _recordDropoff() async {
    final id = int.tryParse('${_rental['rentalid'] ?? 0}') ?? 0;
    if (id == 0) return;

    final res = await _svc.recordDropoff(
      rentalId: id,
      managerId: widget.managerId,
    );
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res['message'] ?? 'Drop-off recorded.'),
        backgroundColor: res['ok'] == true ? Colors.green : Colors.red,
      ),
    );

    if (res['ok'] == true || res['status'] == 'success') {
      setState(() => _rental['status'] = 'completed');
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF0077B6);
    final status = _status();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        title: const Text('Booking Details'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          // 🧩 Overview Card
          BookingCardContainer(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rental #${_rental['rentalid'] ?? '-'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                BookingStatusBadge(status: status),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 📅 Schedule
          BookingCardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📅 Schedule',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const Divider(),
                _infoRow('Pickup (scheduled)',
                    _fmtDate(_getValue('start_date'), _getValue('start_time'))),
                _infoRow('Drop-off (scheduled)',
                    _fmtDate(_getValue('end_date'), _getValue('end_time'))),
                _infoRow('Pickup (actual)',
                    _fmtDate(_getValue('actual_pickup_date'), _getValue('actual_pickup_time'))),
                _infoRow('Drop-off (actual)',
                    _fmtDate(_getValue('actual_dropoff_date'), _getValue('actual_dropoff_time'))),
                _infoRow('Pickup location',
                    '${_getValue('pickup_location')}', icon: Icons.pin_drop_rounded),
                _infoRow('Drop-off location',
                    '${_getValue('dropoff_location')}', icon: Icons.flag_rounded),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 🚗 Vehicle Info
          BookingCardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🚗 Vehicle Information',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const Divider(),
                _infoRow('Vehicle',
                    '${_getValue('manufacturer')} ${_getValue('model')}'),
                _infoRow('License Plate', '${_getValue('license_plate')}'),
                _infoRow('Type', '${_getValue('car_type')}'),
                _infoRow('Fuel Type', '${_getValue('fueltype')}'),
                _infoRow('Transmission', '${_getValue('transmission')}'),
                _infoRow('With Driver', '${_getValue('with_driver')}'),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 👤 Renter Info
          BookingCardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('👤 Renter Information',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const Divider(),
                _infoRow('Full Name', '${_getValue('fullname')}'),
                _infoRow('Email', '${_getValue('email')}'),
                _infoRow('Contact', '${_getValue('contactno')}'),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 💰 Payment Details
          BookingCardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💰 Payment Information',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const Divider(),
                _infoRow('Payment Method', '${_getValue('payment_method')}'),
                _infoRow('Reference No', '${_getValue('reference_no')}'),
                _infoRow('Payment Status', '${_getValue('payment_status')}'),
                _infoRow('Total Amount',
                    '₱${_getValue('total_amount') ?? _getValue('amount')}'),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 🧾 Notes
          if ((_getValue('admin_notes') ?? '').toString().isNotEmpty)
            BookingCardContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🧾 System Notes',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  const Divider(),
                  Text(
                    '${_getValue('admin_notes')}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // 🚀 Action Buttons
          if (status == 'confirmed')
            FilledButton.icon(
              onPressed: _recordPickup,
              icon: const Icon(Icons.play_circle_outline_rounded),
              label: const Text('Mark as Picked Up'),
            )
          else if (status == 'ongoing')
            FilledButton.icon(
              onPressed: _recordDropoff,
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('Mark as Returned'),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  'Booking closed — no further actions available.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
