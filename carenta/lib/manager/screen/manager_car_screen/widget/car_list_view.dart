// lib/manager/screen/manager_car_screen/widget/car_list_view.dart
import 'package:flutter/material.dart';
import 'package:carenta/widget/shared/car_card_widget.dart';
import 'package:carenta/widget/admin_widget/car_model.dart';
import 'package:carenta/Admin/car_management/car_detail_screen.dart';

class CarListView extends StatelessWidget {
  final List<Map<String, dynamic>> cars;
  final VoidCallback onReload;

  const CarListView({
    super.key,
    required this.cars,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    if (cars.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.directions_car, size: 64, color: Colors.grey),
              SizedBox(height: 8),
              Text('No cars found', style: TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      // ✅ These 2 lines fix the unbounded height crash
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),

      padding: const EdgeInsets.all(12),
      itemCount: cars.length,
      itemBuilder: (context, index) {
        final car = cars[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: CarCardWidget(
            car: car,
            enableFavorite: false,
            showPrices: true,
            onTap: () async {
              try {
                final carModel = CarModel.fromJson(car);
                final updated = await Navigator.push<CarModel>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CarDetailScreen(car: carModel),
                  ),
                );

                if (updated != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Car updated successfully!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  onReload();
                }
              } catch (e, st) {
                debugPrint("❌ Navigation error: $e\n$st");
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Unable to open car details')),
                );
              }
            },
          ),
        );
      },
    );
  }
}
