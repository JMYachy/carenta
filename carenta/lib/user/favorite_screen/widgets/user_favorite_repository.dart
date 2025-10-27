import 'package:carenta/service/user/user_favorite_service.dart';
import 'package:carenta/service/util_service/session_manager_service.dart';
import 'package:carenta/user/favorite_screen/widgets/fav_item.dart';

/// Repository wrapper for renter favorite operations.
/// Connects session, service calls, and data model mapping.
class UserFavoritesRepository {
  final _svc = FavoritesService();

  /// ✅ Get current renter userId from PHP session
  Future<int?> _getUserId() async {
    try {
      final session = await SessionManagerService.checkSession();
      if (session['success'] == true) {
        return session['data']?['userid'];
      }
    } catch (_) {}
    return null;
  }

  /// ✅ Full favorite list with sorting & search
  Future<List<FavItem>> list({String sort = 'recent', String q = ''}) async {
    final userId = await _getUserId();
    if (userId == null) throw Exception("No active session");

    final res = await _svc.list(userId: userId, q: q, sort: sort);

    if (res['status'] == 'success') {
      final List data = (res['data'] as List?) ?? const [];
      return data
          .map((e) => FavItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    throw Exception(res['message'] ?? 'Failed to load favorites');
  }

  /// ✅ Toggle favorite for the active user
  /// Returns true if success, false otherwise.
  Future<bool> toggleFavorite(int carId, {required bool add}) async {
    final userId = await _getUserId();
    if (userId == null) throw Exception("No active session");

    final res = await _svc.toggle(userId: userId, carId: carId, add: add);
    return res['status'] == 'success';
  }

  /// ✅ Lightweight favorite ID list (for persistent heart states)
  /// Used by Home and other pages to quickly know which cars are favorited.
  Future<List<int>> listFavoriteIds(int userId) async {
    try {
      final res = await _svc.list(userId: userId);
      if (res['status'] == 'success') {
        final data = (res['data'] as List?) ?? [];
        return data
            .map<int>((e) => int.tryParse(e['carid'].toString()) ?? 0)
            .where((id) => id > 0)
            .toList();
      }
    } catch (_) {}
    return [];
  }
}
