import 'package:flutter/material.dart';

class ManagerHomeScreen extends StatelessWidget {
  final int pendingVerifications;
  final int availableCars;
  final int activeRentals;
  final int bookingsToday;

  const ManagerHomeScreen({
    super.key,
    required this.pendingVerifications,
    required this.availableCars,
    required this.activeRentals,
    required this.bookingsToday,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const Text(
            "Manager Dashboard",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0077B6),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Overview of today’s operations",
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 24),

          // 🧩 Dashboard Stats Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildStatCard(
                context,
                title: "Pending Verifications",
                value: "$pendingVerifications",
                icon: Icons.verified_user,
                color: Colors.orangeAccent,
              ),
              _buildStatCard(
                context,
                title: "Available Cars",
                value: "$availableCars",
                icon: Icons.directions_car,
                color: Colors.lightBlueAccent,
              ),
              _buildStatCard(
                context,
                title: "Active Rentals",
                value: "$activeRentals",
                icon: Icons.assignment,
                color: Colors.greenAccent,
              ),
              _buildStatCard(
                context,
                title: "Bookings Today",
                value: "$bookingsToday",
                icon: Icons.calendar_today,
                color: Colors.purpleAccent,
              ),
            ],
          ),
          const SizedBox(height: 32),

          const Text(
            "Quick Actions",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0077B6),
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _quickActionButton(
                context,
                icon: Icons.verified_user_outlined,
                label: "User Verifications",
                color: Colors.orangeAccent,
                onTap: () {
                  Navigator.pushNamed(context, "/user_verifications");
                },
              ),
              _quickActionButton(
                context,
                icon: Icons.directions_car_filled_outlined,
                label: "Manage Cars",
                color: Colors.lightBlueAccent,
                onTap: () {
                  Navigator.pushNamed(context, "/manage_cars");
                },
              ),
              _quickActionButton(
                context,
                icon: Icons.book_online_outlined,
                label: "View Bookings",
                color: Colors.purpleAccent,
                onTap: () {
                  Navigator.pushNamed(context, "/bookings");
                },
              ),
              _quickActionButton(
                context,
                icon: Icons.analytics_outlined,
                label: "Rental Reports",
                color: Colors.greenAccent,
                onTap: () {
                  Navigator.pushNamed(context, "/reports");
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🧱 Statistic Card Widget
  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ⚡ Quick Action Button Widget
  Widget _quickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 155,
        height: 120,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color.darken(0.3),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🧮 Helper extension to darken colors slightly
extension ColorUtils on Color {
  Color darken([double amount = .1]) {
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
