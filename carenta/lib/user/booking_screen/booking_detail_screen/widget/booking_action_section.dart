import 'package:flutter/material.dart';

class BookingActionSection extends StatelessWidget {
  final String status;
  final int rentalId;
  final int userId;
  final Function({
    required int rentalId,
    required int userId,
    required bool isRequest,
    required String reason,
  }) onCancel;

  const BookingActionSection({
    super.key,
    required this.status,
    required this.rentalId,
    required this.userId,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isOngoing = status == 'ongoing';
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: isOngoing ? Colors.orange : Colors.red,
            minimumSize: const Size.fromHeight(45),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => _promptReason(context, isOngoing),
          icon: Icon(isOngoing
              ? Icons.report_problem_rounded
              : Icons.cancel_rounded),
          label: Text(isOngoing ? 'Request Cancellation' : 'Cancel Booking'),
        ),
      ),
    );
  }

  Future<void> _promptReason(BuildContext context, bool isRequest) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isRequest ? 'Request Cancellation' : 'Cancel Booking'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
              hintText: 'Enter your reason...', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Submit')),
        ],
      ),
    );
    if (reason != null && reason.isNotEmpty) {
      onCancel(
        rentalId: rentalId,
        userId: userId,
        isRequest: isRequest,
        reason: reason,
      );
    }
  }
}
