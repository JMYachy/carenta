import 'package:flutter/material.dart';
import '../model/manager_dashboard_model.dart';

class DashboardMessagesPreview extends StatelessWidget {
  final List<DashboardMessage> messages;
  const DashboardMessagesPreview({super.key, required this.messages});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recent Messages',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            if (messages.isEmpty)
              const Text('No unread messages',
                  style: TextStyle(color: Colors.grey))
            else
              Column(
                children: messages
                    .take(3)
                    .map((m) => ListTile(
                          leading: const Icon(Icons.message, color: Colors.blue),
                          title: Text(m.username),
                          subtitle: Text(m.snippet,
                              overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}
