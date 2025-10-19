class CarModel {
  final int carId;
  final String manufacturer;
  final String model;
  final String type;
  final String year;
  final String color;
  final String transmission;
  final String fuelType;
  final String seatingCap;
  final String withDriver;
  final String status;
  final List<String> imageUrls;
  final double? dailyRate;
  final double? weeklyRate;
  final double? monthlyRate;
  final String currency;

  // ✅ Add missing fields used by CarDetailScreen
  final String? licensePlate;
  final String? milage;
  final String? promoCode;
  final double? discountPercent;

  const CarModel({
    required this.carId,
    required this.manufacturer,
    required this.model,
    required this.type,
    required this.year,
    required this.color,
    required this.transmission,
    required this.fuelType,
    required this.seatingCap,
    required this.withDriver,
    required this.status,
    required this.imageUrls,
    this.dailyRate,
    this.weeklyRate,
    this.monthlyRate,
    this.currency = 'PHP',
    this.licensePlate,
    this.milage,
    this.promoCode,
    this.discountPercent,
  });

  factory CarModel.fromJson(Map<String, dynamic> json) {
    List<String> images = [];
    if (json['image_urls'] is List) {
      images = (json['image_urls'] as List).map((e) => e.toString()).toList();
    } else if (json['image_url'] is String) {
      images = [json['image_url']];
    }

    return CarModel(
      carId: int.tryParse(json['carid']?.toString() ?? '0') ?? 0,
      manufacturer: json['manufacturer'] ?? 'Unknown',
      model: json['model'] ?? 'N/A',
      type: json['type'] ?? 'N/A',
      year: json['year'] ?? 'N/A',
      color: json['color'] ?? 'N/A',
      transmission: json['transmission'] ?? 'Automatic',
      fuelType: json['fueltype'] ?? 'Gasoline',
      seatingCap: json['seatingcap'] ?? '4',
      withDriver: json['withDriver'] ?? 'No',
      status: json['status'] ?? 'available',
      imageUrls: images,
      dailyRate: double.tryParse(json['daily_rate']?.toString() ?? ''),
      weeklyRate: double.tryParse(json['weekly_rate']?.toString() ?? ''),
      monthlyRate: double.tryParse(json['monthly_rate']?.toString() ?? ''),
      currency: json['currency'] ?? 'PHP',
      // ✅ Added fields for details screen
      licensePlate: json['license_plate'] ?? 'N/A',
      milage: json['milage']?.toString() ?? '0',
      promoCode: json['promo_code'],
      discountPercent:
          double.tryParse(json['discount_percent']?.toString() ?? ''),
    );
  }
}
