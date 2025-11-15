import 'package:flutter/material.dart';

class AccountInfoPanel extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String createdAt;
  final String lastLogin;
  final Future<void> Function(Map<String, String>) onSave;

  const AccountInfoPanel({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.createdAt,
    required this.lastLogin,
    required this.onSave,
  });

  @override
  State<AccountInfoPanel> createState() => _AccountInfoPanelState();
}

class _AccountInfoPanelState extends State<AccountInfoPanel> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fn;
  late final TextEditingController _ln;
  late final TextEditingController _em;
  late final TextEditingController _ph;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fn = TextEditingController(text: widget.firstName);
    _ln = TextEditingController(text: widget.lastName);
    _em = TextEditingController(text: widget.email);
    _ph = TextEditingController(text: widget.phone);
  }

  @override
  void dispose() {
    _fn.dispose();
    _ln.dispose();
    _em.dispose();
    _ph.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await widget.onSave({
      'first_name': _fn.text.trim(),
      'last_name': _ln.text.trim(),
      'email': _em.text.trim(),
      'phone_number': _ph.text.trim(),
    });
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 260,
                child: TextFormField(
                  controller: _fn,
                  decoration: const InputDecoration(labelText: 'First Name'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ),
              SizedBox(
                width: 260,
                child: TextFormField(
                  controller: _ln,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ),
              SizedBox(
                width: 260,
                child: TextFormField(
                  controller: _em,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ),
              SizedBox(
                width: 260,
                child: TextFormField(
                  controller: _ph,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Joined: ${widget.createdAt}',
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ),
              Expanded(
                child: Text(
                  'Last Login: ${widget.lastLogin}',
                  textAlign: TextAlign.end,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _onSave,
                icon:
                    _saving
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.save_outlined, size: 18),
                label: const Text(
                  'Save',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0077B6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
