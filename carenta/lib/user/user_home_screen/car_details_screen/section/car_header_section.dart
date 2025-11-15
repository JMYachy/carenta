import 'package:carenta/widget/shared/car_media_carousel.dart';
import 'package:flutter/material.dart';
import 'package:carenta/service/config/service_base_url.dart';

class CarHeaderSection extends StatelessWidget {
  final Map<String, dynamic> car;
  final bool editable;
  const CarHeaderSection({super.key, required this.car, this.editable = false});

  // Merge images + videos into a single list
  List<String> _collectMedia(Map<String, dynamic> car) {
    final urls = <String>[];

    String _resolve(dynamic v) {
      if (v == null) return '';
      final s = v.toString().trim();
      if (s.isEmpty) return '';
      // Make relative paths absolute
      return ServiceBaseUrl.file(s);
    }

    void add(dynamic v) {
      final u = _resolve(v);
      if (u.isNotEmpty) urls.add(u);
    }

    // IMAGES
    // 1) media: [ { media_url, thumbnail_url, media_type }, ... ] or [string]
    if (car['media'] is List) {
      for (final m in (car['media'] as List)) {
        if (m is Map) {
          add(m['media_url'] ?? m['url']);
        } else {
          add(m);
        }
      }
    }
    // 2) direct image fields
    add(car['media_url']);
    add(car['thumbnail_url']);
    add(car['image_url']);

    // VIDEOS
    // 1) videos: [ { media_url }, ... ] or [string]
    if (car['videos'] is List) {
      for (final v in (car['videos'] as List)) {
        if (v is Map) {
          add(v['media_url'] ?? v['url']);
        } else {
          add(v);
        }
      }
    }
    // 2) direct video field
    add(car['video_url']);

    // de-dupe while keeping order
    final seen = <String>{};
    final merged = <String>[];
    for (final u in urls) {
      if (seen.add(u)) merged.add(u);
    }
    // filter out non-media accidents (e.g. wrong values)
    return merged
        .where((u) {
          final L = u.toLowerCase();
          return L.endsWith('.jpg') ||
              L.endsWith('.jpeg') ||
              L.endsWith('.png') ||
              L.endsWith('.webp') ||
              L.endsWith('.gif') ||
              L.endsWith('.mp4') ||
              L.endsWith('.mov') ||
              L.endsWith('.webm') ||
              L.contains('/uploads/videos/');
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final mediaList = _collectMedia(car);

    final manufacturer = (car['manufacturer'] ?? '').toString();
    final model = (car['model'] ?? '').toString();
    final year = (car['year'] ?? '').toString();
    final plate = (car['license_plate'] ?? '').toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CarMediaCarousel(
          mediaUrls: mediaList,
          editable: editable, // show add buttons if you want
        ),
        const SizedBox(height: 16),
        Text(
          '$manufacturer $model${year.isNotEmpty ? ' ($year)' : ''}',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        if (plate.isNotEmpty)
          Text('Plate: $plate', style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}
