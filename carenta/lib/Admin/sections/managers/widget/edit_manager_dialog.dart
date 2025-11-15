import 'package:flutter/material.dart';

class EditManagerDialog extends StatefulWidget {
  final Map<String, dynamic> manager; // minimal payload

  const EditManagerDialog({super.key, required this.manager});

  @override
  State<EditManagerDialog> createState() => _EditManagerDialogState();
}

class _EditManagerDialogState extends State<EditManagerDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _username;
  late final TextEditingController _email;
  late final TextEditingController _first;
  late final TextEditingController _last;
  late final TextEditingController _phone;
  final _password = TextEditingController(); // optional

  @override
  void initState() {
    super.initState();
    final m = widget.manager;
    _username = TextEditingController(text: m['username'] ?? '');
    _email = TextEditingController(text: m['email'] ?? '');
    _first = TextEditingController(text: m['first_name'] ?? '');
    _last = TextEditingController(text: m['last_name'] ?? '');
    _phone = TextEditingController(text: m['phone_number'] ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Manager'),
      content: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                controller: _username,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final r = RegExp(r'^\S+@\S+\.\S+$');
                  return r.hasMatch(v) ? null : 'Invalid email';
                },
              ),
              TextFormField(
                controller: _first,
                decoration: const InputDecoration(labelText: 'First name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _last,
                decoration: const InputDecoration(labelText: 'Last name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(
                  labelText: 'Phone (optional)',
                ),
              ),
              TextFormField(
                controller: _password,
                decoration: const InputDecoration(
                  labelText: 'New password (optional)',
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (!_form.currentState!.validate()) return;
            Navigator.pop(context, {
              'username': _username.text.trim(),
              'email': _email.text.trim(),
              'first_name': _first.text.trim(),
              'last_name': _last.text.trim(),
              'phone_number':
                  _phone.text.trim().isEmpty ? null : _phone.text.trim(),
              if (_password.text.isNotEmpty) 'password': _password.text,
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
