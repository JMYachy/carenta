import 'package:flutter/material.dart';

class CarStatusList extends StatelessWidget {
  const CarStatusList({super.key});

  @override
  Widget build(BuildContext context) {
    final statuses = [
      {"label": "Available", "count": 12, "color": Colors.green},
      {"label": "Ongoing Rentals", "count": 5, "color": Colors.orange},
      {"label": "Under Maintenance", "count": 2, "color": Colors.red},
    ];

    return Column(
      children: statuses.map((s) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (s["color"] as Color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: (s["color"] as Color).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: s["color"] as Color, radius: 18),
              const SizedBox(width: 12),
              Text(s["label"] as String, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text("${s["count"]}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
