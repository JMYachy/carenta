import 'package:flutter/material.dart';

class SecurityPanel extends StatelessWidget {
  final bool twoFactorEnabled;
  final int loginAttempts;
  final String lastIp;
  final String lastLogin;
  final Future<void> Function(bool enabled) onToggle2FA;
  final Future<void> Function(String current, String next) onChangePassword;

  const SecurityPanel({
    super.key,
    required this.twoFactorEnabled,
    required this.loginAttempts,
    required this.lastIp,
    required this.lastLogin,
    required this.onToggle2FA,
    required this.onChangePassword,
  });

  @override
  Widget build(BuildContext context) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    bool local2fa = twoFactorEnabled;

    Future<void> _changePwDialog() async {
      await showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Change Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Current Password',
                    ),
                  ),
                  TextField(
                    controller: newCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await onChangePassword(currentCtrl.text, newCtrl.text);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Update'),
                ),
              ],
            ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: Text('Two-Factor Authentication')),
            StatefulBuilder(
              builder:
                  (ctx, setSB) => Switch(
                    value: local2fa,
                    onChanged: (v) async {
                      await onToggle2FA(v);
                      setSB(() => local2fa = v);
                    },
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 16,
          runSpacing: 6,
          children: [
            Text(
              'Login Attempts: $loginAttempts',
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
            Text(
              'Last IP: $lastIp',
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
            Text(
              'Last Login: $lastLogin',
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: OutlinedButton.icon(
            onPressed: _changePwDialog,
            icon: const Icon(Icons.password_outlined, size: 18),
            label: const Text(
              'Change Password',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              foregroundColor: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
