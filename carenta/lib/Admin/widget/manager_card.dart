// lib/Admin/widget/manager_card.dart
import 'package:flutter/material.dart';
import 'k_colors.dart';
import 'k_typography.dart';

class ManagerCard extends StatelessWidget {
  final String name;
  final String email;
  final String avatarUrl;
  final String lastLogin;
  final bool isActive;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ManagerCard({
    super.key,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.lastLogin,
    required this.isActive,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(radius: 28, backgroundImage: AssetImage(avatarUrl)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: KText.title),
                  const SizedBox(height: 2),
                  Text(email, style: KText.small),
                  const SizedBox(height: 4),
                  Text("Last login: $lastLogin", style: KText.small),
                ],
              ),
            ),
            Column(
              children: [
                Switch(
                  activeColor: KColors.primary,
                  value: isActive,
                  onChanged: (_) => onToggle(),
                ),
                Text(
                  isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 11,
                    color: isActive ? Colors.green : Colors.grey[600],
                  ),
                ),
              ],
            ),
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'edit') onEdit();
                if (val == 'delete') onDelete();
              },
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
            ),
          ],
        ),
      ),
    );
  }
}
