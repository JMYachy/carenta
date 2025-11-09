import 'package:carenta/manager/dashboard/widgets/dashboard_stats_card.dart';
import 'package:flutter/material.dart';
import 'package:carenta/manager/dashboard/service/manager_dashboard_service.dart';

/// ✅ NEW: Standalone Home Overview Screen
/// Handles dashboard data, auto-refresh, and visual layout.
class ManagerHomeScreen extends StatefulWidget {
  const ManagerHomeScreen({super.key});

  @override
  State<ManagerHomeScreen> createState() => ManagerHomeScreenState();
}

class ManagerHomeScreenState extends State<ManagerHomeScreen> {
  late Future<Map<String, dynamic>> _dashboardFuture;
  DateTime? _lastRefresh;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _fetchDashboard();
  }

  /// ✅ NEW: Public refresh method (called by Dashboard shell)
  Future<void> refreshDashboard() async {
    if (_lastRefresh == null ||
        DateTime.now().difference(_lastRefresh!) > const Duration(minutes: 1)) {
      setState(() => _dashboardFuture = _fetchDashboard());
      _lastRefresh = DateTime.now();
    }
  }

  Future<Map<String, dynamic>> _fetchDashboard() async {
    final service = ManagerDashboardService();
    return await service.fetchDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final data = snapshot.data ?? {};
        final overview = data['overview'] ?? {};

        return RefreshIndicator(
          onRefresh: refreshDashboard,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Overview',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  DashboardStatsCard(
                    title: 'Available Cars',
                    value: overview['available_vehicles'] ?? 0,
                    icon: Icons.directions_car,
                    color: Colors.green,
                  ),
                  DashboardStatsCard(
                    title: 'Active Rentals',
                    value: overview['active_bookings'] ?? 0,
                    icon: Icons.book_online,
                    color: Colors.orange,
                  ),
                  DashboardStatsCard(
                    title: 'Pending Verifications',
                    value: overview['pending_verifications'] ?? 0,
                    icon: Icons.verified_user,
                    color: Colors.redAccent,
                  ),
                  DashboardStatsCard(
                    title: 'Pending Tasks',
                    value: overview['pending_tasks'] ?? 0,
                    icon: Icons.pending_actions,
                    color: Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Recent Notifications',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              // ✅ NEW: Placeholder for notifications (to be linked later)
              const Text(
                'No new notifications.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }
}
