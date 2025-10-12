import 'dart:io';
import 'package:carenta/main/splash_screen.dart';
import 'package:carenta/service/admin/admin_profile_service.dart';
import 'package:carenta/service/util_service/session_manager_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final AdminProfileService _svc = AdminProfileService();

  int? _adminId;
  bool _checkingSession = true;

  late Future<Map<String, dynamic>> _future;
  bool _isEditing = false;
  bool _saving = false;
  bool _changingPw = false;

  // fields
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  bool _twoFA = false;
  String? _avatarUrl;
  String _role = 'admin';
  String _username = '';

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    try {
      final res = await SessionService.checkSession();
      if (res['success'] == true &&
          (res['data']?['account_type'] == 'admin_table')) {
        setState(() {
          _adminId = res['data']?['adminid'];
          _future = _load();
          _checkingSession = false;
        });
      } else {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SplashScreen()),
        );
      }
    } catch (_) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SplashScreen()),
      );
    }
  }

  Future<Map<String, dynamic>> _load() async {
    final res = await _svc.fetchProfile(_adminId!);
    if (res['status'] == 'success') {
      final data = res['data'] as Map<String, dynamic>;
      _username = (data['username'] ?? '').toString();
      _role = (data['role'] ?? '').toString();
      _first.text = (data['first_name'] ?? '').toString();
      _last.text = (data['last_name'] ?? '').toString();
      _email.text = (data['email'] ?? '').toString();
      _phone.text = (data['phone_number'] ?? '').toString();
      _avatarUrl = (data['profile_picture'] as String?);
      _twoFA = (data['two_factor_enabled']?.toString() == '1');
      return data;
    }
    throw Exception(res['message'] ?? 'Failed to load profile');
  }

  void _refreshProfile() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
    });
    final res = await _svc.updateProfile(
      adminId: _adminId!,
      firstName: _first.text.trim(),
      lastName: _last.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      twoFactorEnabled: _twoFA,
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(res['message'] ?? 'Updated')));
    if (res['status'] == 'success') {
      setState(() {
        _isEditing = false;
        _future = _load();
      });
    }
  }

  Future<void> _changePassword() async {
    final creds = await _askPassword(context);
    if (creds == null) return;
    setState(() {
      _changingPw = true;
    });
    final res = await _svc.changePassword(
      adminId: _adminId!,
      oldPassword: creds.$1,
      newPassword: creds.$2,
    );
    if (!mounted) return;
    setState(() {
      _changingPw = false;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(res['message'] ?? 'Updated')));
  }

  Future<void> _pickAndUploadAvatar() async {
    if (!_isEditing) return;
    final picker = ImagePicker();
    final x = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 1200, imageQuality: 88);
    if (x == null) return;
    final file = File(x.path);
    final res = await _svc.uploadAvatar(adminId: _adminId!, imageFile: file);
    if (!mounted) return;
    if (res['status'] == 'success') {
      setState(() {
        _avatarUrl = (res['avatar_url'] as String?);
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(res['message'])));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Upload failed')));
    }
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSession) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_adminId == null) {
      return const Scaffold(
        body: Center(child: Text("No admin session")),
      );
    }

    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Column(
        children: [
          _Header(title: 'Admin Profile', subtitle: 'Manage your account'),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return _Error(
                    message: 'Failed to load profile',
                    onRetry: _refreshProfile,
                  );
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    _Avatar(
                      avatarUrl: _avatarUrl,
                      onTap: _pickAndUploadAvatar,
                      editable: _isEditing,
                    ),
                    const SizedBox(height: 16),
                    _InfoChips(username: _username, role: _role),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Personal info',
                      child: Column(
                        children: [
                          _FieldRow(
                              label: 'First name',
                              controller: _first,
                              enabled: _isEditing),
                          _FieldRow(
                              label: 'Last name',
                              controller: _last,
                              enabled: _isEditing),
                          _FieldRow(
                              label: 'Email',
                              controller: _email,
                              enabled: _isEditing,
                              keyboardType: TextInputType.emailAddress),
                          _FieldRow(
                              label: 'Phone',
                              controller: _phone,
                              enabled: _isEditing,
                              keyboardType: TextInputType.phone),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Two-factor authentication'),
                            subtitle:
                                const Text('Add extra security to your account'),
                            value: _twoFA,
                            onChanged: _isEditing
                                ? (v) {
                                    setState(() {
                                      _twoFA = v;
                                    });
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'Security',
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _changingPw ? null : _changePassword,
                              icon: const Icon(Icons.password_rounded),
                              label: Text(
                                  _changingPw ? 'Changing…' : 'Change password'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _ActionsBar(
        editing: _isEditing,
        saving: _saving,
        onEdit: () {
          setState(() {
            _isEditing = true;
          });
        },
        onCancel: () {
          setState(() {
            _isEditing = false;
          });
        },
        onSave: _saving ? null : _save,
      ),
    );
  }
}

/* ===== UI bits ===== */

class _Header extends StatelessWidget {
  final String title, subtitle;
  const _Header({required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary.withValues(alpha: 0.12), cs.primary.withValues(alpha: 0.04), Colors.transparent],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Icon(Icons.manage_accounts_rounded, color: cs.primary, size: 32),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            ]),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? avatarUrl;
  final VoidCallback? onTap;
  final bool editable;
  const _Avatar({this.avatarUrl, this.onTap, required this.editable});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: cs.surfaceContainerHighest,
            backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty) ? NetworkImage(avatarUrl!) : null,
            child: (avatarUrl == null || avatarUrl!.isEmpty) ? const Icon(Icons.person_rounded, size: 48) : null,
          ),
          if (editable)
            Positioned(
              right: 0, bottom: 0,
              child: InkWell(
                onTap: onTap,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: cs.primary,
                  child: Icon(Icons.edit_rounded, size: 18, color: cs.onPrimary),
                ),
              ),
            )
        ],
      ),
    );
  }
}

class _InfoChips extends StatelessWidget {
  final String username, role;
  const _InfoChips({required this.username, required this.role});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
      children: [
        Chip(avatar: const Icon(Icons.badge_rounded, size: 18), label: Text(username)),
        Chip(
          avatar: const Icon(Icons.security_rounded, size: 18),
          label: Text(role.toUpperCase()),
          backgroundColor: cs.primaryContainer,
          labelStyle: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          child,
        ]),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final TextInputType? keyboardType;
  const _FieldRow({required this.label, required this.controller, required this.enabled, this.keyboardType});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class _ActionsBar extends StatelessWidget {
  final bool editing, saving;
  final VoidCallback? onEdit, onCancel, onSave;
  const _ActionsBar({required this.editing, required this.saving, this.onEdit, this.onCancel, this.onSave});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: Row(
          children: [
            if (!editing)
              Expanded(child: FilledButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit_rounded), label: const Text('Edit'))),
            if (editing) ...[
              Expanded(child: OutlinedButton.icon(onPressed: onCancel, icon: const Icon(Icons.close_rounded), label: const Text('Cancel'))),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: saving ? null : onSave,
                  icon: const Icon(Icons.save_rounded),
                  label: Text(saving ? 'Saving…' : 'Save'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Error extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _Error({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.error_outline_rounded, size: 56, color: cs.error),
        const SizedBox(height: 12),
        Text(message, style: TextStyle(color: cs.onSurfaceVariant)),
        const SizedBox(height: 8),
        FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Retry')),
      ]),
    );
  }
}

/* bottom-sheet for password */
Future<(String,String)?> _askPassword(BuildContext context) async {
  final oldC = TextEditingController();
  final newC = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final result = await showModalBottomSheet<(String,String)>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Change password', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextFormField(
              controller: oldC, obscureText: true, decoration: const InputDecoration(labelText: 'Current password'),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: newC, obscureText: true, decoration: const InputDecoration(labelText: 'New password (min 8 chars)'),
              validator: (v) => (v == null || v.length < 8) ? 'Min 8 characters' : null,
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))),
              const SizedBox(width: 8),
              Expanded(child: FilledButton(onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(ctx, (oldC.text, newC.text));
                }
              }, child: const Text('Update'))),
            ]),
          ]),
        ),
      ),
    ),
  );
  return result;
}
