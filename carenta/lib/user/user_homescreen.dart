import 'package:carenta/service/admin/admingetcar_service.dart';
import 'package:carenta/user/user_cardetail.dart';
import 'package:carenta/widget/buildercard_listedcarmodel.dart';
import 'package:flutter/material.dart';

class UserHomescreen extends StatefulWidget {
  const UserHomescreen({super.key});

  @override
  State<UserHomescreen> createState() => _UserHomescreenState();
}

class _UserHomescreenState extends State<UserHomescreen> {
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
      if (!mounted) return;
      setState(() {
        _allCars = cars;
        _filteredCars = cars;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching cars: $e")),
      );
    }
  }

  void _filterCars() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCars = _allCars.where((car) {
        final name = car['name']?.toLowerCase() ?? '';
        final brand = car['brand']?.toLowerCase() ?? '';
        return name.contains(query) || brand.contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _carService.close(); // nice to cleanup the client
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // 🔍 Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController, // ⬅️ use the real controller
                      decoration: InputDecoration(
                        hintText: 'Search cars...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 🚗 Car list
            Expanded(
              child: _isLoading
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
                                // ⬇️ tap anywhere on the card to open details
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CarDetails(car: car),
                                      ),
                                    );
                                  },
                                  child: BuildercardListedcarmodel(
                                    carName: car['name'] ?? 'Unknown',
                                    brand: car['brand'] ?? 'N/A',
                                    imageUrl: (car['image_url'] as String?)?.isNotEmpty == true
                                        ? car['image_url']
                                        : 'https://via.placeholder.com/150',
                                    seats: int.tryParse(car['seats']?.toString() ?? '4') ?? 4,
                                    transmission: car['transmission'] ?? 'Automatic',
                                    pricePerDay: (car['price'] ?? '50').toString(),
                                    // If your card supports it, you can also pass:
                                    // currency: (car['currency'] ?? 'PHP').toString(),
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
