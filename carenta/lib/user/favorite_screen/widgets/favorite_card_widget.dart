import 'package:carenta/user/favorite_screen/user_favorite_screen.dart';
import 'package:carenta/user/user_home_screen/car_details_screen/user_car_details_screen.dart';
import 'package:flutter/material.dart';

class FavoriteCardWidget extends StatefulWidget {
  final FavoriteCarModel car;
  final VoidCallback onToggle;
  final VoidCallback? onTap;

  const FavoriteCardWidget({
    super.key,
    required this.car,
    required this.onToggle,
    this.onTap,
  });

  @override
  State<FavoriteCardWidget> createState() => _FavoriteCardWidgetState();
}

class _FavoriteCardWidgetState extends State<FavoriteCardWidget> {
  bool _animatingHeart = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final car = widget.car;

    return Material(
      color: theme.colorScheme.surface,
      elevation: 1.5,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: 16:9 image area
                  _CarImage(imageUrl: car.imageUrl),

                  const SizedBox(width: 12),

                  // Right: details
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4, right: 36), // leave room for heart
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            car.title.isEmpty ? 'Car' : car.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 10,
                            runSpacing: -4,
                            children: [
                              _ChipText(icon: Icons.category_rounded, label: car.type),
                              _ChipText(icon: Icons.settings_suggest_rounded, label: car.transmission),
                              _ChipText(icon: Icons.local_gas_station_rounded, label: car.fuelType),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Text(
                                car.dailyRate != null
                                    ? '₱${car.dailyRate!.toStringAsFixed(0)}/day'
                                    : 'Rate unavailable',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (car.rating != null)
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, size: 18),
                                    const SizedBox(width: 4),
                                    Text(
                                      car.rating!.toStringAsFixed(1),
                                      style: theme.textTheme.labelLarge,
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Heart toggle at top-right of the card (not overlapping the image)
            Positioned(
              top: 6,
              right: 6,
              child: _AnimatedHeartButton(
                animating: _animatingHeart,
                onPressed: () async {
                  setState(() => _animatingHeart = true);
                  await Future.delayed(const Duration(milliseconds: 180));
                  if (mounted) setState(() => _animatingHeart = false);
                  widget.onToggle();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CarImage extends StatelessWidget {
  final String imageUrl;
  const _CarImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    final placeholder = Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.6),
        borderRadius: radius,
      ),
      child: const Center(
        child: Icon(
          Icons.directions_car_filled_rounded,
          size: 36,
        ),
      ),
    );

    // 🧠 Auto-prepend full domain if only relative path given
    String resolvedUrl = imageUrl.trim();
    if (resolvedUrl.isNotEmpty && !resolvedUrl.startsWith('http')) {
      resolvedUrl = 'https://carentaph.com/$resolvedUrl';
    }

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: 110, // square size for 1:1
        child: AspectRatio(
          aspectRatio: 1 / 1,
          child: resolvedUrl.isNotEmpty
              ? Image.network(
                  resolvedUrl,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  frameBuilder: (context, child, frame, _) {
                    if (frame == null) {
                      return AnimatedOpacity(
                        opacity: 0.3,
                        duration: const Duration(milliseconds: 300),
                        child: placeholder,
                      );
                    }
                    return AnimatedOpacity(
                      opacity: 1,
                      duration: const Duration(milliseconds: 400),
                      child: child,
                    );
                  },
                  errorBuilder: (_, __, ___) => placeholder,
                )
              : placeholder,
        ),
      ),
    );
  }
}


class _ChipText extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ChipText({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(
            label.isEmpty ? '—' : label,
            style: theme.textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

class _AnimatedHeartButton extends StatelessWidget {
  final bool animating;
  final VoidCallback onPressed;

  const _AnimatedHeartButton({
    required this.animating,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: animating ? 1.18 : 1.0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutBack,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: IconButton(
          tooltip: 'Remove from favorites',
          onPressed: onPressed,
          icon: const Icon(
            Icons.favorite_rounded,
            color: Colors.redAccent, // ❤️ always red
          ),
        ),
      ),
    );
  }
}
