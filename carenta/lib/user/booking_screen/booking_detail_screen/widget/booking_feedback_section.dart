import 'package:flutter/material.dart';

class BookingFeedbackSection extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onRatingChange;
  final TextEditingController commentController;
  final VoidCallback onSubmit;

  const BookingFeedbackSection({
    super.key,
    required this.rating,
    required this.onRatingChange,
    required this.commentController,
    required this.onSubmit,
  });

  static const _minChars = 10;
  static const _maxChars = 500;

  String _ratingLabel(int v) {
    switch (v) {
      case 1:
        return 'Terrible';
      case 2:
        return 'Poor';
      case 3:
        return 'Okay';
      case 4:
        return 'Good';
      case 5:
        return 'Excellent';
      default:
        return 'Select a rating';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hintStyle = theme.textTheme.bodySmall?.copyWith(color: Colors.grey);

    final quickTags = <String>[
      'Clean car',
      'Friendly staff',
      'On-time pickup',
      'Smooth process',
      'Great value',
      'Would rent again',
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              rating > 0
                  ? Colors.blueAccent.withOpacity(0.4)
                  : Colors.grey.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: commentController,
          builder: (context, value, _) {
            final comment = value.text.trim();
            final canSubmit = rating > 0 && comment.length >= _minChars;
            final remaining = _maxChars - value.text.length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rate & Review',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                // ⭐ Stars + label
                Row(
                  children: [
                    ...List.generate(5, (i) {
                      final filled = i < rating;
                      return IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        iconSize: 30,
                        icon: Icon(
                          filled
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: filled ? Colors.amber : Colors.grey,
                        ),
                        onPressed: () => onRatingChange(i + 1),
                      );
                    }),
                    const SizedBox(width: 8),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 150),
                      style: theme.textTheme.bodyMedium!.copyWith(
                        color: rating > 0 ? Colors.black87 : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                      child: Text(_ratingLabel(rating)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 💬 Quick reaction chips
                Wrap(
                  spacing: 8,
                  runSpacing: -6,
                  children:
                      quickTags.map((t) {
                        return ActionChip(
                          label: Text(t),
                          onPressed: () {
                            final text = commentController.text;
                            final needsSpace =
                                text.isNotEmpty && !text.endsWith(' ');
                            final append = needsSpace ? ' $t' : t;
                            if (text.length + append.length <= _maxChars) {
                              commentController.text =
                                  text.isEmpty ? t : '$text$append';
                              commentController
                                  .selection = TextSelection.fromPosition(
                                TextPosition(
                                  offset: commentController.text.length,
                                ),
                              );
                            }
                          },
                        );
                      }).toList(),
                ),
                const SizedBox(height: 10),

                // ✍️ Comment box
                TextField(
                  controller: commentController,
                  maxLines: 5,
                  maxLength: _maxChars,
                  decoration: InputDecoration(
                    labelText: 'Share your experience',
                    hintText: 'What did you like? What could be improved?',
                    border: const OutlineInputBorder(),
                    helperText:
                        remaining < (_maxChars - 60)
                            ? '$_minChars+ characters • $remaining left'
                            : '$_minChars+ characters',
                    helperStyle: hintStyle,
                  ),
                ),

                const SizedBox(height: 6),
                Text(
                  'Your review helps others make better choices.',
                  style: hintStyle,
                ),

                const SizedBox(height: 12),

                // ✅ Submit button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        canSubmit ? Colors.blueAccent : Colors.grey.shade400,
                    minimumSize: const Size.fromHeight(45),
                    elevation: canSubmit ? 2 : 0,
                  ),
                  onPressed: canSubmit ? onSubmit : null,
                  icon: const Icon(Icons.save_rounded, color: Colors.white),
                  label: const Text(
                    'Submit Feedback',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
