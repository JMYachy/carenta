// lib/manager/manager_booking_screen/widget/booking_action_sheet.dart
import 'package:flutter/material.dart';

Future<String?> showPickupRemarkSheet(BuildContext context) {
  return _showRemarkSheet(context, title: 'Record Pickup', hint: 'Optional pickup remark...');
}

Future<String?> showDropoffRemarkSheet(BuildContext context) {
  return _showRemarkSheet(context, title: 'Record Return', hint: 'Optional return remark...');
}

Future<String?> _showRemarkSheet(BuildContext context, {required String title, required String hint}) async {
  final ctrl = TextEditingController();
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      final insets = MediaQuery.of(ctx).viewInsets;
      return Padding(
        padding: EdgeInsets.only(bottom: insets.bottom),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              TextField(
                controller: ctrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: hint,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                      child: const Text('Confirm'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
