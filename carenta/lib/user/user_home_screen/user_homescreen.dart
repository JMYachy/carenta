import 'package:carenta/user/user_home_screen/service/user_car_service.dart';
import 'package:flutter/material.dart';
import 'package:carenta/user/user_home_screen/car_details_screen/user_car_details_screen.dart';
import 'package:carenta/widget/shared/car_card_widget.dart';
import 'package:carenta/service/util_service/session_manager_service.dart';
import 'package:carenta/user/favorite_screen/widgets/user_favorite_repository.dart';

class UserHomescreen extends StatefulWidget {
  const UserHomescreen({super.key});

  @override
  State<UserHomescreen> createState() => _UserHomescreenState();
}

class _UserHomescreenState extends State<UserHomescreen> with RouteAware {
  final TextEditingController _searchController = TextEditingController();
  final UserCarService _carService = UserCarService();
  final _favRepo = UserFavoritesRepository();

  List<Map<String, dynamic>> _allCars = [];
  List<Map<String, dynamic>> _filteredCars = [];
  bool _isLoading = true;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _initAndFetch();
    _searchController.addListener(_filterCars);
  }

  Future<void> _initAndFetch() async {
    setState(() => _isLoading = true);
    try {
      final session = await SessionManagerService.checkSession();
      if (session['success'] == true) {
        _userId = session['data']?['userid'];
      }
      await _fetchCars();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Session or load error: $e")));
    }
  }

  /// ✅ Fetch cars + refresh favorite states
  Future<void> _fetchCars() async {
    setState(() => _isLoading = true);
    try {
      final cars = await _carService.fetchCars();

      List<int> favs = [];
      if (_userId != null) {
        favs = await _favRepo.listFavoriteIds(_userId!);
      }

      final normalized =
          cars.map<Map<String, dynamic>>((c) {
            final id = _extractCarId(c);
            final isFav = favs.contains(id);
            return {...c, 'carid': id, 'is_favorite': isFav};
          }).toList();

      if (mounted) {
        setState(() {
          _allCars = normalized;
          _filteredCars = normalized;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error fetching cars: $e")));
    }
  }

  /// Refresh favorites when returning from another screen
  @override
  void didPopNext() {
    _fetchCars();
  }

  int _extractCarId(Map<String, dynamic> car) {
    final raw = car['carid'] ?? car['id'];
    if (raw is int) return raw;
    return int.tryParse('${raw ?? 0}') ?? 0;
  }

  void _filterCars() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCars =
          _allCars.where((car) {
            final model = (car['model'] ?? '').toString().toLowerCase();
            final brand = (car['manufacturer'] ?? '').toString().toLowerCase();
            return model.contains(query) || brand.contains(query);
          }).toList();
    });
  }

  void _applyFavoriteLocally(int carId, bool isFav) {
    for (var i = 0; i < _allCars.length; i++) {
      if (_extractCarId(_allCars[i]) == carId) {
        _allCars[i] = {..._allCars[i], 'is_favorite': isFav};
      }
    }
    for (var i = 0; i < _filteredCars.length; i++) {
      if (_extractCarId(_filteredCars[i]) == carId) {
        _filteredCars[i] = {..._filteredCars[i], 'is_favorite': isFav};
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    _carService.close();
    super.dispose();
  }

  Map<String, dynamic> _normalizeCarData(Map<String, dynamic> raw) {
    return {
      'carid': raw['carid'] ?? raw['id'],
      'manufacturer': raw['manufacturer'] ?? '',
      'model': raw['model'] ?? '',
      'type': raw['type'] ?? '',
      'color': raw['color'] ?? '',
      'milage': raw['milage'] ?? '',
      'transmission': raw['transmission'] ?? '',
      'fueltype': raw['fueltype'] ?? '',
      'seatingcap': raw['seatingcap'] ?? '',
      'status': raw['status'] ?? '',
      'withDriver': raw['withDriver'] ?? 'No',
      'daily_rate': raw['daily_rate'] ?? 0,
      'currency': raw['currency'] ?? 'PHP',
      'media_url':
          raw['media_url'] ??
          raw['thumbnail_url'] ??
          raw['image_url'] ??
          'https://via.placeholder.com/600x400?text=No+Image',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // 🔍 Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search cars...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // 🚗 Car List
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredCars.isEmpty
                      ? const Center(
                        child: Text(
                          'No cars found.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                      : RefreshIndicator(
                        onRefresh: _fetchCars,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                          itemCount: _filteredCars.length,
                          itemBuilder: (context, index) {
                            final car = _filteredCars[index];
                            final carId = _extractCarId(car);
                            final isFav = car['is_favorite'] ?? false;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: CarCardWidget(
                                car: {...car, 'is_favorite': isFav},
                                showStatus: false,
                                compactMode: true,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => UserCarDetailsScreen(
                                            car: _normalizeCarData(car),
                                          ),
                                    ),
                                  );
                                },
                                onFavoriteChangedAsync: (bool becomeFav) async {
                                  final ok = await _favRepo.toggleFavorite(
                                    carId,
                                    add: becomeFav,
                                  );
                                  if (ok) {
                                    _applyFavoriteLocally(carId, becomeFav);
                                  } else if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to ${becomeFav ? "add to" : "remove from"} favorites',
                                        ),
                                      ),
                                    );
                                  }
                                  return ok;
                                },
                              ),
                            );
                          },
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
