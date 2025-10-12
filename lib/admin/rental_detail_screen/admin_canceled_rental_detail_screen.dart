// lib/admin/admin_cancelled_rental_detail_screen.dart
import 'package:flutter/material.dart';

class AdminCancelledRentalDetailScreen extends StatelessWidget {
  final Map<String, dynamic> rental;
  final int adminId;

  const AdminCancelledRentalDetailScreen({
    super.key,
    required this.rental,
    required this.adminId,
  });

  @override
  Widget build(BuildContext context) {
    final r = rental;
    final status = (r['status'] ?? '').toString().toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cancelled Rental Details"),
        backgroundColor: Colors.red,
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
                backgroundColor: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 20),

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

          _buildSection(
            title: "Cancellation Info",
            icon: Icons.cancel,
            children: [
              _infoRow(
                "Reason",
                r['cancellation_reason'] ?? "No reason provided",
              ),
              _infoRow("Cancelled By", r['cancelled_by'] ?? "Unknown"),
              _infoRow("Cancelled At", r['updated_at'] ?? "N/A"),
            ],
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
                Icon(icon, color: Colors.red),
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
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
