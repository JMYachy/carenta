import 'package:carenta/Admin/sections/overview/service/admin_overview_service.dart';
import 'package:carenta/Admin/sections/overview/widget/dashboard_stat_card.dart';
import 'package:carenta/Admin/sections/overview/widget/recent_activity_card.dart';
import 'package:carenta/Admin/sections/overview/widget/revenue_chart_section.dart';
import 'package:flutter/material.dart';

class OverviewSection extends StatefulWidget {
  const OverviewSection({super.key});

  @override
  State<OverviewSection> createState() => _OverviewSectionState();
}

class _OverviewSectionState extends State<OverviewSection> {
  final _service = DashboardService();

  bool _loading = true;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _activities = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      final data = await _service.fetchDashboard();
      setState(() {
        _stats = data['stats'];
        _activities = data['activities'];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2196F3);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _fetchData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // STATS GRID
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          DashboardStatCard(
                            icon: Icons.groups,
                            title: 'Active Managers',
                            value: _stats['managers'].toString(),
                            color: primaryBlue,
                          ),
                          DashboardStatCard(
                            icon: Icons.directions_car,
                            title: 'Cars Listed',
                            value: _stats['cars'].toString(),
                            color: Colors.teal,
                          ),
                          DashboardStatCard(
                            icon: Icons.assignment_turned_in,
                            title: 'Active Rentals',
                            value: _stats['rentals'].toString(),
                            color: Colors.orange,
                          ),
                          DashboardStatCard(
                            icon: Icons.people_alt,
                            title: 'Total Users',
                            value: _stats['users'].toString(),
                            color: Colors.deepPurple,
                          ),
                          DashboardStatCard(
                            icon: Icons.payments,
                            title: 'Total Revenue',
                            value: '₱${_stats['revenue']}',
                            color: Colors.green,
                          ),
                          DashboardStatCard(
                            icon: Icons.feedback,
                            title: 'Feedback Pending',
                            value: _stats['feedback'].toString(),
                            color: Colors.redAccent,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Revenue Overview',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const RevenueChartSection(),
                      const SizedBox(height: 24),
                      const Text(
                        'Recent Activity',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._activities.map(
                        (a) => RecentActivityCard(activity: a),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
    );
  }
}
