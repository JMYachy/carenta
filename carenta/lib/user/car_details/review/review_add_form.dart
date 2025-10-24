import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:carenta/service/user/review_service.dart';

class ReviewAddForm extends StatefulWidget {
  final int carId;
  final int userId;
  final VoidCallback onSubmitted;

  const ReviewAddForm({
    super.key,
    required this.carId,
    required this.userId,
    required this.onSubmitted,
  });

  @override
  State<ReviewAddForm> createState() => _ReviewAddFormState();
}

class _ReviewAddFormState extends State<ReviewAddForm> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  int _rating = 0;
  File? _mediaFile;
  bool _loading = false;

  Future<void> _pickMedia() async {
    final picker = ImagePicker();
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder:
          (_) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.image),
                  title: const Text('Pick Image'),
                  onTap: () => Navigator.pop(context, 'image'),
                ),
                ListTile(
                  leading: const Icon(Icons.videocam),
                  title: const Text('Pick Video'),
                  onTap: () => Navigator.pop(context, 'video'),
                ),
              ],
            ),
          ),
    );
    if (choice == null) return;

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (picked != null) {
      setState(() => _mediaFile = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final res = await ReviewService().addReview(
        userId: widget.userId,
        carId: widget.carId,
        rating: _rating,
        comment: _commentController.text.trim(),
        mediaFile: _mediaFile,
      );

      if (res['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Review added')),
        );
        _commentController.clear();
        _rating = 0;
        _mediaFile = null;
        widget.onSubmitted();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Error')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Write a Review',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Row(
              children: List.generate(
                5,
                (i) => IconButton(
                  icon: Icon(
                    i < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: () => setState(() => _rating = i + 1),
                ),
              ),
            ),
            TextFormField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Share your experience...',
                filled: true,
              ),
              maxLines: 3,
              validator:
                  (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Please write something'
                          : null,
            ),
            const SizedBox(height: 10),
            if (_mediaFile != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _mediaFile!,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: GestureDetector(
                      onTap: () => setState(() => _mediaFile = null),
                      child: const CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            TextButton.icon(
              onPressed: _pickMedia,
              icon: const Icon(Icons.attach_file, color: Color(0xFFFF5722)),
              label: const Text(
                'Add Image/Video',
                style: TextStyle(color: Color(0xFFFF5722)),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _loading ? null : _submit,
              icon:
                  _loading
                      ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.send, size: 18),
              label: Text(_loading ? 'Submitting...' : 'Submit Review'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5722),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
