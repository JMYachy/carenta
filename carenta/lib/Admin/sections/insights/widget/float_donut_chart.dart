import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class FleetDonutChart extends StatelessWidget {
  /// Expecting keys: available, rented, maintenance, unavailable|disabled
  final Map<String, num> fleetStatus;
  const FleetDonutChart({super.key, required this.fleetStatus});

  @override
  Widget build(BuildContext context) {
    final avail = (fleetStatus['available'] ?? 0).toDouble();
    final rented = (fleetStatus['rented'] ?? 0).toDouble();
    final maint = (fleetStatus['maintenance'] ?? 0).toDouble();
    // accept either `unavailable` or legacy `disabled`
    final unavail =
        (fleetStatus['unavailable'] ?? fleetStatus['disabled'] ?? 0).toDouble();

    final total = (avail + rented + maint + unavail).clamp(
      1.0,
      double.infinity,
    );

    final sections = <PieChartSectionData>[
      PieChartSectionData(
        value: avail,
        title: '',
        radius: 54,
        color: Colors.green.shade500, // ✅ Available
      ),
      PieChartSectionData(
        value: rented,
        title: '',
        radius: 54,
        color: Colors.blue.shade500, // ✅ Rented
      ),
      PieChartSectionData(
        value: maint,
        title: '',
        radius: 54,
        color: Colors.orange.shade400, // ✅ Maintenance
      ),
      PieChartSectionData(
        value: unavail,
        title: '',
        radius: 54,
        color: Colors.red.shade400, // ✅ Unavailable
      ),
    ];

    Widget legendDot(Color c, String t) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(t),
      ],
    );

    return _card(
      title: 'Fleet Status',
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 48,
                    sections: sections,
                    startDegreeOffset: -90,
                    borderData: FlBorderData(show: false),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      (total.isFinite ? total.toInt() : 0).toString(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('Total'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              legendDot(Colors.green.shade500, 'Available (${avail.toInt()})'),
              legendDot(Colors.blue.shade500, 'Rented (${rented.toInt()})'),
              legendDot(
                Colors.orange.shade400,
                'Maintenance (${maint.toInt()})',
              ),
              legendDot(
                Colors.red.shade400,
                'Unavailable (${unavail.toInt()})',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
