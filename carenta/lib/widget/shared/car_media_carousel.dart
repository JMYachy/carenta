import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';

/// 🚗 CarMediaCarousel (Enhanced)
/// Handles images + videos with smart autoplay:
/// ✅ Pauses auto-scroll while a video plays
/// ✅ Resumes after it ends
/// ✅ User can swipe anytime to skip
class CarMediaCarousel extends StatefulWidget {
  final List<String> mediaUrls;
  final bool editable;
  final Function(List<File>)? onImagesAdded;
  final Function(File)? onVideoAdded;
  final bool autoPlay;
  final Duration autoPlayInterval;

  const CarMediaCarousel({
    super.key,
    required this.mediaUrls,
    this.editable = false,
    this.onImagesAdded,
    this.onVideoAdded,
    this.autoPlay = true,
    this.autoPlayInterval = const Duration(seconds: 5),
  });

  @override
  State<CarMediaCarousel> createState() => _CarMediaCarouselState();
}

class _CarMediaCarouselState extends State<CarMediaCarousel> {
  final PageController _pageController = PageController();
  final ImagePicker _picker = ImagePicker();

  int _currentIndex = 0;
  VideoPlayerController? _videoController;
  Timer? _autoPlayTimer;
  bool _loadingMedia = true;
  bool _videoError = false;

  @override
  void initState() {
    super.initState();
    _initMedia();
    _startAutoPlay();
  }

  @override
  void didUpdateWidget(covariant CarMediaCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mediaUrls != oldWidget.mediaUrls) {
      _currentIndex = 0;
      _disposeVideo();
      _initMedia();
      _restartAutoPlay();
    }
  }

  @override
  void dispose() {
    _disposeVideo();
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // 🧩 Helper: check if it's a video file
  bool _isVideo(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv') ||
        lower.contains('/videos/');
  }

  // 🔄 Initialize current media (for video)
  Future<void> _initMedia() async {
    if (widget.mediaUrls.isEmpty) return;
    final url = widget.mediaUrls[_currentIndex];
    _loadingMedia = true;
    _videoError = false;
    setState(() {});

    if (_isVideo(url)) {
      try {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
        await _videoController!.initialize().timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw TimeoutException("Video load timeout");
          },
        );
        _videoController!.setLooping(false);
        if (widget.autoPlay) _videoController!.play();

        // 🎬 Manage autoplay while video plays
        _videoController!.addListener(() {
          if (!mounted) return;
          final vc = _videoController!;
          final playing = vc.value.isPlaying;

          if (playing) {
            _pauseAutoPlay(); // pause timer while playing
          }

          // Resume auto-play once video completes
          if (!playing &&
              vc.value.position >= vc.value.duration &&
              vc.value.duration != Duration.zero) {
            Future.delayed(const Duration(seconds: 2), _restartAutoPlay);
          }
        });
      } catch (e) {
        debugPrint("⚠️ Video load failed: $e");
        _videoError = true;
      }
    }
    _loadingMedia = false;
    if (mounted) setState(() {});
  }

  void _disposeVideo() {
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;
  }

  // 🕒 Auto-play loop between media
  void _startAutoPlay() {
    if (!widget.autoPlay || widget.mediaUrls.length <= 1) return;

    _autoPlayTimer = Timer.periodic(widget.autoPlayInterval, (_) {
      if (!mounted || !_pageController.hasClients) return;

      // Skip advancing if a video is currently playing
      if (_videoController != null && _videoController!.value.isPlaying) return;

      final next = (_currentIndex + 1) % widget.mediaUrls.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void _pauseAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
  }

  void _restartAutoPlay() {
    _autoPlayTimer?.cancel();
    _startAutoPlay();
  }

  // 📸 Pickers
  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 85);
    if (picked.isNotEmpty && widget.onImagesAdded != null) {
      widget.onImagesAdded!(picked.map((x) => File(x.path)).toList());
    }
  }

  Future<void> _pickVideo() async {
    final picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked != null && widget.onVideoAdded != null) {
      widget.onVideoAdded!(File(picked.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaCount = widget.mediaUrls.length;

    if (mediaCount == 0 && !widget.editable) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey.shade100,
        ),
        alignment: Alignment.center,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 50,
              color: Colors.grey,
            ),
            SizedBox(height: 8),
            Text("No media available", style: TextStyle(color: Colors.black54)),
          ],
        ),
      );
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 220,
                width: double.infinity,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: mediaCount,
                  onPageChanged: (i) async {
                    _disposeVideo();
                    setState(() => _currentIndex = i);
                    await _initMedia();
                  },
                  itemBuilder: (context, index) {
                    final url = widget.mediaUrls[index];
                    final isVideo = _isVideo(url);

                    if (isVideo) {
                      if (_videoError) {
                        return _buildErrorPlaceholder("Video failed to load");
                      }
                      final vc = _videoController;
                      if (vc == null || !vc.value.isInitialized) {
                        return _buildLoadingPlaceholder();
                      }
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            vc.value.isPlaying ? vc.pause() : vc.play();
                          });
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AspectRatio(
                              aspectRatio: vc.value.aspectRatio,
                              child: VideoPlayer(vc),
                            ),
                            if (!vc.value.isPlaying)
                              Container(
                                color: Colors.black26,
                                child: const Icon(
                                  Icons.play_circle_fill,
                                  color: Colors.white,
                                  size: 64,
                                ),
                              ),
                          ],
                        ),
                      );
                    } else {
                      return Image.network(
                        url,
                        fit: BoxFit.cover,
                        loadingBuilder: (ctx, child, progress) {
                          if (progress == null) return child;
                          return _buildLoadingPlaceholder();
                        },
                        errorBuilder:
                            (_, __, ___) =>
                                _buildErrorPlaceholder("Image failed to load"),
                      );
                    }
                  },
                ),
              ),

              // 🔢 Media counter
              if (mediaCount > 0)
                Positioned(
                  bottom: 8,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / $mediaCount',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),

              // 🔄 Loading spinner overlay
              if (_loadingMedia)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black26,
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        if (widget.editable)
          Wrap(
            spacing: 10,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.image_outlined),
                label: const Text("Add Images"),
              ),
              OutlinedButton.icon(
                onPressed: _pickVideo,
                icon: const Icon(Icons.video_library_outlined),
                label: const Text("Add Video"),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
    );
  }

  Widget _buildErrorPlaceholder(String message) {
    return Container(
      color: Colors.grey.shade100,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
