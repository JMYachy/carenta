import 'package:flutter/material.dart';
import 'package:carenta/admin/car_management/add_car.dart';
import 'package:carenta/admin/car_management/car_detail_screen.dart';
import 'package:carenta/service/admin/admin_get_car_service.dart';
import 'package:carenta/widget/admin_widget/admin_card_builder_listed_car_model.dart';
import 'package:carenta/widget/admin_widget/car_model.dart';

class AdminCarScreen extends StatefulWidget {
  const AdminCarScreen({super.key});

  @override
  State<AdminCarScreen> createState() => _AdminCarScreenState();
}

class _AdminCarScreenState extends State<AdminCarScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AdminGetCarService _carService = AdminGetCarService();

  List<CarModel> _allCars = [];
  List<CarModel> _filteredCars = [];
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
      final carsJson = await _carService.getCars();
      final cars = carsJson.map<CarModel>((c) => CarModel.fromJson(c)).toList();
      setState(() {
        _allCars = cars;
        _filteredCars = cars;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
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
            return car.model.toLowerCase().contains(query) ||
                car.manufacturer.toLowerCase().contains(query);
          }).toList();
    });
  }

  void _addCar() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddCar()),
    ).then((_) => _fetchCars());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // 🔍 Search bar + Add button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search cars...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle,
                      color: Colors.blue,
                      size: 32,
                    ),
                    onPressed: _addCar,
                    tooltip: 'Add Car',
                  ),
                ],
              ),
            ),

            // 🚗 Car list
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
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredCars.length,
                          itemBuilder: (context, index) {
                            final car = _filteredCars[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              CarDetailScreen(car: car),
                                    ),
                                  );
                                },
                                child: AdminBuildercardListedcarmodel(
                                  carName: '${car.manufacturer} ${car.model}',
                                  brand: car.manufacturer,
                                  imageUrl:
                                      car.imageUrls.isNotEmpty
                                          ? car.imageUrls.first
                                          : 'https://via.placeholder.com/150',
                                  seats: int.tryParse(car.seatingCap) ?? 4,
                                  transmission: car.transmission,
                                  pricePerDay: car.dailyRate?.toString() ?? '0',
                                ),
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
