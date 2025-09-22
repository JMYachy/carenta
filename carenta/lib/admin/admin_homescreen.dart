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
            'Reports Overview',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),

          _buildReportCard(
            Icons.people,
            'Registered Users',
            totalUsers.toString(),
            Colors.blue,
          ),
          _buildReportCard(
            Icons.directions_car,
            'Listed Cars',
            totalCars.toString(),
            Colors.green,
          ),
          _buildReportCard(
            Icons.book_online,
            'Total Bookings',
            totalBookings.toString(),
            Colors.orange,
          ),
          _buildReportCard(
            Icons.attach_money,
            'Total Revenue',
            '₱${totalRevenue.toStringAsFixed(2)}',
            Colors.deepPurple,
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
