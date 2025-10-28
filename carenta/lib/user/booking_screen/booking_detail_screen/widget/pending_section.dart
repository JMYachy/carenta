// lib/user/booking_detail/widgets/pending_section.dart
import 'package:flutter/material.dart';

class PendingSection extends StatelessWidget {
  final Map<String, dynamic> booking;
  const PendingSection({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Booking Pending",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Your booking is awaiting confirmation from the admin or manager.",
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder:
                      (_) => AlertDialog(
                        title: const Text("Cancel Booking"),
                        content: const Text(
                          "Are you sure you want to cancel this booking?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("No"),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Yes"),
                          ),
                        ],
                      ),
                );

                if (confirm == true && context.mounted) {
                  // TODO: Implement cancel booking API call
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Booking cancelled.")),
                  );
                  Navigator.pop(context, true);
                }
              },
              icon: const Icon(Icons.cancel),
              label: const Text("Cancel Booking"),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
