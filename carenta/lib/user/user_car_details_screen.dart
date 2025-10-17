import 'package:carenta/service/user/user_favorite_service.dart';
import 'package:carenta/service/user/review_service.dart';
import 'package:carenta/user/user_create_booking_screen.dart';
import 'package:carenta/widget/car_image_carousel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserCarDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> car;
  final int? userId;

  const UserCarDetailsScreen({super.key, required this.car, this.userId});

  @override
  State<UserCarDetailsScreen> createState() => _UserCarDetailsScreen();
}

class _UserCarDetailsScreen extends State<UserCarDetailsScreen> {
  bool isFavorite = false;
  bool isLoadingFav = false;

  final _favService = FavoritesService();
  final _reviewService = ReviewService();

  List<Map<String, dynamic>> reviews = [];
  bool isLoadingReviews = true;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
    _loadReviews();
  }

  Future<void> _checkFavoriteStatus() async {
    // If there's no userId (not signed in), skip favorite checks
    if (widget.userId == null) return;
    try {
      setState(() => isLoadingFav = true);
      final res = await _favService.list(userId: widget.userId!);
      if (res['status'] == 'success') {
        final List data = res['data'];
        final found = data.any(
          (c) => c['carid'].toString() == widget.car['carid'].toString(),
        );
        setState(() => isFavorite = found);
      }
    } catch (_) {
      // ignore silently
    } finally {
      setState(() => isLoadingFav = false);
    }
  }

  Future<void> _loadReviews() async {
    try {
      final result = await _reviewService.getReviews(widget.car['carid']);
      if (mounted) {
        final List<Map<String, dynamic>> data =
            (result['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        setState(() {
          reviews = data;
          isLoadingReviews = false;
        });
      }
    } catch (_) {
      setState(() => isLoadingReviews = false);
    }
  }

  Future<void> _toggleFavorite() async {
    if (isLoadingFav) return;
    setState(() => isLoadingFav = true);

    final bool newState = !isFavorite;
    try {
      final res = await _favService.toggle(
        userId: widget.userId!,
        carId: widget.car['carid'],
        add: newState,
      );
      if (!mounted) return;

      if (res['status'] == 'success') {
        setState(() => isFavorite = newState);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newState ? 'Added to favorites' : 'Removed from favorites',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.black87,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => isLoadingFav = false);
    }
  }

  String get _currencySymbol {
    final currency = (widget.car['currency'] ?? 'PHP').toString().toUpperCase();
    switch (currency) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      default:
        return '₱';
    }
  }

  double _num(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final car = widget.car;

    final List<String> carImages = [];
    if (car['media'] != null && car['media'] is List) {
      carImages.addAll(
        List<String>.from(car['media'].map((m) => m['media_url'])),
      );
    } else {
      final img = (car['image_url'] ?? car['media_url'])?.toString().trim();
      if (img != null && img.isNotEmpty) carImages.add(img);
    }

    final manufacturer = (car['manufacturer'] ?? '').toString();
    final model = (car['model'] ?? '').toString();
    final year = (car['year'] ?? '').toString();

    final daily = _num(car['daily_rate'] ?? car['price']);
    final priceFmt = NumberFormat('#,##0.##');
    final transmission = (car['transmission'] ?? '—').toString();
    final fuel = (car['fueltype'] ?? '—').toString();
    final color = (car['color'] ?? '—').toString();
    final milage = (car['milage'] ?? '—').toString();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        title: Text('$manufacturer $model', overflow: TextOverflow.ellipsis),
        actions: [
          isLoadingFav
              ? const Padding(
                padding: EdgeInsets.all(12.0),
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
              : IconButton(
                icon: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFavorite ? Colors.redAccent : Colors.black87,
                ),
                onPressed: widget.userId == null ? null : _toggleFavorite,
              ),
        ],
      ),

      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 12,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black87),
                    children: [
                      const TextSpan(
                        text: 'From ',
                        style: TextStyle(fontSize: 12),
                      ),
                      TextSpan(
                        text: '$_currencySymbol${priceFmt.format(daily)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const TextSpan(
                        text: '/day',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5722),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserCreateBookingscreen(car: car),
                    ),
                  );
                },
                child: const Text(
                  'Book Now',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),

      // ---------------------- BODY -----------------------
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        children: [
          CarImageCarousel(imageUrls: carImages),
          const SizedBox(height: 16),

          // ---- TITLE ----
          Text(
            '$manufacturer $model${year.isNotEmpty ? ' ($year)' : ''}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            (car['license_plate'] ?? '').toString().isNotEmpty
                ? 'Plate: ${car['license_plate']}'
                : '',
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),

          // ---- ABOUT ----
          const Text(
            "About This Car",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          _Card(
            child: Text(
              (car['description'] ?? 'No description available.'),
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),

          const SizedBox(height: 20),

          // ---- SPECIFICATIONS ----
          const Text(
            'Specifications',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _Card(
            child: Column(
              children: [
                _SpecRow(
                  icon: Icons.color_lens_rounded,
                  label: 'Color',
                  value: color,
                ),
                const Divider(height: 20),
                _SpecRow(
                  icon: Icons.speed_rounded,
                  label: 'Milage',
                  value: milage.toString(),
                ),
                const Divider(height: 20),
                _SpecRow(
                  icon: Icons.settings_rounded,
                  label: 'Transmission',
                  value: transmission,
                ),
                const Divider(height: 20),
                _SpecRow(
                  icon: Icons.local_gas_station_rounded,
                  label: 'Fuel Type',
                  value: fuel,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ---- REVIEWS ----
          const Text(
            "Reviews",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (isLoadingReviews)
            const Center(child: CircularProgressIndicator())
          else if (reviews.isEmpty)
            const Text(
              "No reviews yet. Be the first to review!",
              style: TextStyle(color: Colors.black54),
            )
          else
            Column(
              children:
                  reviews.map((r) {
                    return _Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              (r['profile_picture'] != null)
                                  ? NetworkImage(r['profile_picture'])
                                  : null,
                          child:
                              r['profile_picture'] == null
                                  ? const Icon(Icons.person)
                                  : null,
                        ),
                        title: Text(r['full_name'] ?? r['username'] ?? 'User'),
                        subtitle: Text(r['comment'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            (r['rating'] ?? 0),
                            (_) => const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
        ],
      ),
    );
  }
}

// ----------------------------- UI HELPERS -----------------------------

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: child,
    );
  }
}

class _SpecRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _SpecRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final val = value.isEmpty ? '—' : value;
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFFF5722)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Text(val, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}
