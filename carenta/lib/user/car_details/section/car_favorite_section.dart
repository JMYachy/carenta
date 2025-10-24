import 'package:flutter/material.dart';

class CarFavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final bool isLoading;
  final bool enabled;
  final VoidCallback onTap;

  const CarFavoriteButton({
    super.key,
    required this.isFavorite,
    required this.isLoading,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return IconButton(
      icon: Icon(
        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color: isFavorite ? Colors.redAccent : Colors.black87,
      ),
      onPressed: enabled ? onTap : null,
    );
  }
}
