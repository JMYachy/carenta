import 'package:carenta/service/util_service/session_manager_service.dart';
import 'package:flutter/material.dart';
import 'package:carenta/service/user/user_profile_service.dart';
import 'package:carenta/main/splash_screen.dart';
import 'package:intl/intl.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _svc = UserProfileService();

  // controllers
  final _firstC = TextEditingController();
  final _lastC = TextEditingController();
  final _emailC = TextEditingController();
  final _phoneC = TextEditingController();
  final _usernameC = TextEditingController();
  final _addressC = TextEditingController();
  final _cityC = TextEditingController();
  final _stateC = TextEditingController();
  final _zipC = TextEditingController();
  final _countryC = TextEditingController();
  final _languageC = TextEditingController();
  final _timezoneC = TextEditingController();

  // password controllers
  final _currentPwC = TextEditingController();
  final _newPwC = TextEditingController();
  final _confirmPwC = TextEditingController();

  DateTime? _birthdate;
  String? _gender;
  bool _darkMode = false;

  bool _editing = false;
  bool _saving = false;
  bool _changingPw = false;
  bool _filledOnce = false;

  late Future<_UserProfile> _future;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _checkSessionAndLoad();
  }

  Future<void> _checkSessionAndLoad() async {
    try {
      final session = await SessionService.checkSession();
      if (session['success'] == true) {
        setState(() {
          _userId = session['data']?['userid'];
          _future = _load();
        });
      } else {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SplashScreen()),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SplashScreen()),
        );
      }
    }
  }

  Future<_UserProfile> _load() async {
    if (_userId == null) throw Exception("No active session");
    final res = await _svc.fetchProfile(_userId!);
    if (res['status'] == 'success') {
      final data = Map<String, dynamic>.from(res['data'] as Map);
      return _UserProfile.fromMap(data);
    }
    throw Exception(res['message'] ?? 'Failed to load profile');
  }

  Future<void> _pickBirthdate() async {
    final now = DateTime.now();
    final initial = _birthdate ?? DateTime(now.year - 21, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _birthdate = picked);
    }
  }

  String _fmtDate(DateTime? d) =>
      d == null ? '' : DateFormat('MMM d, yyyy').format(d);

  Future<void> _saveProfile() async {
    if (_saving || _userId == null) return;
    setState(() => _saving = true);

    final res = await _svc.updateProfile(
      userId: _userId!,
      firstName: _firstC.text.trim(),
      lastName: _lastC.text.trim(),
      email: _emailC.text.trim(),
      phone: _phoneC.text.trim(),
      username: _usernameC.text.trim().isEmpty ? null : _usernameC.text.trim(),
      gender: _gender,
      birthdate:
          _birthdate != null
              ? DateFormat('yyyy-MM-dd').format(_birthdate!)
              : null,
      address: _addressC.text.trim().isEmpty ? null : _addressC.text.trim(),
      city: _cityC.text.trim().isEmpty ? null : _cityC.text.trim(),
      province: _stateC.text.trim().isEmpty ? null : _stateC.text.trim(),
      zipCode: _zipC.text.trim().isEmpty ? null : _zipC.text.trim(),
      country: _countryC.text.trim().isEmpty ? null : _countryC.text.trim(),
      language: _languageC.text.trim().isEmpty ? null : _languageC.text.trim(),
      timezone: _timezoneC.text.trim().isEmpty ? null : _timezoneC.text.trim(),
      darkMode: _darkMode,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    final ok = res['status'] == 'success';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res['message'] ?? (ok ? 'Saved' : 'Save failed'))),
    );

    if (ok) {
      setState(() {
        _editing = false;
        _future = _load();
      });
    }
  }

  Future<void> _changePassword() async {
    if (_changingPw || _userId == null) return;

    final current = _currentPwC.text.trim();
    final newPw = _newPwC.text.trim();
    final confirmPw = _confirmPwC.text.trim();

    if (newPw.isEmpty || confirmPw.isEmpty || current.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fill all password fields')));
      return;
    }
    if (newPw != confirmPw) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match')),
      );
      return;
    }

    setState(() => _changingPw = true);
    final res = await _svc.changePassword(
      userId: _userId!,
      currentPassword: current,
      newPassword: newPw,
    );
    setState(() => _changingPw = false);

    final ok = res['status'] == 'success';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res['message'] ?? (ok ? 'Password updated' : 'Failed')),
      ),
    );

    if (ok) {
      _currentPwC.clear();
      _newPwC.clear();
      _confirmPwC.clear();
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to log out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton.tonal(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Logout'),
              ),
            ],
          ),
    );
    if (confirm != true) return;

    await SessionService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (_) => false,
    );
  }

  @override
  void dispose() {
    _firstC.dispose();
    _lastC.dispose();
    _emailC.dispose();
    _phoneC.dispose();
    _usernameC.dispose();
    _addressC.dispose();
    _cityC.dispose();
    _stateC.dispose();
    _zipC.dispose();
    _countryC.dispose();
    _languageC.dispose();
    _timezoneC.dispose();
    _currentPwC.dispose();
    _newPwC.dispose();
    _confirmPwC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_userId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            tooltip: _editing ? 'Cancel' : 'Edit',
            icon: Icon(_editing ? Icons.close_rounded : Icons.edit_rounded),
            onPressed: () => setState(() => _editing = !_editing),
          ),
        ],
      ),
      body: FutureBuilder<_UserProfile>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text("Error: ${snap.error}"));
          }

          final profile = snap.data!;
          if (!_filledOnce) {
            _filledOnce = true;
            _firstC.text = profile.firstName;
            _lastC.text = profile.lastName;
            _emailC.text = profile.email;
            _phoneC.text = profile.phone;
            _usernameC.text = profile.username;
            _addressC.text = profile.address ?? '';
            _cityC.text = profile.city ?? '';
            _stateC.text = profile.state ?? '';
            _zipC.text = profile.zipCode ?? '';
            _countryC.text = profile.country ?? '';
            _languageC.text = profile.language ?? '';
            _timezoneC.text = profile.timezone ?? '';
            _gender = profile.gender;
            _birthdate = profile.birthdate;
            _darkMode = profile.darkMode;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _Header(profile: profile),
                const SizedBox(height: 16),

                // Profile card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildEditable("First Name", _firstC),
                      _buildEditable("Last Name", _lastC),
                      _buildEditable("Username", _usernameC),
                      _buildEditable(
                        "Email",
                        _emailC,
                        type: TextInputType.emailAddress,
                      ),
                      _buildEditable(
                        "Phone",
                        _phoneC,
                        type: TextInputType.phone,
                      ),
                      _buildEditable("Address", _addressC),
                      _buildEditable("City", _cityC),
                      _buildEditable("State/Province", _stateC),
                      _buildEditable("Postal Code", _zipC),
                      _buildEditable("Country", _countryC),
                      ListTile(
                        title: const Text("Gender"),
                        trailing: DropdownButton<String>(
                          value: _gender,
                          hint: const Text("Select"),
                          items: const [
                            DropdownMenuItem(
                              value: "Male",
                              child: Text("Male"),
                            ),
                            DropdownMenuItem(
                              value: "Female",
                              child: Text("Female"),
                            ),
                            DropdownMenuItem(
                              value: "Other",
                              child: Text("Other"),
                            ),
                          ],
                          onChanged:
                              _editing
                                  ? (v) => setState(() => _gender = v)
                                  : null,
                        ),
                      ),
                      ListTile(
                        title: const Text("Birthdate"),
                        subtitle: Text(_fmtDate(_birthdate)),
                        trailing:
                            _editing
                                ? IconButton(
                                  icon: const Icon(Icons.calendar_today),
                                  onPressed: _pickBirthdate,
                                )
                                : null,
                      ),
                      SwitchListTile(
                        title: const Text("Dark Mode"),
                        value: _darkMode,
                        onChanged:
                            _editing
                                ? (v) => setState(() => _darkMode = v)
                                : null,
                      ),
                      _buildEditable("Language", _languageC),
                      _buildEditable("Timezone", _timezoneC),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Change password card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Change Password",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _PasswordField(
                          controller: _currentPwC,
                          label: "Current Password",
                          icon: Icons.lock_outline,
                        ),
                        const SizedBox(height: 12),
                        _PasswordField(
                          controller: _newPwC,
                          label: "New Password",
                          icon: Icons.lock_reset,
                        ),
                        const SizedBox(height: 12),
                        _PasswordField(
                          controller: _confirmPwC,
                          label: "Confirm New Password",
                          icon: Icons.lock_person,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            icon:
                                _changingPw
                                    ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : const Icon(Icons.save),
                            label: Text(
                              _changingPw ? "Updating..." : "Update Password",
                            ),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _changingPw ? null : _changePassword,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                if (_editing)
                  FilledButton.icon(
                    onPressed: _saving ? null : _saveProfile,
                    icon:
                        _saving
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.save),
                    label: const Text('Save changes'),
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: OutlinedButton.styleFrom(foregroundColor: cs.error),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEditable(
    String label,
    TextEditingController c, {
    TextInputType type = TextInputType.text,
  }) {
    return ListTile(
      title: Text(label),
      subtitle: TextField(controller: c, enabled: _editing, keyboardType: type),
    );
  }
}

/* ==================== Custom PasswordField ==================== */
class _PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.icon,
  });

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: Icon(widget.icon),
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

/* ==================== Model ==================== */
class _UserProfile {
  final int userId;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? country;
  final String? gender;
  final DateTime? birthdate;
  final String? avatarUrl;
  final String? language;
  final String? timezone;
  final bool darkMode;

  _UserProfile({
    required this.userId,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.country,
    this.gender,
    this.birthdate,
    this.avatarUrl,
    this.language,
    this.timezone,
    this.darkMode = false,
  });

  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return null;
    }
  }

  factory _UserProfile.fromMap(Map<String, dynamic> m) {
    return _UserProfile(
      userId: int.tryParse(m['userid'].toString()) ?? 0,
      username: m['username']?.toString() ?? '',
      firstName: m['first_name']?.toString() ?? '',
      lastName: m['last_name']?.toString() ?? '',
      email: m['email']?.toString() ?? '',
      phone: m['phone_number']?.toString() ?? '',
      address: m['street_address']?.toString(),
      city: m['city']?.toString(),
      state: m['state']?.toString(),
      zipCode: m['postal_code']?.toString(),
      country: m['country']?.toString(),
      gender: m['gender']?.toString(),
      birthdate: _toDate(m['birthdate']),
      avatarUrl: m['profile_picture']?.toString(),
      language: m['language']?.toString(),
      timezone: m['timezone']?.toString(),
      darkMode: (m['dark_mode']?.toString() == '1'),
    );
  }

  String get fullName {
    if (firstName.isEmpty && lastName.isEmpty) return username;
    return "$firstName $lastName".trim();
  }
}

class _Header extends StatelessWidget {
  final _UserProfile profile;
  const _Header({required this.profile});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 32,
        backgroundImage:
            (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty)
                ? NetworkImage(profile.avatarUrl!)
                : null,
        child:
            (profile.avatarUrl == null || profile.avatarUrl!.isEmpty)
                ? Text(
                  profile.fullName.isNotEmpty
                      ? profile.fullName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(fontSize: 24),
                )
                : null,
      ),
      title: Text(
        profile.fullName,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      subtitle: Text(profile.email),
    );
  }
}
