import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:carenta/manager/screen/manager_booking_screen/manager_booking_types.dart';
import 'package:carenta/manager/screen/manager_booking_screen/widget/booking_card_container.dart';
import 'package:carenta/manager/screen/manager_booking_screen/widget/booking_status_badge.dart';

class BookingCard extends StatelessWidget {
  final BookingRow booking;
  final VoidCallback? onTap;

  const BookingCard({
    super.key,
    required this.booking,
    this.onTap,
  });

  String _status(BookingRow r) => (r['status'] ?? '').toString().toLowerCase();

  String _fmt(String? d, String? t) {
    if (d == null || d.isEmpty) return '-';
    final dt = DateTime.tryParse('$d ${t ?? '00:00:00'}');
    return dt == null
        ? '$d ${t ?? ''}'.trim()
        : DateFormat('MMM d, h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final status = _status(booking);
    final title = 'Rental #${booking['rentalid'] ?? booking['id'] ?? '-'}';

    final pickup = _fmt('${booking['start_date']}', '${booking['start_time']}');
    final dropoff = _fmt('${booking['end_date']}', '${booking['end_time']}');
    final sub =
        '${booking['manufacturer'] ?? ''} ${booking['model'] ?? ''}'.trim();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: BookingCardContainer(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: Colors.blueGrey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.directions_car, color: Colors.black54),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      BookingStatusBadge(status: status),
                    ],
                  ),
                  if (sub.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        sub,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.call_received,
                          size: 16, color: Colors.black45),
                      const SizedBox(width: 6),
                      Expanded(child: Text(pickup)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.call_made,
                          size: 16, color: Colors.black45),
                      const SizedBox(width: 6),
                      Expanded(child: Text(dropoff)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
