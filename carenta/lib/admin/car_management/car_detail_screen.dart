import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:carenta/widget/admin_widget/car_model.dart';

class CarDetailScreen extends StatelessWidget {
  final CarModel car;
  const CarDetailScreen({super.key, required this.car});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('${car.manufacturer} ${car.model}'),
        backgroundColor: const Color(0xFF0077B6),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🚘 Car Images
            if (car.imageUrls.isNotEmpty)
              CarouselSlider(
                options: CarouselOptions(
                  height: 240,
                  enlargeCenterPage: true,
                  enableInfiniteScroll: false,
                  viewportFraction: 0.9,
                ),
                items:
                    car.imageUrls.map((url) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          url.startsWith('http')
                              ? url
                              : 'https://carentaph.com/$url',
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      );
                    }).toList(),
              )
            else
              Container(
                height: 220,
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey.shade300,
                ),
                child: const Icon(
                  Icons.directions_car,
                  size: 100,
                  color: Colors.white70,
                ),
              ),

            // 🪪 Car Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${car.year} ${car.manufacturer} ${car.model}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        children: [
                          _buildChip(Icons.directions_car, car.type),
                          _buildChip(Icons.settings, car.transmission),
                          _buildChip(Icons.local_gas_station, car.fuelType),
                          _buildChip(Icons.people, '${car.seatingCap} Seats'),
                          _buildChip(Icons.color_lens, car.color),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildRow('License Plate', car.licensePlate),
                      _buildRow('Mileage', '${car.milage} km'),
                      _buildRow('With Driver', car.withDriver),
                      _buildRow('Status', car.status),
                    ],
                  ),
                ),
              ),
            ),

            // 💰 Pricing Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pricing',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildRow('Daily Rate', '₱${car.dailyRate ?? 0}'),
                      _buildRow('Weekly Rate', '₱${car.weeklyRate ?? 0}'),
                      _buildRow('Monthly Rate', '₱${car.monthlyRate ?? 0}'),
                      if (car.promoCode != null)
                        _buildRow(
                          'Promo Code',
                          '${car.promoCode} (${car.discountPercent ?? 0}% off)',
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, color: Colors.white, size: 18),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: const Color(0xFF1D84B5),
    );
  }
}
