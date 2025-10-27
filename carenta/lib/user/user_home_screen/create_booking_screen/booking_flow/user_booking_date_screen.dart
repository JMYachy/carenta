import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'user_booking_details_screen.dart';

class UserBookingDateScreen extends StatefulWidget {
  final Map<String, dynamic> car;
  const UserBookingDateScreen({super.key, required this.car});

  @override
  State<UserBookingDateScreen> createState() => _UserBookingDateScreenState();
}

class _UserBookingDateScreenState extends State<UserBookingDateScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _pickupTime;
  TimeOfDay? _dropoffTime;

  final _dateFmt = DateFormat('yyyy-MM-dd');

  bool get _readyToProceed =>
      _startDate != null && _endDate != null && _pickupTime != null;

  String _formatTime(TimeOfDay? t) {
    if (t == null) return 'Select';
    final dt = DateTime(0, 1, 1, t.hour, t.minute);
    return DateFormat('hh:mm a').format(dt);
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial =
        isStart ? (_startDate ?? now) : (_endDate ?? _startDate ?? now);
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
    final picked = await showTimePicker(
      context: context,
      initialTime: now,
      helpText:
          isStart ? 'Select pickup time' : 'Select drop-off time (optional)',
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

  @override
  Widget build(BuildContext context) {
    final car = widget.car;
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Dates • ${car['model'] ?? ''}'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0077B6),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DateCard(
            label: 'Start Date',
            value: _startDate == null ? 'Select' : _dateFmt.format(_startDate!),
            icon: Icons.calendar_today,
            onTap: () => _pickDate(isStart: true),
          ),
          const SizedBox(height: 12),
          _DateCard(
            label: 'End Date',
            value: _endDate == null ? 'Select' : _dateFmt.format(_endDate!),
            icon: Icons.event_available,
            onTap: () => _pickDate(isStart: false),
          ),
          const SizedBox(height: 12),
          _DateCard(
            label: 'Pickup Time',
            value: _formatTime(_pickupTime),
            icon: Icons.access_time,
            onTap: () => _pickTime(isStart: true),
          ),
          const SizedBox(height: 12),
          _DateCard(
            label: 'Drop-off Time (optional)',
            value: _formatTime(_dropoffTime),
            icon: Icons.access_time_filled,
            onTap: () => _pickTime(isStart: false),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed:
                _readyToProceed
                    ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => UserBookingDetailsScreen(
                                car: widget.car,
                                startDate: _startDate!,
                                endDate: _endDate!,
                                pickupTime: _pickupTime!,
                                dropoffTime: _dropoffTime,
                              ),
                        ),
                      );
                    }
                    : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5722),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Continue',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _DateCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF0077B6)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
