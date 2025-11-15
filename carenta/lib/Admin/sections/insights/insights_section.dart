import 'package:carenta/Admin/sections/insights/service/admin_insight_service.dart';
import 'package:carenta/Admin/sections/insights/widget/float_donut_chart.dart';
import 'package:carenta/service/config/service_base_url.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'widget/stat_card.dart';
import 'widget/revenue_chart.dart';
import 'widget/rentals_line_chart.dart';

class AdminInsightsScreen extends StatefulWidget {
  const AdminInsightsScreen({super.key});
  @override
  State<AdminInsightsScreen> createState() => _AdminInsightsScreenState();
}

class _AdminInsightsScreenState extends State<AdminInsightsScreen> {
  final _svc = AdminInsightsService();
  bool _loading = true;
  Map<String, dynamic>? _data;
  String? _error;
  String _selectedFilter = 'monthly'; // default filter

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({
    String? start,
    String? end,
    String? location,
    String? filter,
  }) async {
    setState(() => _loading = true);
    try {
      final res = await _svc.fetchInsights(
        start: start,
        end: end,
        location: location,
        filter: filter ?? _selectedFilter,
      );
      if (res['ok'] == true) {
        setState(() {
          _data = Map<String, dynamic>.from(res['data'] ?? {});
          _selectedFilter = res['data']?['filter'] ?? _selectedFilter;
          _error = null;
        });
      } else {
        _error = res['message'] ?? 'Server error';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱',
      decimalDigits: 0,
    );

    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error: $_error', textAlign: TextAlign.center),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    final d = _data!;
    final totalRentals = d['totalRentals'] ?? 0;
    final monthlyRevenue = (d['monthlyRevenue'] ?? 0) as num;
    final activeVehicles = d['activeVehicles'] ?? 0;
    final topManager = d['topManager'] ?? '—';
    final underMaintenance = d['underMaintenance'] ?? 0;
    final growth = d['growth'] ?? 0;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Summary Stat Cards
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                StatCard(
                  icon: Icons.receipt_long,
                  label: 'Total Rentals',
                  value: '$totalRentals',
                  color: Colors.blue,
                ),
                StatCard(
                  icon: Icons.attach_money,
                  label: 'Revenue',
                  value: fmt.format(monthlyRevenue),
                  color: Colors.green,
                ),
                StatCard(
                  icon: Icons.directions_car_filled,
                  label: 'Active Vehicles',
                  value: '$activeVehicles',
                  color: Colors.lightBlue,
                ),
                StatCard(
                  icon: Icons.workspace_premium,
                  label: 'Top Manager',
                  value: topManager,
                  color: Colors.amber,
                ),
                StatCard(
                  icon: Icons.build,
                  label: 'Under Maintenance',
                  value: '$underMaintenance',
                  color: Colors.redAccent,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Revenue chart with filter in top right
            RevenueChart(
              data: List<Map<String, dynamic>>.from(
                d['monthlyRevenueData'] ?? const [],
              ),
              filter: _selectedFilter,
              onFilterChanged: (v) {
                if (v != null) {
                  setState(() => _selectedFilter = v);
                  _load(filter: v);
                }
              },
            ),

            const SizedBox(height: 20),

            // Fleet chart
            FleetDonutChart(
              fleetStatus: Map<String, num>.from(d['fleetStatus'] ?? const {}),
            ),

            const SizedBox(height: 20),

            // Rentals over time
            RentalsLineChart(
              rentals: List<num>.from(d['rentalsOverTime'] ?? const []),
            ),

            const SizedBox(height: 16),

            // Summary Footer with print/export
            _summaryFooter(fmt.format(monthlyRevenue), growth),
          ],
        ),
      ),
    );
  }

  Widget _summaryFooter(String revenueText, num growth) {
    final isUp = (growth is num) && growth >= 0;
    final color = isUp ? Colors.green : Colors.redAccent;
    final sign = isUp ? '+' : '';

    Future<void> _openUrl(String action) async {
      final now = DateTime.now();
      final start = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
      final end =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final url = ServiceBaseUrl.endpoint(
        'admin_insights.php?action=$action&filter=$_selectedFilter&start=$start&end=$end',
      );
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }

    return Column(
      children: [
        Text('$revenueText total', style: const TextStyle(fontSize: 16)),
        Text(
          '$sign${growth.toString()}% growth this period',
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: () => _openUrl('print_revenue'),
                icon: const Icon(Icons.print),
                label: const Text('Print Report'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openUrl('export_csv'),
                icon: const Icon(Icons.file_download),
                label: const Text('Export CSV'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
