import 'package:flutter/material.dart';
import 'package:carenta/service/admin/admin_add_manager_service.dart';

class AdminAddManagerScreen extends StatefulWidget {
  const AdminAddManagerScreen({super.key});

  @override
  State<AdminAddManagerScreen> createState() => _AdminAddManagerScreenState();
}

class _AdminAddManagerScreenState extends State<AdminAddManagerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fnameC = TextEditingController();
  final _lnameC = TextEditingController();
  final _emailC = TextEditingController();
  final _phoneC = TextEditingController();
  final _usernameC = TextEditingController();
  final _passwordC = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _fnameC.dispose();
    _lnameC.dispose();
    _emailC.dispose();
    _phoneC.dispose();
    _usernameC.dispose();
    _passwordC.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final res = await AdminAddManagerService.registerManager(
      firstName: _fnameC.text.trim(),
      lastName: _lnameC.text.trim(),
      email: _emailC.text.trim(),
      phone: _phoneC.text.trim(),
      username: _usernameC.text.trim(),
      password: _passwordC.text.trim(),
    );

    setState(() => _loading = false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(res["message"] ?? "No response")));

    if (res["success"] == true) {
      _formKey.currentState?.reset();
      _fnameC.clear();
      _lnameC.clear();
      _emailC.clear();
      _phoneC.clear();
      _usernameC.clear();
      _passwordC.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Manager"),
        backgroundColor: const Color(0xFF0077B6),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 16),
              const Text(
                "Register New Manager",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0077B6),
                ),
              ),
              const SizedBox(height: 24),
              _buildField(_fnameC, "First Name", Icons.person, true),
              _buildField(_lnameC, "Last Name", Icons.person_outline, true),
              _buildField(
                _emailC,
                "Email",
                Icons.email,
                true,
                type: TextInputType.emailAddress,
              ),
              _buildField(
                _phoneC,
                "Phone Number",
                Icons.phone,
                true,
                type: TextInputType.phone,
              ),
              _buildField(_usernameC, "Username", Icons.account_circle, true),
              _buildField(
                _passwordC,
                "Password",
                Icons.lock,
                true,
                obscure: true,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon:
                      _loading
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Icon(Icons.person_add_alt_1),
                  label: Text(_loading ? "Creating..." : "Create Manager"),
                  onPressed: _loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0077B6),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController c,
    String label,
    IconData icon,
    bool required, {
    bool obscure = false,
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: c,
        keyboardType: type,
        obscureText: obscure,
        validator:
            (v) =>
                required && (v == null || v.trim().isEmpty) ? "Required" : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
