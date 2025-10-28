import 'package:flutter/material.dart';

Future<String?> getMessageDialog(
  BuildContext context, {
  required String title,
  required String hint,
}) async {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        maxLines: 4,
        decoration: InputDecoration(
          labelText: 'Message',
          hintText: hint,
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('Send'),
        ),
      ],
    ),
  );
}
