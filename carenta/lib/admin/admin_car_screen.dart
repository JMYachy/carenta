import 'package:carenta/admin/car_management/add_car.dart';
import 'package:flutter/material.dart';
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
  final AdminGetCarService _carService = AdminGetCarService();
  List<CarModel> _cars = [];
  List<CarModel> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCars();
  }

  Future<void> _loadCars() async {
    setState(() => _loading = true);
    try {
      final result = await _carService.getCars();
      final cars = result.map<CarModel>((e) => CarModel.fromJson(e)).toList();
      setState(() {
        _cars = cars;
        _filtered = cars;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _filter(String query) {
    final lower = query.toLowerCase();
    setState(() {
      _filtered = _cars.where((c) {
        return c.manufacturer.toLowerCase().contains(lower) ||
            c.model.toLowerCase().contains(lower);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: _filter,
                          decoration: InputDecoration(
                            hintText: 'Search cars...',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 0, horizontal: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.add_circle,
                            color: Colors.blue, size: 32),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AddCar()),
                          ).then((_) => _loadCars());
                        },
                        tooltip: 'Add Car',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadCars,
                    child: ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final car = _filtered[index];
                        return GestureDetector(
                          onTap: () async {
                            // 👇 Await the result from CarDetailScreen
                            final updatedCar = await Navigator.push<CarModel>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CarDetailScreen(car: car),
                              ),
                            );

                            // 👇 If the user saved edits, update this car in the list
                            if (updatedCar != null) {
                              setState(() {
                                final int i = _cars.indexWhere(
                                    (c) => c.carId == updatedCar.carId);
                                if (i != -1) _cars[i] = updatedCar;

                                final int fi = _filtered.indexWhere(
                                    (c) => c.carId == updatedCar.carId);
                                if (fi != -1) _filtered[fi] = updatedCar;
                              });
                            }
                          },
                          child: AdminBuildercardListedcarmodel(car: car),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
