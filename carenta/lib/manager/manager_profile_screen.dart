import 'package:carenta/service/manager/manager_profile_screen_service.dart';
import 'package:flutter/material.dart';
import 'package:carenta/main/splash_screen.dart';
import 'package:carenta/service/util_service/session_manager_service.dart';

class ManagerProfileScreen extends StatefulWidget {
  const ManagerProfileScreen({super.key});

  @override
  State<ManagerProfileScreen> createState() => _ManagerProfileScreenState();
}

class _ManagerProfileScreenState extends State<ManagerProfileScreen> {
  bool _loading = true;
  bool _editing = false;
  bool _saving = false;

  Map<String, dynamic>? _profile;

  final _emailC = TextEditingController();
  final _phoneC = TextEditingController();
  final _usernameC = TextEditingController();
  final _firstC = TextEditingController();
  final _lastC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);

    final session = await SessionManagerService.checkSession();
    if (session["success"] != true || session["data"]?["role"] != "manager") {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SplashScreen()),
        );
      }
      return;
    }

    final managerId = session["data"]["adminid"]; // reuse adminid key for now
    final res = await ManagerProfileService.fetchProfile(managerId);

    if (res["success"] == true) {
      setState(() {
        _profile = res["data"];
        _emailC.text = _profile?["email"] ?? "";
        _phoneC.text = _profile?["phone_number"] ?? "";
        _usernameC.text = _profile?["username"] ?? "";
        _firstC.text = _profile?["first_name"] ?? "";
        _lastC.text = _profile?["last_name"] ?? "";
        _loading = false;
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(res["message"] ?? "Error")));
      setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_saving) return;
    setState(() => _saving = true);

    final res = await ManagerProfileService.updateProfile(
      managerId: _profile?["managerid"],
      email: _emailC.text.trim(),
      phone: _phoneC.text.trim(),
      username: _usernameC.text.trim(),
      firstName: _firstC.text.trim(),
      lastName: _lastC.text.trim(),
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(res["message"] ?? "Update done")));

    if (res["success"] == true) {
      setState(() => _editing = false);
      _loadProfile();
    }

    setState(() => _saving = false);
  }

  Future<void> _logout() async {
    await SessionManagerService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: const Color(0xFF0077B6),
        actions: [
          IconButton(
            icon: Icon(_editing ? Icons.close : Icons.edit),
            onPressed: () => setState(() => _editing = !_editing),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 45,
              backgroundColor: Colors.grey.shade200,
              child: const Icon(Icons.person, size: 50, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _buildField("First Name", _firstC),
            _buildField("Last Name", _lastC),
            _buildField("Username", _usernameC),
            _buildField("Email", _emailC, type: TextInputType.emailAddress),
            _buildField("Phone Number", _phoneC, type: TextInputType.phone),
            const SizedBox(height: 20),
            if (_editing)
              FilledButton.icon(
                icon:
                    _saving
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Icon(Icons.save),
                label: Text(_saving ? "Saving..." : "Save Changes"),
                onPressed: _saving ? null : _saveProfile,
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController c, {
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: c,
        enabled: _editing,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: !_editing,
          fillColor: !_editing ? Colors.grey.shade100 : null,
        ),
      ),
    );
  }
}
