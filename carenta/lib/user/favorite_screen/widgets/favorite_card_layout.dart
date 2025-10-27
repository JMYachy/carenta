import 'package:flutter/material.dart';

enum FavoriteCardLayout { grid, list }

class FavoriteCarCard extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final int pricePerDay;
  final int seats;
  final String transmission;
  final bool withDriver;
  final double rating;
  final List<String> tags;
  final bool isFavorite;
  final FavoriteCardLayout layout;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onTap;

  const FavoriteCarCard({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.pricePerDay,
    required this.seats,
    required this.transmission,
    required this.withDriver,
    required this.rating,
    required this.tags,
    required this.isFavorite,
    required this.layout,
    this.onFavoriteTap,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child:
          layout == FavoriteCardLayout.grid
              ? _GridCard(
                title: title,
                imageUrl: imageUrl,
                pricePerDay: pricePerDay,
                seats: seats,
                transmission: transmission,
                withDriver: withDriver,
                rating: rating,
                tags: tags,
                isFavorite: isFavorite,
                onFavoriteTap: onFavoriteTap,
              )
              : _ListCard(
                title: title,
                imageUrl: imageUrl,
                pricePerDay: pricePerDay,
                seats: seats,
                transmission: transmission,
                withDriver: withDriver,
                rating: rating,
                tags: tags,
                isFavorite: isFavorite,
                onFavoriteTap: onFavoriteTap,
              ),
    );
  }
}

/* ---------------- GRID CARD ---------------- */

class _GridCard extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final int pricePerDay;
  final int seats;
  final String transmission;
  final bool withDriver;
  final double rating;
  final List<String> tags;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;

  const _GridCard({
    required this.title,
    required this.imageUrl,
    required this.pricePerDay,
    required this.seats,
    required this.transmission,
    required this.withDriver,
    required this.rating,
    required this.tags,
    required this.isFavorite,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image section – expands to take available space
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child:
                        imageUrl == null || imageUrl!.isEmpty
                            ? Container(
                              color: cs.surfaceContainerHighest,
                              alignment: Alignment.center,
                              child: const Icon(Icons.directions_car, size: 40),
                            )
                            : Image.network(
                              imageUrl!.startsWith('http')
                                  ? imageUrl!
                                  : 'https://carentaph.com/$imageUrl',
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) => Container(
                                    color: cs.surfaceContainerHighest,
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.directions_car,
                                      size: 40,
                                    ),
                                  ),
                            ),
                  ),
                ),
                // Favorite icon
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.white.withOpacity(0.85),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onFavoriteTap,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 20,
                          color: isFavorite ? Colors.red : cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content section
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
            ).copyWith(top: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // Rating + Price
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Flexible(
                      child: Text(
                        '₱${pricePerDay.toString()}/day',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Info chips – Wrap avoids horizontal overflow
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _buildChips(cs),
                  ),
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildChips(ColorScheme cs) {
    final baseStyle = BoxDecoration(
      color: cs.surfaceVariant.withOpacity(0.45),
      borderRadius: BorderRadius.circular(8),
    );

    // Limit to max 3 chips in grid to avoid overflow
    final limited = <String>[
      withDriver ? 'With driver' : 'Self-drive',
      transmission,
      '$seats seats',
      ...tags, // if tags has extra, Wrap will handle or they’ll be dropped by limit
    ].where((e) => e.trim().isNotEmpty).take(3);

    return limited
        .map(
          (t) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: baseStyle,
            child: Text(
              t,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: cs.onSurface, fontSize: 11),
            ),
          ),
        )
        .toList();
  }
}

/* ---------------- LIST CARD ---------------- */

class _ListCard extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final int pricePerDay;
  final int seats;
  final String transmission;
  final bool withDriver;
  final double rating;
  final List<String> tags;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;

  const _ListCard({
    required this.title,
    required this.imageUrl,
    required this.pricePerDay,
    required this.seats,
    required this.transmission,
    required this.withDriver,
    required this.rating,
    required this.tags,
    required this.isFavorite,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(16),
            ),
            child: SizedBox(
              width: 120,
              height: 100,
              child:
                  imageUrl == null || imageUrl!.isEmpty
                      ? Container(
                        color: cs.surfaceContainerHighest,
                        alignment: Alignment.center,
                        child: const Icon(Icons.directions_car, size: 36),
                      )
                      : Image.network(
                        imageUrl!.startsWith('http')
                            ? imageUrl!
                            : 'https://carentaph.com/$imageUrl',
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => Container(
                              color: cs.surfaceContainerHighest,
                              alignment: Alignment.center,
                              child: const Icon(Icons.directions_car, size: 36),
                            ),
                      ),
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title + heart
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: onFavoriteTap,
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : cs.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Rating + price
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '₱$pricePerDay/day',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _chip(cs, withDriver ? 'With driver' : 'Self-drive'),
                      _chip(cs, transmission),
                      _chip(cs, '$seats seats'),
                      ...tags.take(2).map((t) => _chip(cs, t)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(ColorScheme cs, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: cs.surfaceVariant.withOpacity(0.45),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: cs.onSurface, fontSize: 11),
    ),
  );
}
