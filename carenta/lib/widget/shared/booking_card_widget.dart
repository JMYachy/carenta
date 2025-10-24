import 'package:carenta/service/config/service_base_url.dart';
import 'package:flutter/material.dart';

/// ✅ A shared, reusable widget to display a booking card for any user type.
/// Used in UserBookingScreen, AdminBookingList, etc.
class BookingCardWidget extends StatelessWidget {
  final String title; // e.g., "Toyota HiAce 2022"
  final String subtitle; // e.g., "Aug 25, 9:00 AM — Aug 27, 9:00 AM"
  final String badge; // e.g., "COMPLETED"
  final String footnote; // e.g., "Self-drive • Plate: ABC-1234"
  final String? imageUrl; // Optional thumbnail
  final VoidCallback? onTap; // Optional tap action

  const BookingCardWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.footnote,
    this.imageUrl,
    this.onTap,
  });

  /// 🧠 Factory: Create directly from API data (e.g., from user_bookings.php)
  factory BookingCardWidget.fromApi(
    Map<String, dynamic> r, {
    VoidCallback? onTap,
  }) {
    String title = _composeTitle(r);
    String subtitle = _composeSubtitle(r);
    String badge = (r['status'] ?? 'pending').toString().toUpperCase();
    String withDriver = (r['rental_type'] ?? 'self-drive')
        .toString()
        .replaceAll('-', ' ');
    String plate = (r['license_plate'] ?? 'TBA').toString();
    String footnote = '$withDriver • Plate: $plate';

    // 🔍 Handle multiple possible image fields from API
    String? imageUrl =
        (r['thumbnail_url'] ??
                r['media_url'] ??
                r['image_url'] ??
                r['car_image'])
            ?.toString();

    // 🧠 Auto-prepend correct base path if it's a relative URL
    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (!imageUrl.startsWith('http')) {
        imageUrl = ServiceBaseUrl.file(imageUrl); // ✅ use file() not endpoint()
      }
    }

    // Debug check (optional)
    // print('🖼️ Final image URL: $imageUrl');

    return BookingCardWidget(
      title: title,
      subtitle: subtitle,
      badge: badge,
      footnote: footnote,
      imageUrl: (imageUrl != null && imageUrl.isNotEmpty) ? imageUrl : null,
      onTap: onTap,
    );
  }

  static String _composeTitle(Map<String, dynamic> r) {
    final manufacturer = (r['manufacturer'] ?? '').toString().trim();
    final model = (r['model'] ?? '').toString().trim();
    final combined = [manufacturer, model].where((e) => e.isNotEmpty).join(' ');
    if (combined.isNotEmpty) return combined;
    final carId = r['carid'] ?? r['car_id'] ?? '-';
    return 'Car #$carId';
  }

  static String _composeSubtitle(Map<String, dynamic> r) {
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
    final card = Card(
      elevation: 0.8,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _Thumbnail(imageUrl: imageUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _StatusBadge(text: badge),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          footnote,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
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

    if (onTap != null) {
      return InkWell(onTap: onTap, child: card);
    }
    return card;
  }
}

/// 🖼️ Image / thumbnail widget
class _Thumbnail extends StatelessWidget {
  final String? imageUrl;
  const _Thumbnail({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final border = BorderRadius.circular(10);
    return ClipRRect(
      borderRadius: border,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: Border.all(color: Colors.black12),
        ),
        child:
            (imageUrl == null || imageUrl!.isEmpty)
                ? const Icon(Icons.directions_car, size: 28)
                : Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) =>
                          const Icon(Icons.directions_car, size: 28),
                ),
      ),
    );
  }
}

/// 🏷️ Status badge (CONFIRMED / COMPLETED / CANCELLED etc.)
class _StatusBadge extends StatelessWidget {
  final String text;
  const _StatusBadge({required this.text});

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
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
          letterSpacing: .4,
        ),
      ),
    );
  }
}
