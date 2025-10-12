import 'package:carenta/admin/home_screen/booking_time_line.dart';
import 'package:carenta/admin/home_screen/car_status_list.dart';
import 'package:carenta/admin/home_screen/kpi_summary.dart';
import 'package:carenta/admin/home_screen/recent_activity_feed.dart';
import 'package:flutter/material.dart';

class AdminHomeScreen extends StatelessWidget {
  final int totalUsers;
  final int totalCars;
  final int totalBookings;
  final double totalRevenue;

  const AdminHomeScreen({
    super.key,
    required this.totalUsers,
    required this.totalCars,
    required this.totalBookings,
    required this.totalRevenue,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monitoring Dashboard',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),

          // ✅ Live KPI Summary
          KpiSummary(
            totalUsers: totalUsers,
            totalCars: totalCars,
            totalBookings: totalBookings,
            totalRevenue: totalRevenue,
          ),
          const SizedBox(height: 24),

          const SectionHeader(title: "Car Status Overview"),
          const CarStatusList(),
          const SizedBox(height: 24),

          const SectionHeader(title: "Today's Bookings Timeline"),
          const BookingTimeline(),
          const SizedBox(height: 24),

          const SectionHeader(title: "Recent Activity"),
          const ActivityFeed(),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    );
  }
}
