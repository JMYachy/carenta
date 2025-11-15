import 'package:flutter/material.dart';

class ActivityPanel extends StatelessWidget {
  final int cars;
  final int bookings;
  final int verifications;
  final List<int> dailyCounts; // length 7

  const ActivityPanel({
    super.key,
    required this.cars,
    required this.bookings,
    required this.verifications,
    required this.dailyCounts,
  });

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, int value, Color color, IconData icon) {
      return ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 140, maxWidth: 180),
        child: Container(
          // ↑ Width is limited but elastic; Wrap will move to next line if needed
          height: 96, // a bit taller to avoid tight text layout
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // no Spacer()
            children: [
              Icon(icon, color: color),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$value',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(label, style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive chart height, clamped to avoid vertical overflow
        final double chartH = (constraints.maxWidth * 0.28).clamp(120.0, 180.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ✅ Responsive: no horizontal/vertical overflow
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                chip(
                  'Cars',
                  cars,
                  const Color(0xFF2563EB),
                  Icons.directions_car_filled,
                ),
                chip(
                  'Bookings',
                  bookings,
                  const Color(0xFF10B981),
                  Icons.receipt_long_rounded,
                ),
                chip(
                  'Verifications',
                  verifications,
                  const Color(0xFFF59E0B),
                  Icons.verified_user_rounded,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: chartH,
              child: CustomPaint(painter: _LineChartPainter(dailyCounts)),
            ),
            const SizedBox(height: 6),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Mon'),
                Text('Tue'),
                Text('Wed'),
                Text('Thu'),
                Text('Fri'),
                Text('Sat'),
                Text('Sun'),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<int> values;
  _LineChartPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFEFF4FF);
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(10),
    );
    canvas.drawRRect(rrect, bg);

    if (values.isEmpty) return;

    final maxVal = (values.reduce(
      (a, b) => a > b ? a : b,
    )).toDouble().clamp(1, 9999);
    final dx = size.width / (values.length - 1);
    final path = Path();

    for (int i = 0; i < values.length; i++) {
      final x = i * dx;
      final y = size.height - (values[i] / maxVal) * (size.height - 16) - 8;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final fillPath =
        Path.from(path)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();

    final fillPaint =
        Paint()
          ..color = const Color(0xFF2563EB).withOpacity(.16)
          ..style = PaintingStyle.fill;
    final linePaint =
        Paint()
          ..color = const Color(0xFF2563EB)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.values != values;
}
