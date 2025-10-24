import 'package:carenta/service/config/service_base_url.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class CarImageCarousel extends StatefulWidget {
  final dynamic imageData; // Can be List or String
  const CarImageCarousel({super.key, this.imageData});

  @override
  State<CarImageCarousel> createState() => _CarImageCarouselState();
}

class _CarImageCarouselState extends State<CarImageCarousel> {
  int _current = 0;
  late final List<String> _imageUrls;

  @override
  void initState() {
    super.initState();
    _imageUrls = _extractImages(widget.imageData);
  }

  /// ✅ Safely extract list of image URLs from any data type
  List<String> _extractImages(dynamic data) {
    final List<String> urls = [];

    if (data is List) {
      for (var item in data) {
        if (item is Map && item['media_url'] != null) {
          urls.add(_fixUrl(item['media_url']));
        } else if (item is String) {
          urls.add(_fixUrl(item));
        }
      }
    } else if (data is String && data.isNotEmpty) {
      urls.add(_fixUrl(data));
    }

    if (urls.isEmpty) {
      urls.add(''); // placeholder
    }

    return urls;
  }

  /// ✅ Make URL absolute and correct
  String _fixUrl(dynamic url) {
    if (url == null) return '';
    final u = url.toString().trim();
    if (u.isEmpty) return '';
    if (u.startsWith('http')) return u;
    return ServiceBaseUrl.file(u);
  }

  @override
  Widget build(BuildContext context) {
    final total = _imageUrls.length;

    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        // 🖼️ Main carousel
        CarouselSlider(
          items:
              _imageUrls.map((url) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.grey[200],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child:
                      (url.isEmpty)
                          ? _buildPlaceholder()
                          : Image.network(
                            url,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) => _buildPlaceholder(),
                          ),
                );
              }).toList(),
          options: CarouselOptions(
            height: 220,
            viewportFraction: 1.0,
            enableInfiniteScroll: total > 1,
            autoPlay: total > 1,
            onPageChanged: (index, reason) {
              setState(() => _current = index);
            },
          ),
        ),

        // 🧮 Bottom-left image counter
        if (total > 1)
          Positioned(
            bottom: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_current + 1}/$total',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

        // 🟢 Dots indicator (optional, keep for UX)
        if (total > 1)
          Positioned(
            bottom: 10,
            right: 0,
            left: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children:
                  _imageUrls.asMap().entries.map((entry) {
                    return Container(
                      width: 7.0,
                      height: 7.0,
                      margin: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 3.0,
                      ),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            _current == entry.key
                                ? Colors.white
                                : Colors.white.withOpacity(0.4),
                      ),
                    );
                  }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.directions_car, size: 80, color: Colors.white70),
    );
  }
}
