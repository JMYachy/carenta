import 'package:flutter/material.dart';

/// A reusable, configurable car card widget for both Admin and User UIs.
/// Supports full data maps or lightweight car models.
/// Now includes a favorite toggle ❤️
class CarCardWidget extends StatefulWidget {
  final Map<String, dynamic> car;
  final VoidCallback? onTap;
  final bool showStatus;
  final bool showPrices;
  final bool compactMode;
  final bool enableFavorite;
  final Function(bool isFav)? onFavoriteChanged;

  const CarCardWidget({
    super.key,
    required this.car,
    this.onTap,
    this.showStatus = true,
    this.showPrices = true,
    this.compactMode = false,
    this.enableFavorite = true,
    this.onFavoriteChanged,
  });

  @override
  State<CarCardWidget> createState() => _CarCardWidgetState();
}

class _CarCardWidgetState extends State<CarCardWidget> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.car['is_favorite'] == true ||
        widget.car['favorite'] == true ||
        widget.car['isFavorite'] == true;
  }

  /// --- Currency Symbol Helper ---
  String get _currencySymbol {
    switch ((widget.car['currency'] ?? 'PHP').toString().toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'PHP':
      default:
        return '₱';
    }
  }

  /// --- Status Color ---
  Color get _statusColor {
    final s = (widget.car['status'] ?? '').toString().toLowerCase();
    switch (s) {
      case 'available':
        return Colors.greenAccent;
      case 'rented':
        return Colors.redAccent;
      case 'maintenance':
        return Colors.orangeAccent;
      default:
        return Colors.grey;
    }
  }

  void _toggleFavorite() async {
    setState(() => _isFavorite = !_isFavorite);
    // Optional: call your backend service to update favorite
    widget.onFavoriteChanged?.call(_isFavorite);
  }

  @override
  Widget build(BuildContext context) {
    final car = widget.car;
    final manufacturer = (car['manufacturer'] ?? '').toString();
    final model = (car['model'] ?? '').toString();
    final year = (car['year'] ?? '').toString();
    final type = (car['type'] ?? '').toString();

    final transmission = (car['transmission'] ?? '').toString();
    final fuelType = (car['fueltype'] ?? car['fuelType'] ?? '').toString();
    final seatingCap = car['seatingcap'] ?? car['seatingCap'] ?? 0;

    final daily = car['daily_rate'] ?? car['dailyRate'] ?? 0;
    final weekly = car['weekly_rate'] ?? car['weeklyRate'] ?? 0;
    final monthly = car['monthly_rate'] ?? car['monthlyRate'] ?? 0;

    final List<dynamic> media = (car['media'] ?? []) as List<dynamic>;
    final imageUrl = media.isNotEmpty
        ? media.first['media_url'] ?? car['media_url']
        : car['media_url'] ?? '';

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: widget.onTap,
      child: Container(
        margin: widget.compactMode
            ? const EdgeInsets.symmetric(vertical: 6, horizontal: 8)
            : const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🏷️ Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '$manufacturer $model',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: widget.compactMode ? 15 : 17,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.showStatus)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      (car['status'] ?? 'Unknown').toString().toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            if (year.isNotEmpty || type.isNotEmpty)
              Text(
                '$year • $type',
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),

            const SizedBox(height: 10),

            // 🖼️ Image with Favorite Button
            Stack(
              alignment: Alignment.topRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      imageUrl.isNotEmpty
                          ? imageUrl.startsWith('http')
                              ? imageUrl
                              : 'https://carentaph.com/$imageUrl'
                          : 'https://via.placeholder.com/600x400?text=No+Image',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF0D47A1).withOpacity(0.15),
                        alignment: Alignment.center,
                        child: const Icon(Icons.directions_car, size: 50),
                      ),
                    ),
                  ),
                ),

                // ❤️ Favorite button
                if (widget.enableFavorite)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: _toggleFavorite,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: _isFavorite
                              ? Colors.redAccent
                              : Colors.grey[700],
                          size: 22,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // ⚙️ Info Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Info(icon: Icons.settings, label: transmission),
                _Info(icon: Icons.local_gas_station, label: fuelType),
                _Info(icon: Icons.people, label: '$seatingCap Seats'),
              ],
            ),

            if (widget.showPrices) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Price(label: 'Daily', value: '$_currencySymbol${daily ?? 0}'),
                  _Price(
                      label: 'Weekly',
                      value: '$_currencySymbol${weekly ?? 0}'),
                  _Price(
                      label: 'Monthly',
                      value: '$_currencySymbol${monthly ?? 0}'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Info({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF0D47A1), size: 16),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.black, fontSize: 13)),
      ],
    );
  }
}

class _Price extends StatelessWidget {
  final String label;
  final String value;
  const _Price({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}
