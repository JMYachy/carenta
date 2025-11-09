// lib/feature/manager/dashboard/widget/dashboard_activity_section.dart
import 'package:flutter/material.dart';
import '../model/manager_dashboard_model.dart';

class DashboardActivitySection extends StatelessWidget {
  final DashboardOverview overview;
  const DashboardActivitySection({super.key, required this.overview});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Today\'s Activity',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _miniCard('Bookings Today', overview.rentalsToday, Icons.today,
                Colors.blueAccent),
            _miniCard('Returns (3 days)', overview.returnsNext3,
                Icons.event_available, Colors.teal),
          ],
        ),
      ],
    );
  }

  Widget _miniCard(String title, num value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 6),
              Text(
                '$value',
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(height: 4),
              Text(title, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
