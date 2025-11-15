// lib/feature/manager/dashboard/widget/dashboard_overview_grid.dart

import 'package:carenta/manager/dashboard/model/manager_dashboard_model.dart';
import 'package:carenta/manager/screen/manager_booking_screen/manager_booking_screen.dart';
import 'package:carenta/manager/screen/manager_car_screen/manager_car_screen.dart';
import 'package:carenta/manager/screen/manager_verification_screen/manager_user_verification_screen.dart';
import 'package:flutter/material.dart';
import 'dashboard_stats_card.dart';

class DashboardOverviewGrid extends StatelessWidget {
  final DashboardOverview overview;
  const DashboardOverviewGrid({super.key, required this.overview});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // 🚗 Available Cars — navigates to fleet screen
        _tappableCard(
          context,
          DashboardStatsCard(
            title: 'Available Cars',
            value: overview.availableVehicles,
            icon: Icons.directions_car,
            color: Colors.green,
          ),
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => const ManagerCarScreen(filterStatus: 'available'),
                ),
              ),
        ),

        // 📘 Active Rentals — navigates to bookings screen
        _tappableCard(
          context,
          DashboardStatsCard(
            title: 'Active Rentals',
            value: overview.activeBookings,
            icon: Icons.book_online,
            color: Colors.orange,
          ),
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) =>
                          const ManagerBookingScreen(filterStatus: 'ongoing'),
                ),
              ),
        ),

        // 🧾 Pending Verifications — navigates to verification screen
        _tappableCard(
          context,
          DashboardStatsCard(
            title: 'Pending Verifications',
            value: overview.pendingVerifications,
            icon: Icons.verified_user,
            color: Colors.redAccent,
          ),
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ManagerUserVerificationScreen(),
                ),
              ),
        ),

        // 🔧 Maintenance — navigates to fleet list (maintenance filter optional)
        _tappableCard(
          context,
          DashboardStatsCard(
            title: 'Maintenance',
            value: overview.maintenanceVehicles,
            icon: Icons.build,
            color: Colors.grey,
          ),
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) =>
                          const ManagerCarScreen(filterStatus: 'maintenance'),
                ),
              ),
        ),

        // ⚠️ Overdue Rentals — navigates to bookings screen (filtered)
        _tappableCard(
          context,
          DashboardStatsCard(
            title: 'Overdue Rentals',
            value: overview.overdueRentals,
            icon: Icons.warning,
            color: Colors.amber,
          ),
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) =>
                          const ManagerBookingScreen(filterStatus: 'ongoing'),
                ),
              ),
        ),

        // 💰 Earnings Today — display only, not navigable
        DashboardStatsCard(
          title: 'Earnings (Today)',
          value: overview.earningsToday,
          icon: Icons.payments,
          color: Colors.blue,
          isCurrency: true,
        ),
      ],
    );
  }

  /// Helper to make cards tappable with ripple feedback
  Widget _tappableCard(
    BuildContext context,
    Widget child, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      splashColor: Theme.of(context).primaryColor.withOpacity(0.1),
      highlightColor: Colors.transparent,
      child: child,
    );
  }
}
