import 'package:carenta/service/Shared/get_car_service.dart';
import 'package:carenta/user/car_details_screen/user_car_details_screen.dart';
import 'package:carenta/widget/shared/car_card_widget.dart';
import 'package:flutter/material.dart';

class UserHomescreen extends StatefulWidget {
  const UserHomescreen({super.key});

  @override
  State<UserHomescreen> createState() => _UserHomescreenState();
}

class _UserHomescreenState extends State<UserHomescreen> {
  final TextEditingController _searchController = TextEditingController();
  final GetCarService _carService = GetCarService();

  List<Map<String, dynamic>> _allCars = [];
  List<Map<String, dynamic>> _filteredCars = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCars();
    _searchController.addListener(_filterCars);
  }

  Future<void> _fetchCars() async {
    setState(() => _isLoading = true);
    try {
      final cars = await _carService.getCars();
      if (!mounted) return;
      setState(() {
        _allCars = cars;
        _filteredCars = cars;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error fetching cars: $e")));
    }
  }

  void _filterCars() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCars =
          _allCars.where((car) {
            final name = car['name']?.toLowerCase() ?? '';
            final brand = car['brand']?.toLowerCase() ?? '';
            return name.contains(query) || brand.contains(query);
          }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _carService.close();
    super.dispose();
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

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: CarCardWidget(
                                car: car,
                                showStatus:
                                    false, // ✅ User doesn’t need car status
                                compactMode: true,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => UserCarDetailsScreen(car: car),
                                    ),
                                  );
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
