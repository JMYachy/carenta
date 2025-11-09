import 'package:flutter/material.dart';
import '../model/manager_dashboard_model.dart';

class DashboardTopModelsChart extends StatelessWidget {
  final List<TopModelData> data;
  const DashboardTopModelsChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Top Rented Models (This Month)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            if (data.isEmpty)
              const Text('No data available',
                  style: TextStyle(color: Colors.grey))
            else
              Column(
                children: data
                    .map((m) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(m.model),
                              Text('${m.count} rentals'),
                            ],
                          ),
                        ))
                    .toList(),
              )
          ],
        ),
      ),
    );
  }
}
