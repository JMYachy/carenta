import 'package:carenta/service/user/user_profile_service.dart';
import 'package:carenta/user/profile_screen/user_vertification_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProfileEditTab extends StatefulWidget {
  final VoidCallback onBack;
  final int? userId;
  const ProfileEditTab({super.key, required this.onBack, this.userId});

  @override
  State<ProfileEditTab> createState() => _ProfileEditTabState();
}

class _ProfileEditTabState extends State<ProfileEditTab> {
  final _svc = UserProfileService();

  bool _loading = true;
  bool _showPasswordSection = false;
  Map<String, dynamic>? _profile;

  // controllers
  final _firstC = TextEditingController();
  final _lastC = TextEditingController();
  final _emailC = TextEditingController();
  final _phoneC = TextEditingController();
  final _addressC = TextEditingController();
  final _cityC = TextEditingController();

  final _currentPwC = TextEditingController();
  final _newPwC = TextEditingController();
  final _confirmPwC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    if (widget.userId == null) return;
    try {
      final res = await _svc.fetchProfile(widget.userId!);
      if (res['status'] == 'success' && res['data'] != null) {
        final data = Map<String, dynamic>.from(res['data'] as Map);
        setState(() {
          _profile = data;
          _firstC.text = data['first_name'] ?? '';
          _lastC.text = data['last_name'] ?? '';
          _emailC.text = data['email'] ?? '';
          _phoneC.text = data['phone_number'] ?? '';
          _addressC.text = data['street_address'] ?? '';
          _cityC.text = data['city'] ?? '';
          _loading = false;
        });
      } else {
        throw Exception('Profile not found');
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: $e')),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (widget.userId == null) return;
    final res = await _svc.updateProfile(
      userId: widget.userId!,
      firstName: _firstC.text.trim(),
      lastName: _lastC.text.trim(),
      email: _emailC.text.trim(),
      phone: _phoneC.text.trim(),
      address: _addressC.text.trim(),
      city: _cityC.text.trim(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res['message'] ?? 'Saved')),
    );
  }

  @override
  void dispose() {
    _firstC.dispose();
    _lastC.dispose();
    _emailC.dispose();
    _phoneC.dispose();
    _addressC.dispose();
    _cityC.dispose();
    _currentPwC.dispose();
    _newPwC.dispose();
    _confirmPwC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Personal Information",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildField("First Name", _firstC),
          _buildField("Last Name", _lastC),
          _buildField("Email", _emailC, keyboardType: TextInputType.emailAddress),
          _buildField("Phone", _phoneC, keyboardType: TextInputType.phone),
          _buildField("Address", _addressC),
          _buildField("City", _cityC),

          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _saveProfile,
            icon: const Icon(Icons.save),
            label: const Text("Save Changes"),
          ),

          const SizedBox(height: 20),
          Divider(color: cs.outlineVariant),
          ListTile(
            leading: const Icon(Icons.verified_user, color: Colors.green),
            title: const Text("Account Verification"),
            subtitle: const Text("Submit ID for verification"),
            trailing: FilledButton.tonal(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserVertificationScreen(userId: widget.userId!),
                  ),
                );
              },
              child: const Text("Verify"),
            ),
          ),

          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.lock_outline, color: Colors.orange),
            title: const Text("Change Password"),
            trailing: IconButton(
              icon: Icon(
                _showPasswordSection ? Icons.expand_less : Icons.expand_more,
              ),
              onPressed: () =>
                  setState(() => _showPasswordSection = !_showPasswordSection),
            ),
          ),
          if (_showPasswordSection)
            _buildPasswordSection(),

          const SizedBox(height: 20),
          Center(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.arrow_back),
              label: const Text("Back to Profile"),
              onPressed: widget.onBack,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController c,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: c,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          _buildField("Current Password", _currentPwC),
          _buildField("New Password", _newPwC),
          _buildField("Confirm New Password", _confirmPwC),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.save),
            label: const Text("Update Password"),
          ),
        ],
      ),
    );
  }
}
