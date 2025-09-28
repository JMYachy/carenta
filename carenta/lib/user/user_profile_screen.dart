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
  final _svc = const UserProfileService(apiRoot: 'http://10.0.2.2/carenta/api');

  // controllers
  final _firstC = TextEditingController();
  final _lastC = TextEditingController();
  final _emailC = TextEditingController();
  final _phoneC = TextEditingController();
  final _usernameC = TextEditingController();
  final _addressC = TextEditingController();
  final _cityC = TextEditingController();
  final _provinceC = TextEditingController();
  final _zipC = TextEditingController();

  DateTime? _birthdate;
  String? _gender;

  bool _editing = false;
  bool _saving = false;
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
    } catch (e) {
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
      birthdate: _birthdate != null
          ? DateFormat('yyyy-MM-dd').format(_birthdate!)
          : null,
      address: _addressC.text.trim().isEmpty ? null : _addressC.text.trim(),
      city: _cityC.text.trim().isEmpty ? null : _cityC.text.trim(),
      province: _provinceC.text.trim().isEmpty ? null : _provinceC.text.trim(),
      zipCode: _zipC.text.trim().isEmpty ? null : _zipC.text.trim(),
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

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton.tonal(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Logout')),
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
    _provinceC.dispose();
    _zipC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_userId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 8),
                  Text(snap.error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                      onPressed: () =>
                          setState(() => _future = _load()),
                      child: const Text("Retry")),
                ],
              ),
            );
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
            _provinceC.text = profile.province ?? '';
            _zipC.text = profile.zipCode ?? '';
            _gender =
                profile.gender?.isEmpty == true ? null : profile.gender;
            _birthdate = profile.birthdate;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              children: [
                _Header(profile: profile),
                const SizedBox(height: 16),

                // Example: Personal info
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.email, color: cs.primary),
                        title: Text(profile.email),
                      ),
                      ListTile(
                        leading: Icon(Icons.phone, color: cs.primary),
                        title: Text(profile.phone),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                if (_editing)
                  FilledButton.icon(
                    onPressed: _saving ? null : _saveProfile,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(strokeWidth: 2))
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
}

/* ==================== Model ==================== */

class _UserProfile {
  final int userId;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String accountType;
  final String? status;
  final String? address;
  final String? city;
  final String? province;
  final String? zipCode;
  final String? gender;
  final DateTime? birthdate;
  final String? avatarUrl;

  _UserProfile({
    required this.userId,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.accountType,
    required this.status,
    required this.address,
    required this.city,
    required this.province,
    required this.zipCode,
    required this.gender,
    required this.birthdate,
    required this.avatarUrl,
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
      accountType: m['account_type']?.toString() ?? m['role']?.toString() ?? '',
      status: m['status']?.toString(),
      address: m['address']?.toString(),
      city: m['city']?.toString(),
      province: m['province']?.toString(),
      zipCode: m['zip_code']?.toString(),
      gender: m['gender']?.toString(),
      birthdate: _toDate(m['birthdate']),
      avatarUrl: m['profile_picture']?.toString(),
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
        backgroundImage: (profile.avatarUrl != null &&
                profile.avatarUrl!.isNotEmpty)
            ? NetworkImage(profile.avatarUrl!)
            : null,
        child: (profile.avatarUrl == null || profile.avatarUrl!.isEmpty)
            ? Text(
                profile.fullName.isNotEmpty
                    ? profile.fullName[0].toUpperCase()
                    : 'U',
                style: const TextStyle(fontSize: 24),
              )
            : null,
      ),
      title: Text(profile.fullName,
          style: Theme.of(context).textTheme.titleLarge),
      subtitle: Text(profile.email),
    );
  }
}
