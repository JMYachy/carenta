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
  final int? ratingPercent; // 0..100
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

  @override
  void didUpdateWidget(CarCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incoming = _extractIsFavorite(widget.car);
    if (incoming != _isFavorite) {
      _isFavorite = incoming;
    }
  }

  // ------ Helpers (SAFE CASTING) ---------------------------------------------

  bool _extractIsFavorite(Map<String, dynamic> car) {
    final v =
        car['is_favorite'] ??
        car['favorite'] ??
        car['isFavorite'] ??
        car['fav'];
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v.toLowerCase() == 'true' || v == '1';
    return false;
  }

  String _asString(dynamic v) => v?.toString() ?? '';

  String get _currencySymbol {
    switch (_asString(widget.car['currency']).toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'PHP':
      default:
        return '₱';
    }
  }

  Color get _statusColor {
    final s = _asString(widget.car['status']).toLowerCase();
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

  String _fmtMoney(dynamic v) {
    if (v == null) return '0';
    if (v is num) return v.toStringAsFixed(0);
    final parsed = num.tryParse(v.toString());
    return parsed?.toStringAsFixed(0) ?? '0';
  }

  int _clampPct(int? v) => (v ?? 0).clamp(0, 100);

  void _toggleFavorite() async {
    final next = !_isFavorite;
    setState(() => _isFavorite = next); // optimistic
    widget.onFavoriteChanged?.call(next); // optional sync
    if (widget.onFavoriteChangedAsync != null) {
      // confirm/revert
      final ok = await widget.onFavoriteChangedAsync!(next);
      if (!ok && mounted) setState(() => _isFavorite = !next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final car = widget.car;

    final manufacturer = _asString(
      car['manufacturer'].toString().isEmpty
          ? car['brand']
          : car['manufacturer'],
    );
    final model = _asString(
      car['model'].toString().isEmpty ? car['name'] : car['model'],
    );
    final year = _asString(car['year']);
    final type = _asString(car['type']);

    final transmission = _asString(car['transmission']);
    final fuelType = _asString(car['fueltype'] ?? car['fuelType']);
    final seatingCap = _asString(car['seatingcap'] ?? car['seatingCap']);

    final daily = _fmtMoney(car['daily_rate'] ?? car['dailyRate']);
    final weekly = _fmtMoney(car['weekly_rate'] ?? car['weeklyRate']);
    final monthly = _fmtMoney(car['monthly_rate'] ?? car['monthlyRate']);

    // SAFELY derive image URL as String
    final List<dynamic> media =
        (car['media'] is List) ? (car['media'] as List<dynamic>) : const [];
    final rawUrl =
        media.isNotEmpty
            ? (media.first is Map ? (media.first as Map)['media_url'] : null)
            : (car['media_url']);
    final imageUrl = _asString(rawUrl); // <----- FORCE STRING

    final rPct = _clampPct(
      widget.ratingPercent ??
          (car['rating_percent'] is num
              ? (car['rating_percent'] as num).round()
              : null),
    );
    final rCount =
        widget.reviewCount ??
        (car['review_count'] is num
            ? (car['review_count'] as num).toInt()
            : (int.tryParse('${car['review_count'] ?? ''}') ?? 0));

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: widget.onTap,
      child: Container(
        margin:
            widget.compactMode
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
            // Title + Favorite (moved to header) + Status
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${manufacturer.isEmpty ? '' : manufacturer + ' '}$model',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: widget.compactMode ? 15 : 17,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.enableFavorite)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _toggleFavorite,
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? Colors.redAccent : Colors.grey[700],
                      size: 22,
                    ),
                  ),
                if (widget.showStatus)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _asString(car['status']).toUpperCase(),
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
                '${year.isEmpty ? '' : year + ' • '}$type',
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),

            const SizedBox(height: 10),

            // Image + Rating badge (favorite moved to header)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      imageUrl.isNotEmpty
                          ? (imageUrl.startsWith('http')
                              ? imageUrl
                              : 'https://carentaph.com/$imageUrl')
                          : 'https://via.placeholder.com/600x400?text=No+Image',
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) => Container(
                            color: const Color(0xFF0D47A1).withOpacity(0.15),
                            alignment: Alignment.center,
                            child: const Icon(Icons.directions_car, size: 50),
                          ),
                    ),
                  ),
                ),
                if (rPct > 0)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star_rate_rounded,
                            size: 16,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$rPct%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          if (rCount > 0) ...[
                            const SizedBox(width: 6),
                            Text(
                              '($rCount)',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // Specs row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Info(icon: Icons.settings, label: transmission),
                _Info(icon: Icons.local_gas_station, label: fuelType),
                _Info(
                  icon: Icons.people,
                  label: '${seatingCap.isEmpty ? '—' : seatingCap} Seats',
                ),
              ],
            ),

            if (widget.showPrices) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Price(label: 'Daily', value: '$_currencySymbol$daily'),
                  _Price(label: 'Weekly', value: '$_currencySymbol$weekly'),
                  _Price(label: 'Monthly', value: '$_currencySymbol$monthly'),
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
