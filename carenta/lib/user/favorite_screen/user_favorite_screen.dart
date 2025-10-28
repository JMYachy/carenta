import 'dart:async';
import 'package:carenta/main/splash_screen.dart';
import 'package:carenta/service/user/user_favorite_service.dart';
import 'package:carenta/service/util_service/session_manager_service.dart';
import 'package:carenta/user/favorite_screen/widgets/favorite_card_widget.dart';
import 'package:carenta/user/user_home_screen/car_details_screen/user_car_details_screen.dart';
import 'package:flutter/material.dart';

class UserFavoritesScreen extends StatefulWidget {
  const UserFavoritesScreen({super.key});

  @override
  State<UserFavoritesScreen> createState() => _UserFavoritesScreenState();
}

class _UserFavoritesScreenState extends State<UserFavoritesScreen> {
  final _svc = FavoritesService();
  final _searchC = TextEditingController();
  final _scrollC = ScrollController();

  int? _userId;
  bool _initing = true;
  bool _loading = false;
  String _sort = 'recent'; // recent | price_asc | price_desc | rating_desc
  String? _error;

  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _searchC.dispose();
    _scrollC.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() => _initing = true);
    try {
      final session = await SessionManagerService.getSession();
      final uid = session?.userId;
      if (uid == null) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SplashScreen()),
          (_) => false,
        );
        return;
      }
      _userId = uid;
      await _fetch();
    } catch (e) {
      _error = 'Failed to initialize: $e';
    } finally {
      if (mounted) setState(() => _initing = false);
    }
  }

  Future<void> _fetch() async {
    if (_userId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _svc.list(
        userId: _userId!,
        q: _searchC.text.trim().isEmpty ? null : _searchC.text.trim(),
        sort: _sort,
      );

      if (res['status'] == 'success') {
        final List data = (res['data'] as List?) ?? const [];
        _items = data.cast<Map<String, dynamic>>();
      } else {
        _error = res['message']?.toString() ?? 'Unexpected server response';
      }
    } catch (e) {
      _error = 'Network error: $e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pullToRefresh() async {
    await _fetch();
  }

  void _applySort(String value) {
    if (_sort == value) return;
    setState(() => _sort = value);
    _fetch();
  }

  void _onToggleFavorite(int carId, bool currentlyFav) async {
    // Optimistic update: if removing from favorites list, remove instantly
    if (currentlyFav) {
      final idx = _items.indexWhere((e) => _readInt(e['carid']) == carId);
      if (idx != -1) {
        setState(() => _items.removeAt(idx));
      }
    }

    try {
      final res = await _svc.toggle(
        userId: _userId!,
        carId: carId,
        add: !currentlyFav,
      );

      if (res['status'] != 'success') {
        // rollback if failed
        if (currentlyFav) {
          await _fetch();
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Failed to toggle favorite')),
          );
        }
      } else {
        if (mounted && !currentlyFav) {
          // If user added a favorite from elsewhere and opened this screen later,
          // we could re-fetch to include it. Here we’re already on the favorites list,
          // so we just show success.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Added to favorites')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // rollback
        await _fetch();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Toggle failed: $e')),
        );
      }
    }
  }

  int? _readInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        actions: [
          // Sort menu
          PopupMenuButton<String>(
            tooltip: 'Sort',
            onSelected: _applySort,
            initialValue: _sort,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'recent', child: Text('Recently added')),
              PopupMenuItem(value: 'price_asc', child: Text('Price: Low to High')),
              PopupMenuItem(value: 'price_desc', child: Text('Price: High to Low')),
              PopupMenuItem(value: 'rating_desc', child: Text('Rating: High to Low')),
            ],
            icon: const Icon(Icons.sort_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchC,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _fetch(),
              decoration: InputDecoration(
                hintText: 'Search cars, models, types…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchC.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchC.clear();
                          _fetch();
                        },
                        icon: const Icon(Icons.close_rounded),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          Expanded(
            child: _initing
                ? const _LoadingState()
                : RefreshIndicator(
                    onRefresh: _pullToRefresh,
                    child: _buildBody(theme),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Icon(Icons.error_outline_rounded, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: FilledButton.icon(
              onPressed: _fetch,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ),
        ],
      );
    }

    if (_loading && _items.isEmpty) {
      return const _LoadingState();
    }

    if (_items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          const Icon(Icons.favorite_border_rounded, size: 48),
          const SizedBox(height: 12),
          const Center(
            child: Text('No favorites yet'),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Tap the heart on a car to save it here.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      );
    }

    // ✅ THIS is the correct ListView builder section
    return ListView.separated(
      controller: _scrollC,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final raw = _items[index];
        final model = FavoriteCarModel.fromJson(raw);

        return FavoriteCardWidget(
          car: model,
          onToggle: () => _onToggleFavorite(model.carId, true),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UserCarDetailsScreen(
                  car: {
                    "carid": model.carId,
                    "manufacturer": model.title,
                    "type": model.type,
                    "transmission": model.transmission,
                    "fueltype": model.fuelType,
                    "daily_rate": model.dailyRate,
                    "image_url": model.imageUrl,
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Minimal shimmer-style loading with modern feel
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: 6,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemBuilder: (context, i) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
        ),
        height: 120,
      ),
    );
  }
}

/// Safe, defensive model for the mixed API fields
class FavoriteCarModel {
  final int carId;
  final String title; // manufacturer + model fallback
  final String type;
  final String transmission;
  final String fuelType;
  final String imageUrl;
  final double? dailyRate;
  final double? rating;

  FavoriteCarModel({
    required this.carId,
    required this.title,
    required this.type,
    required this.transmission,
    required this.fuelType,
    required this.imageUrl,
    required this.dailyRate,
    required this.rating,
  });

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
    }

  static double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static String _firstNonEmpty(List<dynamic> vals, {String fallback = ''}) {
    for (final v in vals) {
      final s = (v ?? '').toString().trim();
      if (s.isNotEmpty) return s;
    }
    return fallback;
  }

  factory FavoriteCarModel.fromJson(Map<String, dynamic> json) {
    final manufacturer = _firstNonEmpty([json['manufacturer'], json['brand']]);
    final model = _firstNonEmpty([json['model'], json['name'], json['car_model']]);
    final title = _firstNonEmpty(
      [json['title'], '$manufacturer $model'.trim()],
      fallback: model.isNotEmpty ? model : manufacturer,
    );

    final img = _firstNonEmpty([
      json['image_url'],
      json['thumbnail_url'],
      json['media_url'],
      json['photo'],
    ]);

    return FavoriteCarModel(
      carId: _asInt(json['carid'] ?? json['car_id']),
      title: title,
      type: _firstNonEmpty([json['type'], json['car_type']], fallback: '—'),
      transmission: _firstNonEmpty([json['transmission']], fallback: '—'),
      fuelType: _firstNonEmpty([json['fueltype'], json['fuel_type']], fallback: '—'),
      imageUrl: img,
      dailyRate: _asDouble(json['daily_rate'] ?? json['price_per_day'] ?? json['price']),
      rating: _asDouble(json['rating']),
    );
  }
}
