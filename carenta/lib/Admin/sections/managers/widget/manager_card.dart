import 'package:flutter/material.dart';
import 'package:carenta/service/config/service_base_url.dart';

class ManagerCard extends StatelessWidget {
  final String name;
  final String email;
  final String? avatarUrl;
  final String? lastLogin;
  final bool isActive;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ManagerCard({
    super.key,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.lastLogin,
    required this.isActive,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  /// Safely build the full image URL for the profile photo
  String _resolveAvatar() {
    final raw = avatarUrl ?? '';

    // No image stored → placeholder
    if (raw.isEmpty) {
      return ServiceBaseUrl.file('uploads/placeholder_user.png');
    }

    // If DB saved only filename like "profile_2_1762891474.jpg"
    if (!raw.contains('/')) {
      return ServiceBaseUrl.file('uploads/profile/$raw');
    }

    // If it already has "uploads/profile/..."
    if (raw.startsWith('uploads/')) {
      return ServiceBaseUrl.file(raw);
    }

    // If full URL already (starts with http)
    if (raw.startsWith('http')) {
      return raw;
    }

    // Default fallback
    return ServiceBaseUrl.file('uploads/profile/$raw');
  }

  @override
  Widget build(BuildContext context) {
    final fullUrl = _resolveAvatar();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: FadeInImage.assetNetwork(
            placeholder: 'assets/images/avatar_placeholder.png',
            image: fullUrl,
            fit: BoxFit.cover,
            width: 56,
            height: 56,
            imageErrorBuilder:
                (context, error, stackTrace) => Image.asset(
                  'assets/images/avatar_placeholder.png',
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              email,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            if (lastLogin != null && lastLogin!.isNotEmpty)
              Text(
                "Last Login: $lastLogin",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        trailing: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          children: [
            Switch(
              value: isActive,
              onChanged: (_) => onToggle(),
              activeColor: const Color(0xFF2196F3),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.grey),
              tooltip: 'Edit Manager',
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              tooltip: 'Delete Manager',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
