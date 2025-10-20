// lib/widget/admin_widget/car_detail_screen.dart
import 'package:carenta/widget/admin_widget/car_model.dart';
import 'package:carenta/widget/car_detail_widget/car_info_section.dart';
import 'package:carenta/widget/car_detail_widget/car_status_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class CarDetailScreen extends StatefulWidget {
  final CarModel car;
  const CarDetailScreen({super.key, required this.car});

  @override
  State<CarDetailScreen> createState() => _CarDetailScreenState();
}

class _CarDetailScreenState extends State<CarDetailScreen> {
  late CarModel _car;

  @override
  void initState() {
    super.initState();
    _car = widget.car; // local copy, mutable
  }

  /// This function will be called by CarInfoSection when it updates data
  void _updateCarModel(CarModel updated) {
    setState(() {
      _car = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    final imageList = _car.imageUrls.isNotEmpty
        ? _car.imageUrls
        : ['https://via.placeholder.com/600x400?text=No+Image'];

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _car); // ✅ return updated car to previous screen
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text('${_car.manufacturer} ${_car.model}'),
          backgroundColor: const Color(0xFF0077B6),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _car),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🖼️ Image Carousel
              CarouselSlider(
                options: CarouselOptions(
                  height: 240,
                  enlargeCenterPage: true,
                  enableInfiniteScroll: false,
                  viewportFraction: 0.9,
                ),
                items: imageList.map((url) {
                  final fullUrl = url.startsWith('http')
                      ? url
                      : 'https://carentaph.com/$url';
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      fullUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade300,
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported, size: 60),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // 🧾 Editable info
              CarInfoSection(
                car: _car,
                // Pass a callback so child can tell parent when car updates
                onCarUpdated: _updateCarModel,
              ),

              // ⚙️ Status changer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Status:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    CarStatusDropdown(
                      carId: _car.carId,
                      currentStatus: _car.status,
                      onStatusUpdated: _updateCarModel,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
