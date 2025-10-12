// lib/widget/car_image_carousel.dart
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class CarImageCarousel extends StatefulWidget {
  final List<String> imageUrls;

  const CarImageCarousel({super.key, required this.imageUrls});

  @override
  State<CarImageCarousel> createState() => _CarImageCarouselState();
}

class _CarImageCarouselState extends State<CarImageCarousel> {
  int _activeIndex = 0;
  final CarouselSliderController _controller = CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 230,
          color: Colors.grey[300],
          child: const Center(child: Icon(Icons.directions_car, size: 80)),
        ),
      );
    }

    return Stack(
      children: [
        CarouselSlider(
          carouselController: _controller,
          items: widget.imageUrls.map((url) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, size: 80),
                  ),
                ),
              ),
            );
          }).toList(),
          options: CarouselOptions(
            height: 230,
            enlargeCenterPage: true,
            viewportFraction: 1.0,
            enableInfiniteScroll: widget.imageUrls.length > 1,
            onPageChanged: (index, _) => setState(() => _activeIndex = index),
          ),
        ),
        if (widget.imageUrls.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.imageUrls.length, (i) {
                final isActive = i == _activeIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 26 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFFF5722)
                        : Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}
