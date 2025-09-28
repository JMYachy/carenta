// lib/admin/admin_ongoing_rental_detail_screen.dart
import 'package:flutter/material.dart';

class AdminOngoingRentalDetailScreen extends StatelessWidget {
  final Map<String, dynamic> rental;
  final int adminId;
  final VoidCallback? onUpdated;

  const AdminOngoingRentalDetailScreen({
    super.key,
    required this.rental,
    required this.adminId,
    this.onUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ongoing Rental Monitoring")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Rental #${rental['rentalid']}",
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text("Car: ${rental['car_name'] ?? '${rental['manufacturer']} ${rental['model']}'}"),
            Text("Plate: ${rental['license_plate'] ?? 'N/A'}"),
            Text("With Driver: ${rental['withDriver'] ?? 'N/A'}"),
            const Divider(height: 24),

            Text("Pickup: ${rental['pickup_location']}"),
            Text("Dropoff: ${rental['dropoff_location']}"),
            Text("Duration: ${rental['date_range']}"),
            const Divider(height: 24),

            Text("Status: ${rental['status']}"),
            const SizedBox(height: 16),

            // 🔮 Future feature: live GPS tracking map
            Expanded(
              child: Center(
                child: Text(
                  "🚗 GPS tracking will be shown here.",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
