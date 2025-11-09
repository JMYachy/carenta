import 'package:flutter/material.dart';

class CarCardWidget extends StatefulWidget {
  final Map<String, dynamic> car;
  final VoidCallback? onTap;
  final bool showStatus;
  final bool showPrices;
  final bool compactMode;
  final bool enableFavorite;
  final Function(bool isFav)? onFavoriteChanged;
  final Future<bool> Function(bool isFav)? onFavoriteChangedAsync;
  final int? ratingPercent;
  final int? reviewCount;

  const CarCardWidget({
    super.key,
    required this.car,
    this.onTap,
    this.showStatus = true,
    this.showPrices = true,
    this.compactMode = false,
    this.enableFavorite = true,
    this.onFavoriteChanged,
    this.onFavoriteChangedAsync,
    this.ratingPercent,
    this.reviewCount,
  });

  @override
  State<CarCardWidget> createState() => _CarCardWidgetState();
}

class _CarCardWidgetState extends State<CarCardWidget> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = _extractIsFavorite(widget.car);
  }

  bool _extractIsFavorite(Map<String, dynamic> car) {
    final v = car['is_favorite'] ?? car['favorite'] ?? car['isFavorite'] ?? car['fav'];
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v.toLowerCase() == 'true' || v == '1';
    return false;
  }

  String _asString(dynamic v) => v?.toString() ?? '';

  String get _currencySymbol {
    switch (_asString(widget.car['currency']).toUpperCase()) {
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'PHP':
      default: return '₱';
    }
  }

  String _fmtMoney(dynamic v) {
    if (v == null) return '0';
    if (v is num) return v.toStringAsFixed(0);
    final parsed = num.tryParse(v.toString());
    return parsed?.toStringAsFixed(0) ?? '0';
  }

  void _toggleFavorite() async {
    final next = !_isFavorite;
    setState(() => _isFavorite = next);
    widget.onFavoriteChanged?.call(next);
    if (widget.onFavoriteChangedAsync != null) {
      final ok = await widget.onFavoriteChangedAsync!(next);
      if (!ok && mounted) setState(() => _isFavorite = !next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final car = widget.car;

    final manufacturer = _asString(car['manufacturer'] ?? car['brand']);
    final model = _asString(car['model'] ?? car['name']);
    final carName = "$manufacturer $model".trim();
    final year = _asString(car['year']);
    final transmission = _asString(car['transmission']);
    final seats = _asString(car['seatingcap'] ?? car['seatingCap']);
    final fuel = _asString(car['fueltype'] ?? car['fuelType']);
    final daily = _fmtMoney(car['daily_rate'] ?? car['price'] ?? 0);

    final imageUrl = _asString(
      (car['media'] is List && (car['media'] as List).isNotEmpty)
          ? (car['media'][0] is Map ? (car['media'][0]['media_url'] ?? '') : '')
          : (car['media_url'] ?? ''),
    );

    final rating = (widget.ratingPercent ??
        (car['rating_percent'] is num ? (car['rating_percent'] as num).round() : 0));

    final reviewCount = (widget.reviewCount ??
        (car['review_count'] is num
            ? car['review_count'] as int
            : int.tryParse('${car['review_count'] ?? 0}') ?? 0));

    final promoText = _buildPromoText(car);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼️ Image with favorite & rating overlay
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    imageUrl.isNotEmpty
                        ? (imageUrl.startsWith('http')
                            ? imageUrl
                            : 'https://carentaph.com/$imageUrl')
                        : 'https://via.placeholder.com/600x400?text=No+Image',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF0D47A1).withOpacity(0.15),
                      alignment: Alignment.center,
                      child: const Icon(Icons.directions_car, size: 50, color: Colors.black38),
                    ),
                  ),
                ),

                // ❤️ Favorite
                if (widget.enableFavorite)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: InkWell(
                      onTap: _toggleFavorite,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white,
                        child: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite ? Colors.redAccent : Colors.grey[700],
                          size: 18,
                        ),
                      ),
                    ),
                  ),

                // ⭐ Rating & Price
                Positioned(
                  left: 8,
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              rating > 0 ? '${(rating / 20).toStringAsFixed(1)} ★' : 'New',
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                            ),
                            if (reviewCount > 0)
                              Text(' ($reviewCount)', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                        Text(
                          '$_currencySymbol$daily/day',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // 🚗 Car Info
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Text(
                carName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            if (year.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: Text(
                  year,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ),

            // 🔧 Specs Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Spec(icon: Icons.settings, label: transmission),
                  _Spec(icon: Icons.local_gas_station, label: fuel),
                  _Spec(icon: Icons.people, label: '$seats seats'),
                ],
              ),
            ),

            // 💸 Promo Info (if exists)
            if (promoText != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                margin: const EdgeInsets.only(bottom: 10, left: 8, right: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D47A1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  promoText,
                  style: const TextStyle(
                    color: Color(0xFF0D47A1),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String? _buildPromoText(Map<String, dynamic> car) {
    final promos = <String>[];
    void addPromo(dynamic daysRaw, dynamic discountRaw) {
      final days = int.tryParse(daysRaw?.toString() ?? '');
      final discount = double.tryParse(discountRaw?.toString() ?? '');
      if (days != null && discount != null && discount > 0) {
        promos.add('$days+ days: -${discount.toStringAsFixed(0)}%');
      }
    }

    addPromo(car['min_days_for_promo1'], car['promo1_discount_percent']);
    addPromo(car['min_days_for_promo2'], car['promo2_discount_percent']);
    addPromo(car['min_days_for_promo3'], car['promo3_discount_percent']);

    if (promos.isEmpty) return null;
    return 'PROMO → ${promos.join(' • ')}';
  }

}

class _Spec extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Spec({required this.icon, required this.label});
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
