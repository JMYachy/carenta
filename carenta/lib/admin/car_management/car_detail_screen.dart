import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:carenta/widget/admin_widget/car_model.dart';

class CarDetailScreen extends StatelessWidget {
  final CarModel car;
  const CarDetailScreen({super.key, required this.car});

  String get _currencySymbol {
    switch (car.currency.toUpperCase()) {
      case 'PHP':
        return '₱';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageList = car.imageUrls.isNotEmpty
        ? car.imageUrls
        : ['https://via.placeholder.com/600x400?text=No+Image'];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('${car.manufacturer} ${car.model}'),
        backgroundColor: const Color(0xFF0077B6),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🚘 Car Images
            CarouselSlider(
              options: CarouselOptions(
                height: 240,
                enlargeCenterPage: true,
                enableInfiniteScroll: false,
                viewportFraction: 0.9,
              ),
              items: imageList.map((url) {
                final fullUrl =
                    url.startsWith('http') ? url : 'https://carentaph.com/$url';
                return ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    fullUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stack) => Container(
                      color: Colors.grey.shade300,
                      alignment: Alignment.center,
                      child: const Icon(Icons.directions_car,
                          size: 80, color: Colors.white70),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // 🪪 Car Info Section
            _buildSection(
              title: 'Car Information',
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
                  _buildRow('With Driver', car.withDriver),
                  _buildRow('Status', car.status),
                ],
              ),
            ),

            // 🧾 Technical Details Section
            _buildSection(
              title: 'Technical Details',
              child: Column(
                children: [
                  _buildRow('License Plate', car.licensePlate ?? 'N/A'),
                  _buildRow('Mileage', '${car.milage ?? "0"} km'),
                  _buildRow('Fuel Type', car.fuelType),
                  _buildRow('Transmission', car.transmission),
                  _buildRow('Color', car.color),
                ],
              ),
            ),

            // 💰 Pricing Info
            _buildSection(
              title: 'Pricing',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRow(
                      'Daily Rate', '$_currencySymbol${car.dailyRate ?? 0}'),
                  _buildRow(
                      'Weekly Rate', '$_currencySymbol${car.weeklyRate ?? 0}'),
                  _buildRow('Monthly Rate',
                      '$_currencySymbol${car.monthlyRate ?? 0}'),
                  if (car.promoCode != null && car.promoCode!.isNotEmpty)
                    _buildRow('Promo Code',
                        '${car.promoCode} (${car.discountPercent ?? 0}% OFF)'),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// --- Reusable Section Container ---
  Widget _buildSection({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                child,
              ]),
        ),
      ),
    );
  }

  /// --- Reusable Row Builder ---
  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.black54, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  /// --- Reusable Chip Builder ---
  Widget _buildChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, color: Colors.white, size: 18),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: const Color(0xFF1D84B5),
    );
  }
}
