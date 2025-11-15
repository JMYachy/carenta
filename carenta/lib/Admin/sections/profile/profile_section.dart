import 'dart:io';
import 'package:carenta/Admin/sections/profile/service/admin_profile_service.dart';
import 'package:carenta/service/config/service_base_url.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AdminProfileSection extends StatefulWidget {
  final int adminId;
  const AdminProfileSection({super.key, required this.adminId});

  @override
  State<AdminProfileSection> createState() => _AdminProfileSectionState();
}

class _AdminProfileSectionState extends State<AdminProfileSection> {
  late final AdminProfileService _service;
  bool _loading = true;
  Map<String, dynamic>? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = AdminProfileService(widget.adminId);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _service.fetchProfile();
      if (!mounted) return;

      if (res['ok'] == true) {
        final d = Map<String, dynamic>.from(res['data'] ?? {});
        d['profile_picture'] = ServiceBaseUrl.file(d['profile_picture'] ?? '');
        setState(() {
          _data = d;
          _error = null;
        });
      } else {
        _error = res['message'] ?? 'Server error';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changePasswordDialog() async {
    final current = TextEditingController();
    final next = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Change Password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: current,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current password',
                  ),
                ),
                TextField(
                  controller: next,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New password (min 8 characters)',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Change'),
              ),
            ],
          ),
    );

    if (ok == true) {
      final res = await _service.changePassword(
        current: current.text,
        next: next.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Password updated')),
      );
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    try {
      final res = await _service.uploadAvatar(imageFile: File(picked.path));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Avatar updated')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error: $_error', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    final p = _data ?? {};
    final picture = p['profile_picture'] ?? '';
    final name = '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'.trim();
    final username = p['username'] ?? '';
    final email = p['email'] ?? '';
    final phone = p['phone_number'] ?? '';
    final lastLogin = p['last_login'] ?? '—';
    final ip = p['last_ip_address'] ?? '—';
    final role = (p['role'] ?? 'Admin').toString().toUpperCase();
    final status = (p['status'] ?? 'active').toString();

    final statusColor = switch (status) {
      'active' => Colors.green,
      'inactive' => Colors.orange,
      'banned' => Colors.red,
      _ => Colors.grey,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Profile'), centerTitle: true),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // --- Profile Header ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: CircleAvatar(
                        radius: 35,
                        backgroundImage:
                            picture.isNotEmpty ? NetworkImage(picture) : null,
                        child:
                            picture.isEmpty
                                ? const Icon(Icons.person, size: 40)
                                : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _buildBadge(role, Colors.blue),
                              const SizedBox(width: 8),
                              _buildBadge(status, statusColor),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- Account Details Card ---
              _buildCard(
                title: 'Account Details',
                children: [
                  _infoRow('Username', username),
                  _infoRow('Email', email),
                  _infoRow('Phone', phone),
                  _infoRow('Last Login', lastLogin),
                  _infoRow('IP Address', ip),
                ],
              ),
              const SizedBox(height: 20),

              // --- Security Options ---
              _buildCard(
                title: 'Security Options',
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Two-Factor Authentication',
                        style: TextStyle(fontSize: 16),
                      ),
                      Switch(value: true, onChanged: null),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade50,
                      foregroundColor: Colors.blue,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    onPressed: _changePasswordDialog,
                    icon: const Icon(Icons.lock_outline),
                    label: const Text('Change Password'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    onPressed: () {
                      Navigator.of(context).popUntil((r) => r.isFirst);
                    },
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
