import 'package:flutter/material.dart';

/// ProfileSummaryCard
/// Displays avatar, name, role, status, contact, and 4 action buttons.
class ProfileSummaryCard extends StatelessWidget {
  final String name;
  final String role;
  final String status;
  final String email;
  final String phone;
  final String pictureUrl;
  final String lastLogin;
  final String lastIp;

  final VoidCallback? onTapEdit;
  final VoidCallback? onTapSecurity;
  final VoidCallback? onTapAnalytics;
  final VoidCallback? onTapLogout;

  const ProfileSummaryCard({
    super.key,
    required this.name,
    required this.role,
    required this.status,
    required this.email,
    required this.phone,
    required this.pictureUrl,
    required this.lastLogin,
    required this.lastIp,
    this.onTapEdit,
    this.onTapSecurity,
    this.onTapAnalytics,
    this.onTapLogout,
  });

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF0077B6);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 45,
              backgroundImage:
                  pictureUrl.isNotEmpty ? NetworkImage(pictureUrl) : null,
              backgroundColor: Colors.grey.shade300,
              child:
                  pictureUrl.isEmpty
                      ? const Icon(Icons.person, size: 45, color: Colors.white)
                      : null,
            ),
            const SizedBox(height: 12),
            Text(
              name.isEmpty ? 'Manager' : name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              role.toUpperCase(),
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color:
                    status == 'active'
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  color:
                      status == 'active'
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(email, style: const TextStyle(fontSize: 13)),
            Text(
              phone,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 14),

            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                _ActionButton(
                  icon: Icons.edit,
                  label: 'Edit Profile',
                  onTap: onTapEdit,
                  color: blue,
                ),
                _ActionButton(
                  icon: Icons.security,
                  label: 'Security',
                  onTap: onTapSecurity,
                  color: blue,
                ),
                _ActionButton(
                  icon: Icons.bar_chart,
                  label: 'Analytics',
                  onTap: onTapAnalytics,
                  color: blue,
                ),
                _ActionButton(
                  icon: Icons.logout,
                  label: 'Logout',
                  onTap: onTapLogout,
                  color: Colors.redAccent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 44,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withOpacity(0.7)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          foregroundColor: color,
        ),
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
    );
  }
}
