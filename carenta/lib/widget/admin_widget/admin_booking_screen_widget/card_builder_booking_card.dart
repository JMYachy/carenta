// lib/widget/booking_card.dart
import 'package:flutter/material.dart';

class CardbuilderBookingcard extends StatelessWidget {
  final String title;          // e.g., "Toyota HiAce 2022"
  final String subtitle;       // e.g., "Aug 25, 9:00 AM — Aug 27, 9:00 AM"
  final String badge;          // e.g., "CONFIRMED"
  final String footnote;       // e.g., "Self-drive • Plate: ABC-1234"
  final String? imageUrl;      // optional thumbnail

  const CardbuilderBookingcard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.footnote,
    this.imageUrl,
  });

  /// New: build directly from the API row returned by user_bookings.php
  /// Expected keys (from our PHP): manufacturer, model, date_range OR
  /// start_date/start_time/end_date/end_time, status, rental_type, license_plate,
  /// thumbnail_url/media_url.
  factory CardbuilderBookingcard.fromApi(Map<String, dynamic> r) {
    String title = _composeTitle(r);
    String subtitle = _composeSubtitle(r);
    String badge = (r['status'] ?? 'pending').toString().toUpperCase();
    String withDriver = (r['rental_type'] ?? 'self-drive').toString().replaceAll('-', ' ');
    String plate = (r['license_plate'] ?? 'TBA').toString();
    String footnote = '$withDriver • Plate: $plate';
    String? imageUrl = (r['thumbnail_url'] ?? r['media_url'])?.toString();

    return CardbuilderBookingcard(
      title: title,
      subtitle: subtitle,
      badge: badge,
      footnote: footnote,
      imageUrl: (imageUrl != null && imageUrl.isNotEmpty) ? imageUrl : null,
    );
  }

  static String _composeTitle(Map<String, dynamic> r) {
    final manufacturer = (r['manufacturer'] ?? '').toString().trim();
    final model = (r['model'] ?? '').toString().trim();
    final combined = [manufacturer, model].where((e) => e.isNotEmpty).join(' ');
    if (combined.isNotEmpty) return combined;
    final carId = r['carid'] ?? r['car_id'] ?? '-';
    return 'Car #$carId';
    // Optionally append year if you want:
    // final year = (r['year'] ?? '').toString().trim();
    // return [combined, year].where((e) => e.isNotEmpty).join(' ');
  }

  static String _composeSubtitle(Map<String, dynamic> r) {
    // If backend already provides `date_range`, prefer it.
    final dateRange = (r['date_range'] ?? '').toString().trim();
    if (dateRange.isNotEmpty) return dateRange;

    final sd = (r['start_date'] ?? '').toString();
    final st = (r['start_time'] ?? '').toString();
    final ed = (r['end_date'] ?? '').toString();
    final et = (r['end_time'] ?? '').toString();

    String left = sd + (st.isNotEmpty ? ' $st' : '');
    String right = ed + (et.isNotEmpty ? ' $et' : '');
    final range = [left, right].where((e) => e.trim().isNotEmpty).join(' — ');
    return range.isNotEmpty ? range : 'Dates TBA';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.8,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _Thumb(imageUrl: imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _Badge(text: badge),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            footnote,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            // Fix: Material 3 doesn't have colorScheme.hintColor; use onSurfaceVariant
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final String? imageUrl;
  const _Thumb({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final border = BorderRadius.circular(10);
    return ClipRRect(
      borderRadius: border,
      child: Container(
        width: 80,
        height: 80,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: (imageUrl == null || imageUrl!.isEmpty)
            ? const Icon(Icons.directions_car, size: 28)
            : Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.directions_car),
              ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color bg = scheme.surfaceContainerHighest;
    Color fg = scheme.onSurfaceVariant;

    switch (text.toLowerCase()) {
      case 'confirmed':
      case 'ongoing':
        bg = scheme.primaryContainer;
        fg = scheme.onPrimaryContainer;
        break;
      case 'completed':
        bg = scheme.tertiaryContainer;
        fg = scheme.onTertiaryContainer;
        break;
      case 'cancelled':
        bg = scheme.errorContainer;
        fg = scheme.onErrorContainer;
        break;
      // default: pending/others keep neutral surfaceVariant
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg, letterSpacing: .4),
      ),
    );
  }
}
