import 'package:flutter/material.dart';

class ReviewBottomSheet extends StatefulWidget {
  final String carTitle;

  const ReviewBottomSheet({super.key, required this.carTitle});

  @override
  State<ReviewBottomSheet> createState() => _ReviewBottomSheetState();
}

class _ReviewBottomSheetState extends State<ReviewBottomSheet> {
  double _rating = 5.0;
  final _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 250)); // tiny UX pause
    if (!mounted) return;
    Navigator.pop(context, ReviewResult(rating: _rating.round(), comment: _controller.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, controller) {
          return SingleChildScrollView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // drag handle
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),

                Text(
                  'Rate your rental',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(widget.carTitle, style: Theme.of(context).textTheme.labelLarge),

                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.star_rate_rounded, size: 28),
                    Expanded(
                      child: Slider(
                        value: _rating,
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: _rating.toStringAsFixed(0),
                        onChanged: (v) => setState(() => _rating = v),
                      ),
                    ),
                    Text(_rating.toStringAsFixed(0), style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),

                const SizedBox(height: 12),
                TextField(
                  controller: _controller,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Share your experience',
                    hintText: 'What went well? What can be improved?',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Submit Review'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ReviewResult {
  final int rating;
  final String comment;
  const ReviewResult({required this.rating, required this.comment});
}
