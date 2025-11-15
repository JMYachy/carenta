// lib/Admin/widget/profile_card.dart
import 'package:flutter/material.dart';
import 'k_colors.dart';
import 'k_typography.dart';

class ProfileCard extends StatelessWidget {
  final String name;
  final String role;
  final String email;
  final String phone;
  final String status;
  final String? image;
  final VoidCallback? onEdit;
  final VoidCallback? onLogout;

  const ProfileCard({
    super.key,
    required this.name,
    required this.role,
    required this.email,
    required this.phone,
    required this.status,
    this.image,
    this.onEdit,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: AssetImage(
                    image ?? 'assets/images/admin_avatar.png',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: KText.title),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _badge(role, KColors.primary),
                          const SizedBox(width: 6),
                          _badge(
                            status,
                            status == 'Active' ? Colors.green : Colors.orange,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _infoRow('Email', email),
            _infoRow('Phone', phone),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: KText.label),
        Text(value, style: KText.value),
      ],
    ),
  );

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(text, style: TextStyle(fontSize: 12, color: color)),
  );
}
