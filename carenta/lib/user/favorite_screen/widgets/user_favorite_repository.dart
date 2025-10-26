import 'package:carenta/service/user/user_favorite_service.dart';
import 'package:carenta/service/util_service/session_manager_service.dart';
import 'package:carenta/user/favorite_screen/widgets/fav_item.dart';

class UserFavoritesRepository {
  final _svc = FavoritesService();

  Future<int?> _getUserId() async {
    final session = await SessionManagerService.checkSession();
    if (session['success'] == true) {
      return session['data']?['userid'];
    }
    return null;
  }

  Future<List<FavItem>> list({
    required String sort,
    String q = '',
  }) async {
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

  Future<bool> toggleFavorite(int carId, {required bool add}) async {
    final userId = await _getUserId();
    if (userId == null) throw Exception("No active session");
    final res = await _svc.toggle(userId: userId, carId: carId, add: add);
    return res['status'] == 'success';
  }
}
