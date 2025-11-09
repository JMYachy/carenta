import 'package:flutter/material.dart';

class BookingFeedbackSection extends StatelessWidget {
  final int rating;
  final Function(int) onRatingChange;
  final TextEditingController titleController;
  final TextEditingController commentController;
  final VoidCallback onSubmit;

  const BookingFeedbackSection({
    super.key,
    required this.rating,
    required this.onRatingChange,
    required this.titleController,
    required this.commentController,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rate & Review',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: List.generate(5, (i) {
                final filled = i < rating;
                return IconButton(
                  icon: Icon(
                    filled ? Icons.star_rounded : Icons.star_border_rounded,
                    color: filled ? Colors.amber : Colors.grey,
                  ),
                  onPressed: () => onRatingChange(i + 1),
                );
              }),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Review Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Your Review',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                minimumSize: const Size.fromHeight(45),
              ),
              onPressed: onSubmit,
              icon: const Icon(Icons.save_rounded, color: Colors.white),
              label: const Text('Submit Feedback',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
