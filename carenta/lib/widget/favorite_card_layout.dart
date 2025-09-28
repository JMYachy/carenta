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

  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;

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
    this.layout = FavoriteCardLayout.grid,
    this.onTap,
    this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    switch (layout) {
      case FavoriteCardLayout.list:
        return _buildList(context);
      case FavoriteCardLayout.grid:
      return _buildGrid(context);
    }
  }

  Widget _buildGrid(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0.8,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Thumb(imageUrl: imageUrl, isFavorite: isFavorite, onFav: onFavoriteTap),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: Row(
                children: [
                  Icon(Icons.star_rounded, size: 18, color: scheme.tertiary),
                  const SizedBox(width: 4),
                  Text('$rating', style: Theme.of(context).textTheme.bodySmall),
                  const Spacer(),
                  Text('₱$pricePerDay/day',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: Row(
                children: [
                  _Spec(icon: Icons.event_seat_rounded, text: '${seats}p'),
                  const SizedBox(width: 10),
                  _Spec(icon: Icons.settings_rounded, text: transmission),
                  const SizedBox(width: 10),
                  _Spec(icon: Icons.person_rounded, text: withDriver ? 'Driver' : 'Self'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0.8,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 112,
          child: Row(
            children: [
              _Thumb(
                imageUrl: imageUrl,
                isFavorite: isFavorite,
                onFav: onFavoriteTap,
                width: 128,
                height: 112,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.star_rounded, size: 18, color: scheme.tertiary),
                          const SizedBox(width: 4),
                          Text('$rating', style: Theme.of(context).textTheme.bodySmall),
                          const Spacer(),
                          Text('₱$pricePerDay/day',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const Spacer(),
                      Wrap(
                        spacing: 6,
                        runSpacing: -6,
                        children: [
                          _Spec(icon: Icons.event_seat_rounded, text: '${seats}p'),
                          _Spec(icon: Icons.settings_rounded, text: transmission),
                          _Spec(icon: Icons.person_rounded, text: withDriver ? 'Driver' : 'Self'),
                          for (final t in tags.take(3)) _Tag(text: t),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ---------- sub-widgets ---------- */

class _Thumb extends StatelessWidget {
  final String? imageUrl;
  final bool isFavorite;
  final VoidCallback? onFav;
  final double width, height;
  final BorderRadius? borderRadius;

  const _Thumb({
    required this.imageUrl,
    required this.isFavorite,
    required this.onFav,
    this.width = double.infinity,
    this.height = 140,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final border = borderRadius ?? const BorderRadius.vertical(top: Radius.circular(16));
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        ClipRRect(
          borderRadius: border,
          child: Container(
            width: width,
            height: height,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: (imageUrl == null || imageUrl!.isEmpty)
                ? const Icon(Icons.directions_car, size: 32)
                : Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.directions_car, size: 32),
                  ),
          ),
        ),
        Positioned(
          right: 8,
          top: 8,
          child: InkWell(
            onTap: onFav,
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFavorite ? scheme.primary : scheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Spec extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Spec({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(text, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  const _Tag({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: cs.onPrimaryContainer,
          letterSpacing: .3,
        ),
      ),
    );
  }
}
