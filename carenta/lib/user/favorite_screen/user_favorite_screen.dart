import 'package:carenta/user/favorite_screen/widgets/fav_item.dart';
import 'package:carenta/user/favorite_screen/widgets/favorite_search_field.dart';
import 'package:carenta/user/favorite_screen/widgets/filter_strip.dart';
import 'package:carenta/user/favorite_screen/widgets/sort_icon.dart';
import 'package:carenta/user/favorite_screen/widgets/square_icon_button.dart';
import 'package:carenta/user/favorite_screen/widgets/empty_state.dart';
import 'package:carenta/user/favorite_screen/widgets/error_state.dart';
import 'package:carenta/user/favorite_screen/widgets/favorite_list_grid.dart';
import 'package:carenta/user/favorite_screen/widgets/user_favorite_repository.dart';
import 'package:flutter/material.dart';



class UserFavoritesScreen extends StatefulWidget {
  const UserFavoritesScreen({super.key});
  @override
  State<UserFavoritesScreen> createState() => _UserFavoritesScreenState();
}

class _UserFavoritesScreenState extends State<UserFavoritesScreen> {
  final _repo = UserFavoritesRepository();
  final _searchC = TextEditingController();
  bool _isGrid = true;
  String _sort = 'Recently added';
  int _selected = 0;

  late Future<List<FavItem>> _future;

  final _filters = const [
    FilterSpec('All', Icons.all_inclusive_rounded),
    FilterSpec('With driver', Icons.person_rounded),
    FilterSpec('Self-drive', Icons.directions_car_filled_rounded),
    FilterSpec('Van/MPV', Icons.airport_shuttle_rounded),
    FilterSpec('SUV/Car', Icons.directions_car_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _future = _repo.list(sort: _sortParam);
  }

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

  void _reload() => setState(() => _future = _repo.list(sort: _sortParam, q: _searchC.text));

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: FavoriteSearchField(
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
                SquareIconButton(
                  tooltip: _isGrid ? 'Show list' : 'Show grid',
                  icon: _isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded,
                  onTap: () => setState(() => _isGrid = !_isGrid),
                ),
                const SizedBox(width: 9),
                SortButton(
                  value: _sort,
                  onSelected: (v) {
                    setState(() => _sort = v);
                    _reload();
                  },
                ),
              ],
            ),
          ),
          FilterStrip(filters: _filters, selected: _selected, onSelect: (i) => setState(() => _selected = i)),
          Expanded(
            child: FutureBuilder<List<FavItem>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return ErrorState(message: snap.error.toString(), onRetry: _reload);
                }
                final list = snap.data ?? const <FavItem>[];
                if (list.isEmpty) return const EmptyState();

                return FavoriteListGrid(
                  items: list,
                  isGrid: _isGrid,
                  onToggleFavorite: (item) async {
                    await _repo.toggleFavorite(item.carId, add: false);
                    _reload();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
