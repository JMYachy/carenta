import 'package:flutter/material.dart';

class ChatListTile extends StatelessWidget {
  final String leadingLetter;
  final String title;
  final String subtitle;
  final int unread;
  final VoidCallback onTap;

  const ChatListTile({
    super.key,
    required this.leadingLetter,
    required this.title,
    required this.subtitle,
    required this.unread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: const Color(0xFF90E0EF),
        child: Text(
          leadingLetter,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing:
          unread > 0
              ? Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$unread',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              )
              : null,
      onTap: onTap,
    );
  }
}
