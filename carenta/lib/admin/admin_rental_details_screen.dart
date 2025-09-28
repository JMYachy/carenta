import 'package:flutter/material.dart';
import 'package:carenta/service/admin/admin_booking_service.dart';

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
  State<AdminRentalDetailsScreen> createState() => _AdminRentalDetailsScreenState();
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
    const baseUrl = "http://10.0.2.2/carenta/"; // 🔧 Change for production
    final mediaUrl = r['media_url'];
    final imageUrl = mediaUrl != null ? "$baseUrl$mediaUrl" : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Booking Details"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
              ),
            ),
          const SizedBox(height: 16),

          // Rental details
          Text("Rental #${r['rentalid']}", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text("Car: ${r['car_name'] ?? '${r['manufacturer']} ${r['model']}'}"),
          Text("Plate: ${r['license_plate'] ?? 'N/A'}"),
          Text("With Driver: ${r['withDriver'] ?? 'N/A'}"),
          const Divider(height: 24),

          Text("User ID: ${r['userid']}"),
          Text("Rental Type: ${r['rental_type']}"),
          Text("Pickup: ${r['pickup_location']}"),
          Text("Dropoff: ${r['dropoff_location']}"),
          const Divider(height: 24),

          Text("Start: ${r['start_date']} ${r['start_time']}"),
          Text("End: ${r['end_date']} ${r['end_time']}"),
          Text("Date Range: ${r['date_range'] ?? ''}"),
          const Divider(height: 24),

          Text("Total Amount: ₱${r['total_amount']}"),
          Text("Status: ${r['status']}"),
          const SizedBox(height: 24),

          // Action buttons
          if (status == 'pending') ...[
            FilledButton.icon(
              onPressed: _busy ? null : _approveRental,
              icon: const Icon(Icons.check_circle),
              label: const Text("Approve"),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _busy ? null : _cancelRental,
              icon: const Icon(Icons.cancel),
              label: const Text("Cancel"),
            ),
          ] else if (status == 'confirmed' || status == 'ongoing') ...[
            FilledButton.icon(
              onPressed: _busy ? null : _cancelRental,
              icon: const Icon(Icons.report_gmailerrorred),
              label: const Text("Cancel due to issue"),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ] else ...[
            Text(
              "This booking is already $status.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

Future<String?> _askReason(BuildContext context) async {
  final ctrl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
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
