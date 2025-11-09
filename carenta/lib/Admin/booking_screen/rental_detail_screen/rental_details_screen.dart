/*import 'package:carenta/widget/rental_detail_widget/safe_car_image.dart';
import 'package:flutter/material.dart';
import 'package:carenta/manager/screen/manager_booking_screen/service/manager_booking_service.dart';

class AdminRentalDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> rental;
  final int adminId;
  final VoidCallback? onCancelled;

  const AdminRentalDetailsScreen({
    super.key,
    required this.rental,
    required this.adminId,
    this.onCancelled,
  });

  @override
  State<AdminRentalDetailsScreen> createState() =>
      _AdminRentalDetailsScreenState();
}

class _AdminRentalDetailsScreenState extends State<AdminRentalDetailsScreen> {
  final _svc = AdminBookingService();
  bool _busy = false;

  Future<void> _approveRental() async {
    setState(() => _busy = true);
    final res = await _svc.approveBooking(
      rentalId: widget.rental['rentalid'],
      adminId: widget.adminId,
    );
    if (!mounted) return;
    setState(() => _busy = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res['message'] ?? 'Booking approved')),
    );

    widget.onCancelled?.call();
    Navigator.pop(context);
  }

  Future<void> _cancelRental() async {
    final reason = await _askReason(context);
    if (reason == null) return;

    setState(() => _busy = true);
    final res = await _svc.cancelBooking(
      rentalId: widget.rental['rentalid'],
      adminId: widget.adminId,
      reason: reason,
    );
    if (!mounted) return;
    setState(() => _busy = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res['message'] ?? 'Booking cancelled')),
    );

    widget.onCancelled?.call();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.rental;
    final status = (r['status'] ?? '').toString().toLowerCase();
    const baseUrl = "http://10.0.2.2/carenta/"; // update in production
    final mediaUrl = r['media_url'];
    final imageUrl = mediaUrl != null ? "$baseUrl$mediaUrl" : null;

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
        title: const Text("Booking Details"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: _buildActions(status),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SafeCarImage(imageUrl: imageUrl),
          const SizedBox(height: 20),

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
              if (r['date_range'] != null) _infoRow("Range", r['date_range']),
            ],
          ),
          _buildSection(
            title: "Payment",
            icon: Icons.payments,
            children: [_infoRow("Total Amount", "₱${r['total_amount']}")],
          ),

          if (status == 'cancelled')
            _buildSection(
              title: "Cancellation Info",
              icon: Icons.cancel,
              children: [
                _infoRow(
                  "Reason",
                  r['cancellation_reason'] ?? "No reason provided",
                ),
                _infoRow("Cancelled By", r['cancelled_by'] ?? "N/A"),
                _infoRow("Cancelled At", r['cancelled_at'] ?? "N/A"),
                if (r['admin_notes'] != null &&
                    (r['admin_notes'] as String).isNotEmpty)
                  _infoRow("Admin Notes", r['admin_notes']),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildActions(String status) {
    if (status == 'pending') {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _cancelRental,
                icon: const Icon(Icons.cancel),
                label: const Text("Cancel"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _busy ? null : _approveRental,
                icon: const Icon(Icons.check_circle),
                label: const Text("Approve"),
              ),
            ),
          ],
        ),
      );
    } else if (status == 'confirmed' || status == 'ongoing') {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: FilledButton.icon(
          onPressed: _busy ? null : _cancelRental,
          icon: const Icon(Icons.report_problem),
          label: const Text("Cancel due to issue"),
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
        ),
      );
    }
    // For completed/cancelled, no actions
    return const SizedBox.shrink();
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
                Icon(icon, color: Theme.of(context).colorScheme.primary),
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

Future<String?> _askReason(BuildContext context) async {
  final ctrl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder:
        (ctx) => AlertDialog(
          title: const Text("Cancel booking"),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: "Reason",
              hintText: "e.g., car breakdown, maintenance, policy issue",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Close"),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text("Submit"),
            ),
          ],
        ),
  );
}
*/