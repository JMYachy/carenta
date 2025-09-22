import 'package:carenta/service/user/user_favorite_service.dart';
import 'package:carenta/widget/favoritecardlayout.dart';
import 'package:flutter/material.dart';
import 'package:carenta/utils/session_manager.dart';

class UserFavoritesScreen extends StatefulWidget {
  const UserFavoritesScreen({super.key});
  @override
  State<UserFavoritesScreen> createState() => _UserFavoritesScreenState();
}

class _UserFavoritesScreenState extends State<UserFavoritesScreen> {
  final _searchC = TextEditingController();
  final _svc = const FavoritesService(apiRoot: 'http://10.0.2.2/carenta/api');

  final List<_FilterSpec> _filters = const [
    _FilterSpec('All', Icons.all_inclusive_rounded),
    _FilterSpec('With driver', Icons.person_rounded),
    _FilterSpec('Self-drive', Icons.directions_car_filled_rounded),
    _FilterSpec('Van/MPV', Icons.airport_shuttle_rounded),
    _FilterSpec('SUV/Car', Icons.directions_car_rounded),
  ];
  int _selected = 0; // visual only
  bool _isGrid = true;
  String _sort = 'Recently added';
  String get _sortParam {
    switch (_sort) {
      case 'Price: low to high':
        return 'price_asc';
      case 'Price: high to low':
        return 'price_desc';
      case 'Top rated':
        return 'rating_desc';
      default:
        return 'recent';
    }
  }

  late Future<List<_FavItem>> _future;
  List<_FavItem> _items = [];
  final Set<int> _busy = {}; // carIds currently toggling

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_FavItem>> _load() async {
    final userId = SessionManager.instance.userId ?? 1; // fallback if no session yet
    final res = await _svc.list(userId: userId, q: _searchC.text.trim(), sort: _sortParam);

    if (res['status'] == 'success') {
      final List data = (res['data'] as List?) ?? const [];
      final parsed = data
          .map((e) => _FavItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
      _items = parsed;
      return parsed;
    }

    final body = (res['body'] ?? '') as String;
    final short = body.length > 240 ? '${body.substring(0, 240)}…' : body;
    throw Exception('${res['message'] ?? 'Failed to load favorites'}${short.isNotEmpty ? ' • $short' : ''}');
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() {
      _future = next;
    });
    await next;
  }

  Future<void> _toggleFavorite(_FavItem item) async {
    if (_busy.contains(item.carId)) return;
    final userId = SessionManager.instance.userId ?? 1;

    setState(() {
      _busy.add(item.carId);
    });

    final res = await _svc.toggle(userId: userId, carId: item.carId, add: false);
    if (!mounted) return;

    if (res['status'] == 'success') {
      // Optimistic remove
      setState(() {
        _items.removeWhere((x) => x.carId == item.carId);
        _future = Future.value(List<_FavItem>.from(_items));
        _busy.remove(item.carId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Removed from favorites')),
      );
    } else {
      setState(() {
        _busy.remove(item.carId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Failed')),
      );
    }
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Column(
        children: [
          _HeaderBar(title: 'Favorites', subtitle: 'Your saved cars'),

          // Search + actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: {
                Expanded(
                  child: _SearchField(
                    controller: _searchC,
                    hint: 'Search saved cars',
                    onSubmit: (_) => _reload(),
                    onClear: () {
                      _searchC.clear();
                      _reload();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                _SquareIconButton(
                  tooltip: _isGrid ? 'Show list' : 'Show grid',
                  icon: _isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded,
                  onTap: () => setState(() {
                    _isGrid = !_isGrid;
                  }),
                ),

                const SizedBox(width: 9),
                _SortButton(
                  value: _sort,
                  onSelected: (v) {
                    setState(() {
                      _sort = v;
                    });
                    _reload();
                  },
                ),
              }.toList(),
            ),
          ),

          // Filters (visual only for now)
          _FilterStrip(
            filters: _filters,
            selected: _selected,
            onSelect: (i) => setState(() {
              _selected = i;
            }),
          ),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: FutureBuilder<List<_FavItem>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return _ErrState(
                      message: snap.error.toString(),
                      onRetry: _reload,
                    );
                  }
                  final list = snap.data ?? const <_FavItem>[];
                  if (list.isEmpty) return const _EmptyState();

                  final child = _isGrid
                      ? GridView.builder(
                          key: const ValueKey('grid'),
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.78,
                          ),
                          itemCount: list.length,
                          itemBuilder: (_, i) {
                            final m = list[i];
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
                              onFavoriteTap: _busy.contains(m.carId)
                                  ? null
                                  : () => _toggleFavorite(m),
                              onTap: () {}, // open details later
                            );
                          },
                        )
                      : ListView.separated(
                          key: const ValueKey('list'),
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          itemCount: list.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final m = list[i];
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
                              onFavoriteTap: _busy.contains(m.carId)
                                  ? null
                                  : () => _toggleFavorite(m),
                              onTap: () {},
                            );
                          },
                        );

                  return RefreshIndicator(onRefresh: _refresh, child: child);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ==================== Models & helpers ==================== */

class _FavItem {
  final int carId;
  final String title;
  final String? imageUrl;
  final int pricePerDay;
  final int seats;
  final String transmission;
  final bool withDriver;
  final double rating;
  final List<String> tags;

  _FavItem({
    required this.carId,
    required this.title,
    required this.imageUrl,
    required this.pricePerDay,
    required this.seats,
    required this.transmission,
    required this.withDriver,
    required this.rating,
    required this.tags,
  });

  static int _toInt(dynamic v, {int def = 0}) =>
      v == null ? def : (v is int ? v : int.tryParse(v.toString()) ?? def);
  static double _toDouble(dynamic v, {double def = 0}) =>
      v == null ? def : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? def);
  static String _toStr(dynamic v, {String def = ''}) => v?.toString() ?? def;

  factory _FavItem.fromMap(Map<String, dynamic> m) {
    final carId = _toInt(m['carid']);
    final brand = _toStr(m['brand']);
    final model = _toStr(m['model']);
    final carname = _toStr(m['carname']);
    final title = carname.isNotEmpty
        ? carname
        : (brand.isNotEmpty || model.isNotEmpty)
            ? [brand, model].where((e) => e.isNotEmpty).join(' ')
            : 'Car #$carId';

    final image = _toStr(m['thumbnail_url']?.toString().isNotEmpty == true
        ? m['thumbnail_url']
        : m['media_url']);
    final rate = _toInt(m['daily_rate'], def: 0);
    final seats = _toInt(m['seats'] ?? m['capacity'] ?? m['max_seats'], def: 4);
    final trans = _toStr(
        (m['transmission']?.toString().isNotEmpty ?? false) ? m['transmission'] : 'Automatic');
    final withDriver = (m['with_driver']?.toString() == '1') ||
        (m['driver_available']?.toString() == '1');
    final rating = _toDouble(m['rating'], def: 4.5);

    final tags = <String>[
      if (withDriver) 'With driver' else 'Self-drive',
      if ((m['type'] ?? '').toString().isNotEmpty) m['type'].toString(),
    ];

    return _FavItem(
      carId: carId,
      title: title,
      imageUrl: image.isEmpty ? null : image,
      pricePerDay: rate,
      seats: seats,
      transmission: trans,
      withDriver: withDriver,
      rating: rating,
      tags: tags.where((e) => e.isNotEmpty).toList(),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  final String title, subtitle;
  const _HeaderBar({required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary.withValues(alpha: 0.12), scheme.primary.withValues(alpha: 0.04), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Icon(Icons.favorite_rounded, color: scheme.primary, size: 32),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterSpec {
  final String label;
  final IconData icon;
  const _FilterSpec(this.label, this.icon);
}

class _FilterStrip extends StatelessWidget {
  final List<_FilterSpec> filters;
  final int selected;
  final ValueChanged<int> onSelect;
  const _FilterStrip({required this.filters, required this.selected, required this.onSelect});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final isSelected = i == selected;
          return ChoiceChip(
            label: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(filters[i].icon, size: 18),
              const SizedBox(width: 6),
              Text(filters[i].label),
            ]),
            selected: isSelected,
            onSelected: (_) => onSelect(i),
          );
        },
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onSubmit;
  final VoidCallback? onClear;
  const _SearchField({
    required this.controller,
    required this.hint,
    this.onSubmit,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear',
                onPressed: onClear,
                icon: const Icon(Icons.clear_rounded),
              ),
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
      textInputAction: TextInputAction.search,
      onSubmitted: onSubmit,
      onChanged: (_) {
        // rebuild to show/hide clear icon
        (context as Element).markNeedsBuild();
      },
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  const _SquareIconButton({required this.icon, required this.tooltip, this.onTap});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon),
        ),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  final String value;
  final ValueChanged<String> onSelected;
  const _SortButton({required this.value, required this.onSelected});
  @override
  Widget build(BuildContext context) {
    const items = ['Recently added', 'Price: low to high', 'Price: high to low', 'Top rated'];
    return PopupMenuButton<String>(
      tooltip: 'Sort',
      initialValue: value,
      onSelected: onSelected,
      itemBuilder: (ctx) => items.map((e) => PopupMenuItem<String>(value: e, child: Text(e))).toList(),
      child: const _SquareIconButton(icon: Icons.sort_rounded, tooltip: 'Sort', onTap: null),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.favorite_border_rounded, size: 56, color: cs.primary),
        const SizedBox(height: 12),
        Text('No favorites yet', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        Text('Save cars to see them here', style: TextStyle(color: cs.onSurfaceVariant)),
      ]),
    );
  }
}

class _ErrState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrState({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.error_outline_rounded, size: 56, color: cs.error),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(message, textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant)),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Retry')),
      ]),
    );
  }
}
