import 'package:carenta/Admin/sections/overview/service/admin_overview_service.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class RevenueChartSection extends StatefulWidget {
  const RevenueChartSection({super.key});

  @override
  State<RevenueChartSection> createState() => _RevenueChartSectionState();
}

class _RevenueChartSectionState extends State<RevenueChartSection> {
  final _svc = DashboardService();
  bool _loading = true;
  List<Map<String, dynamic>> _points = [];
  String _total = '0.00';
  String _period = 'monthly';

  @override
  void initState() {
    super.initState();
    _loadRevenue();
  }

  Future<void> _loadRevenue() async {
    setState(() => _loading = true);
    try {
      final data = await _svc.fetchRevenue(period: _period);
      setState(() {
        _points = List<Map<String, dynamic>>.from(data['data']);
        _total = data['total'];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load revenue: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2196F3);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Revenue Overview',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              DropdownButton<String>(
                value: _period,
                items: const [
                  DropdownMenuItem(value: 'daily', child: Text('Daily')),
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                  DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _period = v);
                    _loadRevenue();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          _loading
              ? const SizedBox(
                height: 150,
                child: Center(child: CircularProgressIndicator()),
              )
              : SizedBox(
                height: 180,
                child: LineChart(
                  LineChartData(
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          reservedSize: 48,
                          showTitles: true,
                          getTitlesWidget:
                              (value, _) => Text(
                                '₱${value ~/ 1000}k',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, _) {
                            final index = value.toInt();
                            if (index < 0 || index >= _points.length) {
                              return const SizedBox.shrink(); // 🔒 skip invalid indexes
                            }

                            final label = _points[index]['label'].toString();
                            // Trim to show only month/day part if it's a full date
                            final shortLabel =
                                label.length > 7 ? label.substring(5) : label;

                            return Text(
                              shortLabel,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: true,
                        color: primaryBlue,
                        barWidth: 3,
                        dotData: FlDotData(show: false),
                        spots: [
                          for (int i = 0; i < _points.length; i++)
                            FlSpot(i.toDouble(), _points[i]['value'] as double),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Print Revenue Report (to be implemented)'),
                  ),
                );
              },
              icon: const Icon(Icons.print, size: 16),
              label: Text('Total ₱$_total'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryBlue,
                side: const BorderSide(color: primaryBlue),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
