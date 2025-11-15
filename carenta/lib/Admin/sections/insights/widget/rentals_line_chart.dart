import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class RentalsLineChart extends StatelessWidget {
  final List<num> rentals;
  const RentalsLineChart({super.key, required this.rentals});

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    final labels = <int, String>{};
    for (int i = 0; i < rentals.length; i++) {
      spots.add(FlSpot(i.toDouble(), rentals[i].toDouble()));
      labels[i] = 'W${i + 1}';
    }

    return _card(
      title: 'Rentals Over Time',
      child: SizedBox(
        height: 220,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: rentals.isEmpty ? 0 : rentals.length - 1.toDouble(),
            gridData: FlGridData(show: true),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 32),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget:
                      (v, _) => Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          labels[v.toInt()] ?? '',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                barWidth: 3,
                dotData: FlDotData(show: true),
              ),
            ],
          ),
        ),
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
