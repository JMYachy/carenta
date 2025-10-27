import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:carenta/service/user/review_service.dart';

class BookingAddReviewSection extends StatefulWidget {
  final int carId;
  final int userId;
  final VoidCallback? onSubmitted;

  const BookingAddReviewSection({
    super.key,
    required this.carId,
    required this.userId,
    this.onSubmitted,
  });

  @override
  State<BookingAddReviewSection> createState() =>
      _BookingAddReviewSectionState();
}

class _BookingAddReviewSectionState extends State<BookingAddReviewSection> {
  final _reviewService = ReviewService();
  final _commentCtrl = TextEditingController();
  final _picker = ImagePicker();

  int _rating = 0;
  bool _submitting = false;
  File? _mediaFile;

  Future<void> _pickMedia() async {
    final picked = await showModalBottomSheet<XFile?>(
      context: context,
      builder:
          (_) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text("Select Image"),
                  onTap: () async {
                    final img = await _picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    Navigator.pop(context, img);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.videocam_rounded),
                  title: const Text("Select Video"),
                  onTap: () async {
                    final vid = await _picker.pickVideo(
                      source: ImageSource.gallery,
                    );
                    Navigator.pop(context, vid);
                  },
                ),
              ],
            ),
          ),
    );

    if (picked != null) {
      setState(() => _mediaFile = File(picked.path));
    }
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select a rating")));
      return;
    }

    if (_commentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add a short review comment")),
      );
      return;
    }

    setState(() => _submitting = true);

    final result = await _reviewService.addReview(
      userId: widget.userId,
      carId: widget.carId,
      rating: _rating,
      comment: _commentCtrl.text.trim(),
      mediaFile: _mediaFile,
    );

    setState(() => _submitting = false);

    if (!mounted) return;

    final success = result['status'] == 'success';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['message'] ??
              (success ? "Review added!" : "Failed to add review"),
        ),
        backgroundColor: success ? Colors.green : Colors.redAccent,
      ),
    );

    if (success && widget.onSubmitted != null) {
      widget.onSubmitted!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Add a Review",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Rate your experience with this car",
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 10),

          // ⭐ Star Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: List.generate(5, (index) {
              final i = index + 1;
              return IconButton(
                icon: Icon(
                  i <= _rating ? Icons.star_rounded : Icons.star_border_rounded,
                  color: Colors.amber,
                  size: 30,
                ),
                onPressed: () => setState(() => _rating = i),
              );
            }),
          ),

          const SizedBox(height: 8),

          // 🗒️ Comment box
          TextField(
            controller: _commentCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Write your review here...",
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 📸 Media Picker
          if (_mediaFile != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[200],
              ),
              clipBehavior: Clip.antiAlias,
              child:
                  _mediaFile!.path.endsWith('.mp4')
                      ? const Center(
                        child: Icon(
                          Icons.videocam_rounded,
                          color: Colors.black54,
                          size: 60,
                        ),
                      )
                      : Image.file(
                        _mediaFile!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
            ),

          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _pickMedia,
                icon: const Icon(Icons.attach_file_rounded, size: 18),
                label: const Text("Attach Photo/Video"),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _submitting ? null : _submitReview,
                icon: const Icon(Icons.send_rounded, size: 18),
                label: Text(_submitting ? "Submitting..." : "Submit Review"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5722),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }
}
