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
    final r = rental;
    final status = (r['status'] ?? '').toString().toLowerCase();

    // ✅ Status colors
    Color statusColor;
    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'confirmed':
        statusColor = Colors.blue;
        break;
      case 'ongoing':
        statusColor = Colors.green;
        break;
      case 'completed':
        statusColor = Colors.grey;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.black54;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ongoing Rental Monitoring"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Rental ID + Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Rental #${r['rentalid']}",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Chip(
                label: Text(
                  status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 🚗 Live Tracking on top
          _buildSection(
            title: "Live Tracking",
            icon: Icons.map_rounded,
            children: [
              Container(
                height: 180,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text("🚗 GPS tracking will be shown here."),
              ),
            ],
          ),

          _buildSection(
            title: "Car Details",
            icon: Icons.directions_car_filled,
            children: [
              _infoRow(
                "Car",
                r['car_name'] ?? '${r['manufacturer']} ${r['model']}',
              ),
              _infoRow("Plate", r['license_plate'] ?? 'N/A'),
              _infoRow("With Driver", r['withDriver'] ?? 'N/A'),
            ],
          ),

          _buildSection(
            title: "User Info",
            icon: Icons.person,
            children: [
              _infoRow("User ID", r['userid']),
              _infoRow("Rental Type", r['rental_type']),
              _infoRow("Pickup", r['pickup_location']),
              _infoRow("Dropoff", r['dropoff_location']),
            ],
          ),

          _buildSection(
            title: "Schedule",
            icon: Icons.calendar_today,
            children: [
              _infoRow("Start", "${r['start_date']} ${r['start_time']}"),
              _infoRow("End", "${r['end_date']} ${r['end_time']}"),
              if (r['date_range'] != null)
                _infoRow("Duration", r['date_range']),
            ],
          ),

          _buildSection(
            title: "Payment",
            icon: Icons.payments,
            children: [_infoRow("Total Amount", "₱${r['total_amount']}")],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value?.toString() ?? '-',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
