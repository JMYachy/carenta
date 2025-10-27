import 'package:carenta/user/favorite_screen/widgets/fav_item.dart';
import 'package:flutter/material.dart';
import 'package:carenta/widget/favorite_card_layout.dart';

class FavoriteListGrid extends StatelessWidget {
  final List<FavItem> items;
  final bool isGrid;
  final ValueChanged<FavItem> onToggleFavorite;

  const FavoriteListGrid({
    super.key,
    required this.items,
    required this.isGrid,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    if (!isGrid) {
      return ListView.separated(
        key: const ValueKey('list'),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final m = items[i];
          return FavoriteCarCard(
            title: m.title,
            imageUrl: m.imageUrl,
            pricePerDay: m.pricePerDay,
            seats: m.seats,
            transmission: m.transmission,
            withDriver: m.withDriver,
            rating: m.rating,
            tags: m.tags,
            isFavorite: true,
            layout: FavoriteCardLayout.list,
            onFavoriteTap: () => onToggleFavorite(m),
            onTap: () {},
          );
        },
      );
    }

    // Grid
    return GridView.builder(
      key: const ValueKey('grid'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        // ↓ More height per card to avoid bottom/right overflows
        childAspectRatio: 0.70, // was 0.78
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final m = items[i];
        return FavoriteCarCard(
          title: m.title,
          imageUrl: m.imageUrl,
          pricePerDay: m.pricePerDay,
          seats: m.seats,
          transmission: m.transmission,
          withDriver: m.withDriver,
          rating: m.rating,
          tags: m.tags,
          isFavorite: true,
          layout: FavoriteCardLayout.grid,
          onFavoriteTap: () => onToggleFavorite(m),
          onTap: () {},
        );
      },
    );
  }
}
