class CarModel {
  final int carId;
  final String year;
  final String manufacturer;
  final String model;
  final String type;
  final String licensePlate;
  final String color;
  final String transmission;
  final String fuelType;
  final String milage;
  final String seatingCap;
  final String status;
  final String withDriver;
  final List<String> imageUrls;
  final double? dailyRate;
  final double? weeklyRate;
  final double? monthlyRate;
  final String? promoCode;
  final double? discountPercent;

  CarModel({
    required this.carId,
    required this.year,
    required this.manufacturer,
    required this.model,
    required this.type,
    required this.licensePlate,
    required this.color,
    required this.transmission,
    required this.fuelType,
    required this.milage,
    required this.seatingCap,
    required this.status,
    required this.withDriver,
    this.imageUrls = const [],
    this.dailyRate,
    this.weeklyRate,
    this.monthlyRate,
    this.promoCode,
    this.discountPercent,
  });

  factory CarModel.fromJson(Map<String, dynamic> json) {
    return CarModel(
      carId: int.tryParse(json['carid']?.toString() ?? '0') ?? 0,
      year: json['year'] ?? 'N/A',
      manufacturer: json['manufacturer'] ?? 'Unknown',
      model: json['model'] ?? 'Unknown',
      type: json['type'] ?? 'N/A',
      licensePlate: json['license_plate'] ?? 'N/A',
      color: json['color'] ?? 'N/A',
      transmission: json['transmission'] ?? 'N/A',
      fuelType: json['fueltype'] ?? 'N/A',
      milage: json['milage'] ?? '0',
      seatingCap: json['seatingcap'] ?? '0',
      status: json['status'] ?? 'N/A',
      withDriver: json['withDriver'] ?? 'No',
      imageUrls: (json['image_urls'] as List?)?.cast<String>() ?? [],
      dailyRate: double.tryParse(json['daily_rate']?.toString() ?? ''),
      weeklyRate: double.tryParse(json['weekly_rate']?.toString() ?? ''),
      monthlyRate: double.tryParse(json['monthly_rate']?.toString() ?? ''),
      promoCode: json['promo_code'],
      discountPercent: double.tryParse(
        json['discount_percent']?.toString() ?? '',
      ),
    );
  }
}
