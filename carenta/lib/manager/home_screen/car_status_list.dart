import 'package:carenta/service/admin/admin_car_status.dart';
import 'package:flutter/material.dart';

class CarStatusList extends StatefulWidget {
  const CarStatusList({super.key});

  @override
  State<CarStatusList> createState() => _CarStatusListState();
}

class _CarStatusListState extends State<CarStatusList> {
  final CarStatusService _service = CarStatusService();
  Map<String, int>? carStatuses;
  Map<String, int>? rentalStatuses;
  bool _loading = true;
  String? _error;

  final carColors = {
    "Available": Colors.green,
    "Ongoing Rentals": Colors.orange,
    "Under Maintenance": Colors.red,
  };

  final rentalColors = {
    "Pending": Colors.blueGrey,
    "Confirmed": Colors.blue,
    "Ongoing": Colors.orange,
    "Completed": Colors.green,
    "Cancelled": Colors.red,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _service.fetchStatuses();
      setState(() {
        carStatuses = Map<String, int>.from(res["cars"]);
        rentalStatuses = Map<String, int>.from(res["rentals"]);
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Widget _buildStatusList(
    Map<String, int> statuses,
    Map<String, Color> colors,
  ) {
    return Column(
      children:
          statuses.entries.map((entry) {
            final label = entry.key;
            final count = entry.value;
            final color = colors[label] ?? Colors.grey;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  CircleAvatar(backgroundColor: color, radius: 18),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "$count",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Text("Error: $_error");

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "🚗 Car Status",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildStatusList(carStatuses!, carColors),
          const SizedBox(height: 24),
          const Text(
            "📦 Rental Status",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildStatusList(rentalStatuses!, rentalColors),
        ],
      ),
    );
  }
}
