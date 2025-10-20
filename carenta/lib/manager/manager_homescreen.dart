import 'package:flutter/material.dart';

class ManagerHomeScreen extends StatelessWidget {
  final int totalUsers;
  final int totalCars;
  final int totalBookings;

  const ManagerHomeScreen({
    super.key,
    required this.totalUsers,
    required this.totalCars,
    required this.totalBookings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE9F1F7), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text(
              "Manager Dashboard Overview",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0077B6),
              ),
            ),
            const SizedBox(height: 20),

            // Row 1: Users & Cars
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard(
                  title: "Total Users",
                  value: totalUsers.toString(),
                  icon: Icons.people,
                  color: const Color(0xFF1F7895),
                ),
                _buildStatCard(
                  title: "Cars Listed",
                  value: totalCars.toString(),
                  icon: Icons.directions_car,
                  color: const Color(0xFFFF5722),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Row 2: Bookings
            Center(
              child: _buildStatCard(
                title: "Total Bookings",
                value: totalBookings.toString(),
                icon: Icons.book_online,
                color: const Color(0xFF0077B6),
                width: MediaQuery.of(context).size.width * 0.8,
              ),
            ),
            const SizedBox(height: 30),

            const Divider(),
            const SizedBox(height: 10),

            // Tip or Information Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF90E0EF).withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF0077B6)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Keep track of new user verification requests in the 'User Verifications' tab. Review and approve renters promptly to ensure smooth onboarding.",
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    double? width,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: width ?? 150,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.9), color.withOpacity(0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 40),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
