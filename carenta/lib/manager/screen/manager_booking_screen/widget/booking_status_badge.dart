// lib/manager/manager_booking_screen/widget/booking_status_badge.dart
import 'package:flutter/material.dart';

class BookingStatusBadge extends StatelessWidget {
  final String status; // lowercase
  const BookingStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final spec = _style(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: spec.bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        spec.label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: spec.fg),
      ),
    );
  }

  _Spec _style(String s) {
    switch (s) {
      case 'pending':
        return _Spec('Pending', const Color(0xFF8E44AD), const Color(0xFFF0E6F7));
      case 'confirmed':
        return _Spec('Confirmed', const Color(0xFF2C7BE5), const Color(0xFFE7F0FE));
      case 'ongoing':
        return _Spec('Ongoing', const Color(0xFFF59E0B), const Color(0xFFFFF3E0));
      case 'completed':
        return _Spec('Completed', const Color(0xFF10B981), const Color(0xFFE6F7F1));
      case 'cancelled':
      case 'canceled':
        return _Spec('Cancelled', const Color(0xFFE11D48), const Color(0xFFFDE8EC));
      default:
        return _Spec(s.isEmpty ? '—' : s, const Color(0xFF6B7280), const Color(0xFFF3F4F6));
    }
  }
}

class _Spec {
  final String label;
  final Color fg;
  final Color bg;
  _Spec(this.label, this.fg, this.bg);
}
