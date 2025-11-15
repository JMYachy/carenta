import 'package:flutter/material.dart';

class AddManagerButton extends StatelessWidget {
  const AddManagerButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        // TODO: open add manager dialog
      },
      icon: const Icon(Icons.person_add_alt_1),
      label: const Text('Add Manager'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
