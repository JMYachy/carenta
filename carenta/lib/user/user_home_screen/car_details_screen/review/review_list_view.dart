import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ReviewListView extends StatelessWidget {
  final List<Map<String, dynamic>> reviews;
  const ReviewListView({super.key, required this.reviews});

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return const Text(
        "No reviews yet. Be the first to review!",
        style: TextStyle(color: Colors.black54),
      );
    }

    return Column(
      children: reviews.map((r) => _ReviewCard(review: r)).toList(),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final username = review['username'] ?? 'User';
    final comment = review['comment'] ?? '';
    final rating = int.tryParse('${review['rating'] ?? 0}') ?? 0;
    final mediaUrl = review['media_url'];
    final isVideo = mediaUrl?.toString().endsWith('.mp4') ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(child: Icon(Icons.person)),
              const SizedBox(width: 10),
              Text(
                username,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Row(
                children: List.generate(
                  rating,
                  (_) => const Icon(Icons.star, color: Colors.amber, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(comment, style: const TextStyle(fontSize: 14)),
          if (mediaUrl != null && mediaUrl.toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                    isVideo
                        ? _VideoThumbnail(url: mediaUrl)
                        : Image.network(mediaUrl, fit: BoxFit.cover),
              ),
            ),
        ],
      ),
    );
  }
}

class _VideoThumbnail extends StatefulWidget {
  final String url;
  const _VideoThumbnail({required this.url});

  @override
  State<_VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<_VideoThumbnail> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.url)
      ..initialize().then((_) {
        if (mounted) setState(() {});
      });
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio:
          _controller.value.isInitialized
              ? _controller.value.aspectRatio
              : 16 / 9,
      child:
          _controller.value.isInitialized
              ? VideoPlayer(_controller)
              : const Center(child: CircularProgressIndicator()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
