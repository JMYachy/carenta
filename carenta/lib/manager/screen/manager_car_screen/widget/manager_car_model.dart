// lib/manager/screen/manager_car_screen/model/manager_car_model.dart
class ManagerCarModel {
  final int carId;
  final String model;
  final String manufacturer;
  final String color;
  final String licensePlate;
  final String type;
  final int year;
  final double dailyRate;
  final String fuelType;
  final String transmission;
  final int seatingCapacity;
  final int milage;
  final String status;
  final bool withDriver;

  // ✅ Expanded media handling
  final List<Map<String, dynamic>> mediaList; // all images
  final List<Map<String, dynamic>> videoList; // all videos
  final String? imageUrl; // first image
  final String? thumbnailUrl;
  final String? videoUrl; // first video
  final List<String> mediaUrls; // combined list (for carousel)

  ManagerCarModel({
    required this.carId,
    required this.model,
    required this.manufacturer,
    required this.color,
    required this.licensePlate,
    required this.type,
    required this.year,
    required this.dailyRate,
    required this.fuelType,
    required this.transmission,
    required this.seatingCapacity,
    required this.milage,
    required this.status,
    required this.withDriver,
    required this.mediaList,
    required this.videoList,
    required this.mediaUrls,
    this.imageUrl,
    this.thumbnailUrl,
    this.videoUrl,
  });

  factory ManagerCarModel.fromJson(Map<String, dynamic> json) {
    final List<Map<String, dynamic>> allMedia = [];
    final List<Map<String, dynamic>> videos = [];

    // ✅ Separate media
    if (json['media'] is List) {
      for (final item in json['media']) {
        if (item is Map<String, dynamic>) {
          final type = (item['media_type'] ?? '').toString().toLowerCase();
          if (type == 'video') {
            videos.add(item);
          } else {
            allMedia.add(item);
          }
        }
      }
    }

    // ✅ Primary references
    final imageUrl =
        (allMedia.isNotEmpty) ? allMedia.first['media_url'] : json['media_url'];
    final thumbnail =
        (allMedia.isNotEmpty)
            ? allMedia.first['thumbnail_url']
            : json['thumbnail_url'];
    final videoUrl =
        (videos.isNotEmpty) ? videos.first['media_url'] : json['video_url'];

    // ✅ Merge media for carousel
    final mergedUrls =
        [
          ...allMedia.map((m) => m['media_url']?.toString() ?? ''),
          ...videos.map((v) => v['media_url']?.toString() ?? ''),
        ].where((e) => e.isNotEmpty).toList();

    return ManagerCarModel(
      carId: int.tryParse(json['carid'].toString()) ?? 0,
      model: json['model'] ?? '',
      manufacturer: json['manufacturer'] ?? '',
      color: json['color'] ?? '',
      licensePlate: json['license_plate'] ?? '',
      type: json['type'] ?? '',
      year: int.tryParse(json['year'].toString()) ?? 0,
      dailyRate: double.tryParse(json['daily_rate'].toString()) ?? 0.0,
      fuelType: json['fuel_type'] ?? '',
      transmission: json['transmission'] ?? '',
      seatingCapacity: int.tryParse(json['seating_capacity'].toString()) ?? 0,
      milage: int.tryParse(json['milage'].toString()) ?? 0,
      status: json['status'] ?? 'available',
      withDriver: (json['with_driver']?.toString().toLowerCase() == 'yes'),
      mediaList: allMedia,
      videoList: videos,
      imageUrl: imageUrl,
      thumbnailUrl: thumbnail,
      videoUrl: videoUrl,
      mediaUrls: mergedUrls,
    );
  }

  Map<String, dynamic> toJson() => {
    'carid': carId,
    'model': model,
    'manufacturer': manufacturer,
    'color': color,
    'license_plate': licensePlate,
    'type': type,
    'year': year,
    'daily_rate': dailyRate,
    'fuel_type': fuelType,
    'transmission': transmission,
    'seating_capacity': seatingCapacity,
    'milage': milage,
    'status': status,
    'with_driver': withDriver ? 'Yes' : 'No',
    'media': mediaList,
    'videos': videoList,
  };
}
