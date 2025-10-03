import 'package:carenta/admin/add_car.dart';
import 'package:carenta/service/admin/admin_get_car_service.dart';
import 'package:carenta/widget/admin_widget/admin_card_builder_listed_car_model.dart';
import 'package:flutter/material.dart';

class AdminCarScreen extends StatefulWidget {
  const AdminCarScreen({super.key});

  @override
  State<AdminCarScreen> createState() => _AdminCarScreenState();
}

class _AdminCarScreenState extends State<AdminCarScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AdminGetCarService _carService = AdminGetCarService();

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
      setState(() {
        _allCars = cars;
        _filteredCars = cars;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
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
            final name = car['name']?.toLowerCase() ?? '';
            final brand = car['brand']?.toLowerCase() ?? '';
            return name.contains(query) || brand.contains(query);
          }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addCar() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddCar()),
    ).then((_) => _fetchCars()); // refresh after adding a car
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
                              child: AdminBuildercardListedcarmodel(
                                carName: car['name'] ?? 'Unknown',
                                brand: car['brand'] ?? 'N/A',
                                imageUrl:
                                    car['image_url'] ??
                                    'https://via.placeholder.com/150',
                                seats:
                                    int.tryParse(
                                      car['seats']?.toString() ?? '4',
                                    ) ??
                                    4,
                                transmission:
                                    car['transmission'] ?? 'Automatic',
                                pricePerDay: car['price']?.toString() ?? '50',
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
