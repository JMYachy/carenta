import 'package:flutter/material.dart';
import '../model/manager_dashboard_model.dart';

class DashboardFeedbackPreview extends StatelessWidget {
  final List<DashboardFeedback> feedback;
  const DashboardFeedbackPreview({super.key, required this.feedback});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recent Feedback',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            if (feedback.isEmpty)
              const Text('No feedback received yet',
                  style: TextStyle(color: Colors.grey))
            else
              Column(
                children: feedback
                    .take(3)
                    .map((f) => ListTile(
                          leading:
                              const Icon(Icons.star, color: Colors.amber),
                          title: Text(f.username),
                          subtitle: Text(f.comment,
                              overflow: TextOverflow.ellipsis),
                          trailing: Text('${f.rating}★'),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}
