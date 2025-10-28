import 'package:flutter/material.dart';

Future<String?> pickCancelReason(BuildContext context) async {
  const reasons = [
    'Change of plans',
    'Wrong schedule',
    'Found a better deal',
    'Other',
  ];
  String selected = reasons.first;
  final controller = TextEditingController();

  return showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Cancel Booking'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: selected,
            items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
            onChanged: (v) => selected = v ?? reasons.first,
            decoration: const InputDecoration(labelText: 'Reason'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Additional notes (optional)',
              hintText: 'Tell us more…',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        FilledButton(
          onPressed: () {
            final r = (selected == 'Other' && controller.text.trim().isNotEmpty)
                ? controller.text.trim()
                : selected;
            Navigator.pop(context, r);
          },
          child: const Text('Confirm Cancel'),
        ),
      ],
    ),
  );
}
