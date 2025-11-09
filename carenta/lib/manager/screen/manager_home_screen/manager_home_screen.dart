// lib/feature/manager/dashboard/manager_home_screen.dart
import 'package:carenta/manager/dashboard/model/manager_dashboard_model.dart';
import 'package:carenta/manager/dashboard/service/manager_dashboard_service.dart';
import 'package:carenta/manager/dashboard/widgets/dashboard_activity_section.dart';
import 'package:carenta/manager/dashboard/widgets/dashboard_feedback_preview.dart';
import 'package:carenta/manager/dashboard/widgets/dashboard_messages_preview.dart';
import 'package:carenta/manager/dashboard/widgets/dashboard_overview_grid.dart';
import 'package:carenta/manager/dashboard/widgets/dashboard_top_models_chart.dart';
import 'package:flutter/material.dart';

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

  Future<void> refreshDashboard() async {
    if (_lastRefresh == null ||
        DateTime.now().difference(_lastRefresh!) > const Duration(minutes: 1)) {
      setState(() => _dashboardFuture = _fetchDashboard());
      _lastRefresh = DateTime.now();
    }
  }

  Future<Map<String, dynamic>> _fetchDashboard() async {
    return await ManagerDashboardService().fetchDashboardData();
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

        final data = snapshot.data!;
        final overview = data['overview'] as DashboardOverview;
        final charts = data['charts'] as List<TopModelData>;
        final messages = data['messages'] as List<DashboardMessage>;
        final feedback = data['feedback'] as List<DashboardFeedback>;

        return RefreshIndicator(
          onRefresh: refreshDashboard,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Dashboard Overview',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              DashboardOverviewGrid(overview: overview),
              const SizedBox(height: 24),
              DashboardActivitySection(overview: overview),
              const SizedBox(height: 24),
              DashboardTopModelsChart(data: charts),
              const SizedBox(height: 24),
              DashboardMessagesPreview(messages: messages),
              const SizedBox(height: 24),
              DashboardFeedbackPreview(feedback: feedback),
            ],
          ),
        );
      },
    );
  }
}
