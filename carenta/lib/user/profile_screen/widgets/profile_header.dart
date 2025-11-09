import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final String? avatarUrl;

  const ProfileHeader({
    super.key,
    required this.name,
    required this.email,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage:
              (avatarUrl != null && avatarUrl!.isNotEmpty)
                  ? NetworkImage(avatarUrl!)
                  : null,
          child:
              (avatarUrl == null || avatarUrl!.isEmpty)
                  ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: const TextStyle(fontSize: 36),
                  )
                  : null,
        ),
        const SizedBox(height: 12),
        Text(
          name.isEmpty ? 'User' : name,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(email, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}
