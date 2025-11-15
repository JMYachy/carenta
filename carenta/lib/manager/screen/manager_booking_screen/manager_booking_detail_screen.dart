import 'package:carenta/manager/screen/manager_booking_screen/service/manager_booking_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:carenta/manager/screen/manager_booking_screen/widget/booking_card_container.dart';
import 'package:carenta/manager/screen/manager_booking_screen/widget/booking_status_badge.dart';
import 'package:carenta/service/util_service/session_manager_service.dart';

class ManagerBookingDetailScreen extends StatefulWidget {
  final Map<String, dynamic> booking;

  const ManagerBookingDetailScreen({super.key, required this.booking});

  @override
  State<ManagerBookingDetailScreen> createState() =>
      _ManagerBookingDetailScreenState();
}

class _ManagerBookingDetailScreenState
    extends State<ManagerBookingDetailScreen> {
  final _svc = ManagerBookingService();
  late Map<String, dynamic> _rental;
  int? _managerId;
  bool _loadingManager = true;

  @override
  void initState() {
    super.initState();
    _rental = Map<String, dynamic>.from(widget.booking);
    _loadManagerId();
  }

  /// 🔑 Load the logged-in manager id
  Future<void> _loadManagerId() async {
    final acc = await SessionManagerService.getSession();
    setState(() {
      _managerId = acc?.adminId ?? acc?.userId ?? 0;
      _loadingManager = false;
    });
  }

  String _status() => (_rental['status'] ?? '').toString().toLowerCase();

  dynamic _getValue(String key) {
    final car = _rental['car'] as Map?;
    final user = _rental['user'] as Map?;
    final payment = _rental['payment'] as Map?;
    return _rental[key] ?? car?[key] ?? user?[key] ?? payment?[key] ?? '-';
  }

  String _fmtDate(String? date, String? time) {
    if (date == null || date.isEmpty) return '-';
    final dateTimeStr = '$date ${time ?? '00:00:00'}';
    final dt = DateTime.tryParse(dateTimeStr);
    if (dt == null) return dateTimeStr;
    return DateFormat('MMM d, yyyy • h:mm a').format(dt);
  }

  String _fmtActual(String? raw) {
    if (raw == null || raw.isEmpty || raw == 'null') return '-';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return DateFormat('MMM d, yyyy • h:mm a').format(dt);
  }

  int get _rentalId => int.tryParse('${_rental['rentalid'] ?? 0}') ?? 0;

  Future<void> _apply(Map<String, dynamic> res) async {
    if (!mounted) return;
    final ok = res['ok'] == true;
    final msg = (res['message'] ?? '').toString();
    final newStatus = (res['status'] ?? '').toString();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg.isNotEmpty ? msg : (ok ? 'Success' : 'Failed')),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
    if (ok && newStatus.isNotEmpty) {
      setState(() => _rental['status'] = newStatus);
    }
  }

  // === Booking Actions (with correct managerId) ===
  Future<void> _onAccept() async {
    if ((_managerId ?? 0) == 0) return _showNoManagerAlert();
    final res = await _svc.confirmBooking(
      rentalId: _rentalId,
      managerId: _managerId!,
    );
    await _apply(res);
  }

  Future<void> _onCancel() async {
    if ((_managerId ?? 0) == 0) return _showNoManagerAlert();
    String? reason;
    await showDialog(
      context: context,
      builder: (_) {
        final c = TextEditingController();
        return AlertDialog(
          title: const Text('Cancel booking?'),
          content: TextField(
            controller: c,
            decoration: const InputDecoration(labelText: 'Reason (optional)'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: () {
                reason = c.text.trim();
                Navigator.pop(context);
              },
              child: const Text('Confirm Cancel'),
            ),
          ],
        );
      },
    );

    final res = await _svc.cancelBooking(
      rentalId: _rentalId,
      managerId: _managerId!,
      reason: reason,
    );
    await _apply(res);
  }

  Future<void> _onPickup() async {
    if ((_managerId ?? 0) == 0) return _showNoManagerAlert();
    final res = await _svc.recordPickup(
      rentalId: _rentalId,
      managerId: _managerId!,
    );
    await _apply(res);
  }

  Future<void> _onReturn() async {
    if ((_managerId ?? 0) == 0) return _showNoManagerAlert();
    final res = await _svc.recordDropoff(
      rentalId: _rentalId,
      managerId: _managerId!,
    );
    await _apply(res);
  }

  void _showNoManagerAlert() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Manager not logged in. Please log in again.'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  // === UI helpers ===
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
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value.isNotEmpty ? value : '-',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(String status) {
    Widget buildTwoButtons({
      required VoidCallback onPrimary,
      required IconData primaryIcon,
      required String primaryLabel,
      required VoidCallback onSecondary,
      required IconData secondaryIcon,
      required String secondaryLabel,
    }) {
      return Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: onPrimary,
              icon: Icon(primaryIcon),
              label: Text(primaryLabel, overflow: TextOverflow.ellipsis),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onSecondary,
              icon: Icon(secondaryIcon),
              label: Text(secondaryLabel, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      );
    }

    Widget buildInfoBox(Color color, IconData icon, String text) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                style: TextStyle(fontSize: 13, color: color),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    switch (status) {
      case 'pending':
        return buildTwoButtons(
          onPrimary: _onAccept,
          primaryIcon: Icons.check_circle_outline_rounded,
          primaryLabel: 'Accept Rental',
          onSecondary: _onCancel,
          secondaryIcon: Icons.cancel_outlined,
          secondaryLabel: 'Cancel Rental',
        );

      case 'confirmed':
        return buildTwoButtons(
          onPrimary: _onPickup,
          primaryIcon: Icons.play_circle_outline_rounded,
          primaryLabel: 'Mark as Picked Up',
          onSecondary: _onCancel,
          secondaryIcon: Icons.cancel_outlined,
          secondaryLabel: 'Cancel Rental',
        );

      case 'ongoing':
        return buildTwoButtons(
          onPrimary: _onReturn,
          primaryIcon: Icons.check_circle_outline_rounded,
          primaryLabel: 'Mark as Returned',
          onSecondary: _onCancel,
          secondaryIcon: Icons.cancel_outlined,
          secondaryLabel: 'Cancel Rental',
        );

      case 'completed':
        return buildInfoBox(
          Colors.green,
          Icons.verified_rounded,
          'Booking completed — vehicle moved to maintenance.',
        );

      default:
        return buildInfoBox(
          Colors.grey,
          Icons.lock_clock_rounded,
          'Booking closed — no further actions available.',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF0077B6);
    final status = _status();

    if (_loadingManager) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
                const Text(
                  '📅 Schedule',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const Divider(),
                _infoRow(
                  'Pickup (scheduled)',
                  _fmtDate(_getValue('start_date'), _getValue('start_time')),
                ),
                _infoRow(
                  'Drop-off (scheduled)',
                  _fmtDate(_getValue('end_date'), _getValue('end_time')),
                ),
                _infoRow(
                  'Car picked up (actual)',
                  _fmtActual(_getValue('actual_pickup_time')?.toString()),
                ),
                _infoRow(
                  'Car returned (actual)',
                  _fmtActual(_getValue('actual_dropoff_time')?.toString()),
                ),
                _infoRow(
                  'Pickup location',
                  '${_getValue('pickup_location')}',
                  icon: Icons.pin_drop,
                ),
                _infoRow(
                  'Drop-off location',
                  '${_getValue('dropoff_location')}',
                  icon: Icons.flag,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 🚗 Vehicle
          BookingCardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🚗 Vehicle Information',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const Divider(),
                _infoRow(
                  'Vehicle',
                  '${_getValue('manufacturer')} ${_getValue('model')}',
                ),
                _infoRow('License Plate', '${_getValue('license_plate')}'),
                _infoRow('Fuel Type', '${_getValue('fueltype')}'),
                _infoRow('Transmission', '${_getValue('transmission')}'),
                _infoRow('With Driver', '${_getValue('with_driver')}'),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 👤 Renter
          BookingCardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '👤 Renter Information',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const Divider(),
                _infoRow('Full Name', '${_getValue('fullname')}'),
                _infoRow('Email', '${_getValue('email')}'),
                _infoRow('Contact', '${_getValue('contactno')}'),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 💰 Payment
          BookingCardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '💰 Payment Information',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const Divider(),
                _infoRow('Payment Method', '${_getValue('payment_method')}'),
                _infoRow('Reference No', '${_getValue('reference_no')}'),
                _infoRow('Payment Status', '${_getValue('payment_status')}'),
                _infoRow(
                  'Total Amount',
                  '₱${_getValue('total_amount') ?? _getValue('amount')}',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _buildActions(status),
        ],
      ),
    );
  }
}
