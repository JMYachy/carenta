import 'package:flutter/material.dart';
import 'package:carenta/utils/session_manager.dart';
import 'package:carenta/service/user/user_profile_service.dart';
import 'package:carenta/main/splash_screen.dart';
import 'package:intl/intl.dart'; // add intl in pubspec if not present

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
  String? _gender; // 'male'|'female'|'other'

  bool _editing = false;
  bool _saving = false;
  bool _filledOnce = false;

  late Future<_UserProfile> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_UserProfile> _load() async {
    final userId = SessionManager.instance.userId ?? 1;
    final res = await _svc.fetchProfile(userId);
    if (res['status'] == 'success') {
      final data = Map<String, dynamic>.from(res['data'] as Map);
      final model = _UserProfile.fromMap(data);
      return model;
    }
    final body = (res['body'] ?? '') as String;
    throw Exception('${res['message'] ?? 'Failed to load profile'}${body.isNotEmpty ? ' • $body' : ''}');
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
      setState(() {
        _birthdate = picked;
      });
    }
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '';
    return DateFormat('MMM d, yyyy').format(d);
  }

  Future<void> _saveProfile() async {
    if (_saving) return;
    final userId = SessionManager.instance.userId ?? 1;

    // perform async first
    setState(() => _saving = true);
    final res = await _svc.updateProfile(
      userId: userId,
      firstName: _firstC.text.trim(),
      lastName: _lastC.text.trim(),
      email: _emailC.text.trim(),
      phone: _phoneC.text.trim(),
      username: _usernameC.text.trim().isEmpty ? null : _usernameC.text.trim(),
      gender: _gender,
      birthdate: _birthdate != null ? DateFormat('yyyy-MM-dd').format(_birthdate!) : null,
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
        _future = _load(); // refresh
      });
    }
  }

  Future<void> _changePassword() async {
    final userId = SessionManager.instance.userId ?? 1;
    final currentC = TextEditingController();
    final newC = TextEditingController();
    final confirmC = TextEditingController();

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final inset = MediaQuery.of(ctx).viewInsets;
        return Padding(
          padding: EdgeInsets.only(bottom: inset.bottom),
          child: _PasswordSheet(currentC: currentC, newC: newC, confirmC: confirmC),
        );
      },
    );
    if (ok != true) return;
    if (newC.text.trim() != confirmC.text.trim()) {
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New passwords do not match')));
      return;
    }
    if (newC.text.trim().length < 6) {
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 6 characters')));
      return;
    }

    final res = await _svc.changePassword(
      userId: userId,
      currentPassword: currentC.text.trim(),
      newPassword: newC.text.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res['message'] ?? (res['status'] == 'success' ? 'Updated' : 'Failed'))),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton.tonal(onPressed: () => Navigator.pop(ctx, true), child: const Text('Logout')),
        ],
      ),
    );
    if (confirm != true) return;

    await SessionManager.instance.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (_) => false,
    );
  }

  // Optional: integrate image_picker and call _svc.uploadAvatar(...).
  Future<void> _changeAvatar() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Avatar upload not wired yet. Add image_picker and call uploadAvatar().')),
    );
    // Example flow (once you add image_picker):
    // final XFile? x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    // if (x == null) return;
    // final res = await _svc.uploadAvatar(userId: SessionManager.instance.userId ?? 1, file: File(x.path));
    // if (!mounted) return;
    // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Updated')));
    // if (res['status'] == 'success') setState(()=> _future = _load());
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
            return _ErrState(
              message: snap.error.toString(),
              onRetry: () => setState(() => _future = _load()),
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
            _gender = profile.gender?.isEmpty == true ? null : profile.gender;
            _birthdate = profile.birthdate;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              children: [
                _Header(profile: profile, onChangeAvatar: _changeAvatar),
                const SizedBox(height: 16),

                // Account
                _Card(
                  child: Column(
                    children: [
                      _Field(icon: Icons.alternate_email_rounded, label: 'Username', controller: _usernameC, enabled: _editing),
                      const Divider(height: 1),
                      _StaticRow(
                        icon: Icons.verified_user_rounded,
                        label: 'Account type',
                        value: profile.accountType.isEmpty ? 'Standard' : profile.accountType,
                      ),
                      const Divider(height: 1),
                      _StaticRow(
                        icon: Icons.shield_moon_rounded,
                        label: 'Status',
                        value: profile.status ?? 'active',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Personal
                _Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _Field(icon: Icons.badge_rounded, label: 'First name', controller: _firstC, enabled: _editing)),
                            const SizedBox(width: 8),
                            Expanded(child: _Field(icon: Icons.badge_outlined, label: 'Last name', controller: _lastC, enabled: _editing)),
                          ],
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(Icons.wc_rounded, color: cs.primary),
                          title: DropdownButtonFormField<String>(
                            value: _gender = 'male',
                            decoration: const InputDecoration(border: InputBorder.none, labelText: 'Gender'),
                            items: const [
                              DropdownMenuItem(value: 'male', child: Text('Male')),
                              DropdownMenuItem(value: 'female', child: Text('Female')),
                              DropdownMenuItem(value: 'other', child: Text('Other')),
                            ],
                            onChanged: _editing ? (v) => setState(() => _gender = v) : null,
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(Icons.cake_rounded, color: cs.primary),
                          title: Text('Birthdate'),
                          subtitle: Text(_fmtDate(_birthdate).isEmpty ? 'Not set' : _fmtDate(_birthdate)),
                          trailing: _editing
                              ? TextButton.icon(
                                  onPressed: _pickBirthdate,
                                  icon: const Icon(Icons.edit_calendar_rounded),
                                  label: const Text('Pick'),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Contact
                _Card(
                  child: Column(
                    children: [
                      _Field(icon: Icons.email_rounded, label: 'Email', controller: _emailC, keyboardType: TextInputType.emailAddress, enabled: _editing),
                      const Divider(height: 1),
                      _Field(icon: Icons.phone_rounded, label: 'Phone', controller: _phoneC, keyboardType: TextInputType.phone, enabled: _editing),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Address
                _Card(
                  child: Column(
                    children: [
                      _Field(icon: Icons.home_rounded, label: 'Address', controller: _addressC, enabled: _editing),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            Expanded(child: _Field(icon: Icons.location_city_rounded, label: 'City', controller: _cityC, enabled: _editing)),
                            const SizedBox(width: 8),
                            Expanded(child: _Field(icon: Icons.map_rounded, label: 'Province', controller: _provinceC, enabled: _editing)),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 110,
                              child: _Field(icon: Icons.local_post_office_rounded, label: 'ZIP', controller: _zipC, enabled: _editing, keyboardType: TextInputType.number),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.lock_reset_rounded),
                        title: const Text('Change password'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _changePassword,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                if (_editing)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _saveProfile,
                      icon: _saving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.save_rounded),
                      label: const Text('Save changes'),
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Logout'),
                    style: OutlinedButton.styleFrom(foregroundColor: cs.error),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/* ==================== Model & UI bits ==================== */

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
  final String? gender;        // 'male'|'female'|'other'
  final DateTime? birthdate;   // nullable
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

  static int _toInt(dynamic v, {int def = 0}) =>
      v == null ? def : (v is int ? v : int.tryParse(v.toString()) ?? def);
  static String _toStr(dynamic v) => v?.toString() ?? '';

  static DateTime? _toDate(dynamic v) {
    final s = v?.toString() ?? '';
    if (s.isEmpty) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

  factory _UserProfile.fromMap(Map<String, dynamic> m) {
    return _UserProfile(
      userId: _toInt(m['userid'] ?? m['user_id']),
      username: _toStr(m['username']),
      firstName: _toStr(m['first_name']),
      lastName: _toStr(m['last_name']),
      email: _toStr(m['email']),
      phone: _toStr(m['phone_number'] ?? m['phone']),
      accountType: _toStr(m['account_type'] ?? m['role']),
      status: m['status']?.toString(),
      address: m['address']?.toString(),
      city: m['city']?.toString(),
      province: m['province']?.toString(),
      zipCode: m['zip_code']?.toString(),
      gender: m['gender']?.toString(),
      birthdate: _toDate(m['birthdate']),
      avatarUrl: (m['profile_picture']?.toString().isNotEmpty ?? false) ? m['profile_picture'].toString() : null,
    );
  }

  String get fullName {
    final f = firstName.trim();
    final l = lastName.trim();
    if (f.isEmpty && l.isEmpty) return username;
    if (l.isEmpty) return f;
    if (f.isEmpty) return l;
    return '$f $l';
  }
}

class _Header extends StatelessWidget {
  final _UserProfile profile;
  final VoidCallback onChangeAvatar;
  const _Header({required this.profile, required this.onChangeAvatar});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initials = _initials(profile.fullName);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary.withValues(alpha: 0.10), cs.primary.withValues(alpha: 0.03)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              _Avatar(avatarUrl: profile.avatarUrl, initials: initials),
              Positioned(
                right: 0,
                bottom: 0,
                child: Material(
                  color: cs.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onChangeAvatar,
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.edit_rounded, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.fullName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(profile.email, style: TextStyle(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: cs.secondaryContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              (profile.accountType.isEmpty ? 'Standard' : profile.accountType).toUpperCase(),
              style: TextStyle(color: cs.onSecondaryContainer, fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: .5),
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String s) {
    final parts = s.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.characters.take(2).toString().toUpperCase();
    return (parts[0].isEmpty ? '' : parts[0][0]) + (parts[1].isEmpty ? '' : parts[1][0]);
  }
}

class _Avatar extends StatelessWidget {
  final String? avatarUrl;
  final String initials;
  const _Avatar({required this.avatarUrl, required this.initials});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: 32,
      backgroundColor: cs.surfaceContainerHighest,
      backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty) ? NetworkImage(avatarUrl!) : null,
      child: (avatarUrl == null || avatarUrl!.isEmpty)
          ? Text(initials.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800))
          : null,
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: child,
    );
  }
}

class _Field extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final TextInputType? keyboardType;

  const _Field({
    required this.icon,
    required this.label,
    required this.controller,
    this.enabled = true,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: cs.primary),
      title: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _StaticRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StaticRow({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: cs.primary),
      title: Text(label),
      trailing: Text(value, style: TextStyle(color: cs.onSurfaceVariant)),
    );
  }
}

class _PasswordSheet extends StatelessWidget {
  final TextEditingController currentC;
  final TextEditingController newC;
  final TextEditingController confirmC;

  const _PasswordSheet({required this.currentC, required this.newC, required this.confirmC});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(999))),
          const SizedBox(height: 12),
          Text('Change password', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(obscureText: true, controller: currentC, decoration: const InputDecoration(prefixIcon: Icon(Icons.lock_outline_rounded), labelText: 'Current password')),
          const SizedBox(height: 8),
          TextField(obscureText: true, controller: newC, decoration: const InputDecoration(prefixIcon: Icon(Icons.lock_rounded), labelText: 'New password')),
          const SizedBox(height: 8),
          TextField(obscureText: true, controller: confirmC, decoration: const InputDecoration(prefixIcon: Icon(Icons.lock_rounded), labelText: 'Confirm new password')),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel'))),
              const SizedBox(width: 8),
              Expanded(child: FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Update'))),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ErrState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrState({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.error_outline_rounded, size: 56, color: cs.error),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(message, textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant)),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Retry')),
      ]),
    );
  }
}