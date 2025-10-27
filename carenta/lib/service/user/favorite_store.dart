import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:carenta/user/favorite_screen/widgets/user_favorite_repository.dart';

/// App-wide favorites store that survives screen/tab changes.
/// Usage:
///   FavoritesStore.instance.load();
///   FavoritesStore.instance.isFav(carId);
///   await FavoritesStore.instance.setFavorite(carId, toFav: true/false);
///   FavoritesStore.instance.hydrateFromCars(carsFromApi);
class FavoritesStore extends ChangeNotifier {
  FavoritesStore._internal();
  static final FavoritesStore instance = FavoritesStore._internal();

  final _repo = UserFavoritesRepository();
  final Set<int> _favoriteIds = <int>{};
  bool _loaded = false;

  bool get isLoaded => _loaded;
  UnmodifiableSetView<int> get favoriteIds => UnmodifiableSetView(_favoriteIds);

  /// Mark as ready (we hydrate from car lists later).
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    notifyListeners();
  }

  bool isFav(int carId) => _favoriteIds.contains(carId);

  /// Toggle on server and reflect locally.
  Future<bool> setFavorite(int carId, {required bool toFav}) async {
    final ok = await _repo.toggleFavorite(carId, add: toFav);
    if (ok) {
      if (toFav) {
        _favoriteIds.add(carId);
      } else {
        _favoriteIds.remove(carId);
      }
      notifyListeners();
    }
    return ok;
  }

  /// Populate favorites from a fresh cars payload (e.g., Home list API).
  void hydrateFromCars(Iterable<Map<String, dynamic>> cars) {
    final incoming = <int>{};
    for (final c in cars) {
      final id = _extractCarId(c);
      final fav = _extractIsFavorite(c);
      if (id > 0 && fav) incoming.add(id);
    }
    if (incoming.isEmpty) return;
    final before = _favoriteIds.length;
    _favoriteIds.addAll(incoming);
    if (_favoriteIds.length != before) notifyListeners();
  }

  // --- helpers ---------------------------------------------------------------

  static int _extractCarId(Map<String, dynamic> car) {
    final raw = car['carid'] ?? car['id'];
    if (raw is int) return raw;
    return int.tryParse('${raw ?? 0}') ?? 0;
  }

  static bool _extractIsFavorite(Map<String, dynamic> car) {
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
}
