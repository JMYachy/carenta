import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:carenta/service/user/booking_validation_service.dart';

/// Handles start/end date and time selection, locking unavailable days.
class BookingDateSelection extends StatefulWidget {
  final List<UnavailableRange> blocked;
  final DateTime? startDate;
  final DateTime? endDate;
  final TimeOfDay? pickupTime;
  final TimeOfDay? dropoffTime;
  final Function(DateTime, DateTime) onRangeSelected;
  final Function(bool, TimeOfDay) onSelectTime;

  const BookingDateSelection({
    super.key,
    required this.blocked,
    required this.startDate,
    required this.endDate,
    required this.pickupTime,
    required this.dropoffTime,
    required this.onRangeSelected,
    required this.onSelectTime,
  });

  @override
  State<BookingDateSelection> createState() => _BookingDateSelectionState();
}

class _BookingDateSelectionState extends State<BookingDateSelection> {
  final _dateFmt = DateFormat('yyyy-MM-dd');

  /// Selects start or end date safely, skipping blocked and past days.
  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final now = DateTime.now();

    DateTime normalize(DateTime d) => DateTime(d.year, d.month, d.day);

    bool isBlocked(DateTime d) {
      final date = normalize(d);
      for (final r in widget.blocked) {
        final s = normalize(r.start);
        final e = normalize(r.end);
        if (!date.isBefore(s) && !date.isAfter(e)) return true;
      }
      return false;
    }

    // Build safe initial date
    DateTime initial = isStart
        ? (widget.startDate ?? now)
        : (widget.endDate ?? widget.startDate ?? now);

    final today = normalize(now);
    if (initial.isBefore(today)) initial = today;

    // Shift if blocked
    int tries = 0;
    while (isBlocked(initial) && tries < 180) {
      initial = initial.add(const Duration(days: 1));
      tries++;
    }
    if (tries >= 180) initial = today;

    bool selectableDayPredicate(DateTime day) {
      final d = normalize(day);
      if (d.isBefore(today)) return false;
      return !isBlocked(d);
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: DateTime(now.year + 2),
      selectableDayPredicate: selectableDayPredicate,
      helpText: isStart ? 'Select booking start date' : 'Select booking end date',
      cancelText: 'Cancel',
      confirmText: 'Select',
    );

    if (picked != null) {
      if (isStart) {
        widget.onRangeSelected(picked, widget.endDate ?? picked);
      } else {
        widget.onRangeSelected(widget.startDate ?? picked, picked);
      }
    }
  }

  /// Pick pickup or dropoff time.
  Future<void> _pickTime(BuildContext context, bool isStart) async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: now);
    if (picked != null) widget.onSelectTime(isStart, picked);
  }

  @override
  Widget build(BuildContext context) {
    final fmtTime = DateFormat('HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Select your rental dates",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),

        // 📅 Start + End Date
        Row(
          children: [
            Expanded(
              child: _dateField(
                context,
                label: "Start Date",
                value: widget.startDate == null
                    ? "Select"
                    : _dateFmt.format(widget.startDate!),
                icon: Icons.event,
                onTap: () => _pickDate(context, true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _dateField(
                context,
                label: "End Date",
                value: widget.endDate == null
                    ? "Select"
                    : _dateFmt.format(widget.endDate!),
                icon: Icons.event_available,
                onTap: () => _pickDate(context, false),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ⏰ Pickup / Dropoff Times
        Row(
          children: [
            Expanded(
              child: _timeField(
                context,
                label: "Pickup Time",
                value: widget.pickupTime == null
                    ? "Select"
                    : fmtTime.format(DateTime(
                        0, 0, 0, widget.pickupTime!.hour, widget.pickupTime!.minute)),
                icon: Icons.access_time,
                onTap: () => _pickTime(context, true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _timeField(
                context,
                label: "Dropoff Time",
                value: widget.dropoffTime == null
                    ? "—"
                    : fmtTime.format(DateTime(
                        0, 0, 0, widget.dropoffTime!.hour, widget.dropoffTime!.minute)),
                icon: Icons.schedule,
                onTap: () => _pickTime(context, false),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // 🔒 Unavailable notice
        if (widget.blocked.isNotEmpty)
          Row(
            children: const [
              Icon(Icons.lock_clock, color: Colors.redAccent, size: 18),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  "Dates in confirmed or ongoing rentals are unavailable.",
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _dateField(
    BuildContext ctx, {
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blueAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  Text(value,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.black45),
          ],
        ),
      ),
    );
  }

  Widget _timeField(
    BuildContext ctx, {
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blueAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  Text(value,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.black45),
          ],
        ),
      ),
    );
  }
}
