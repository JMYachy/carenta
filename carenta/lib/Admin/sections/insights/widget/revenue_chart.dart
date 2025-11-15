import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RevenueChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String filter; // daily | weekly | monthly | yearly
  final ValueChanged<String?>? onFilterChanged; // ✅ FIXED TYPE

  const RevenueChart({
    super.key,
    required this.data,
    required this.filter,
    this.onFilterChanged,
  });

  String get _title {
    switch (filter) {
      case 'daily':
        return 'Daily Revenue';
      case 'weekly':
        return 'Weekly Revenue';
      case 'yearly':
        return 'Yearly Revenue';
      default:
        return 'Monthly Revenue';
    }
  }

  @override
  Widget build(BuildContext context) {
    final fm = NumberFormat.compactCurrency(locale: 'en_PH', symbol: '₱');
    final groups = <BarChartGroupData>[];
    final labels = <int, String>{};

    for (int i = 0; i < data.length; i++) {
      final label = data[i]['label']?.toString() ?? '';
      final raw = data[i]['value'];
      final v =
          (raw is num)
              ? raw.toDouble()
              : double.tryParse(raw.toString()) ?? 0.0;

      labels[i] = label;
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: v,
              width: 14,
              borderRadius: BorderRadius.circular(6),
              color: Colors.blueAccent,
            ),
          ],
        ),
      );
    }

    final maxY =
        groups.isNotEmpty
            ? groups
                .map((g) => g.barRods.first.toY)
                .reduce((a, b) => a > b ? a : b)
            : 0;

    return _card(
      title: _title,
      filter: filter,
      onFilterChanged: onFilterChanged,
      child: SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            maxY: (maxY == 0 ? 1 : maxY * 1.1),
            barGroups: groups,
            gridData: FlGridData(
              show: true,
              drawHorizontalLine: true,
              horizontalInterval: (maxY / 4).clamp(
                1,
                double.infinity,
              ), // ✅ prevents NaN
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 48,
                  getTitlesWidget:
                      (v, _) => Text(
                        fm.format(v),
                        style: const TextStyle(fontSize: 10),
                      ),
                  interval: (maxY / 4).clamp(1, double.infinity),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget:
                      (v, _) => Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          labels[v.toInt()] ?? '',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card({
    required String title,
    required Widget child,
    required String filter,
    ValueChanged<String?>? onFilterChanged, // ✅ FIXED TYPE HERE TOO
  }) {
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
          // Header with filter dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: filter,
                  items: const [
                    DropdownMenuItem(value: 'daily', child: Text('Daily')),
                    DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                    DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                    DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                  ],
                  onChanged: onFilterChanged, // ✅ now accepts String?
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
