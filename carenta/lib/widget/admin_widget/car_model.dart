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

  // ✅ Additional fields used in CarDetailScreen
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

  /// ✅ Parse JSON from backend API
  factory CarModel.fromJson(Map<String, dynamic> json) {
    List<String> images = [];
    if (json['image_urls'] is List) {
      images = (json['image_urls'] as List).map((e) => e.toString()).toList();
    } else if (json['image_url'] is String && json['image_url'].isNotEmpty) {
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
      seatingCap: json['seatingcap']?.toString() ?? '4',
      withDriver: json['withDriver'] ?? 'No',
      status: json['status'] ?? 'available',
      imageUrls: images,
      dailyRate: double.tryParse(json['daily_rate']?.toString() ?? ''),
      weeklyRate: double.tryParse(json['weekly_rate']?.toString() ?? ''),
      monthlyRate: double.tryParse(json['monthly_rate']?.toString() ?? ''),
      currency: json['currency'] ?? 'PHP',
      licensePlate: json['license_plate'] ?? 'N/A',
      milage: json['milage']?.toString() ?? '0',
      promoCode: json['promo_code'],
      discountPercent:
          double.tryParse(json['discount_percent']?.toString() ?? ''),
    );
  }

  /// ✅ Convert to JSON (for updates or debugging)
  Map<String, dynamic> toJson() {
    return {
      'carid': carId,
      'manufacturer': manufacturer,
      'model': model,
      'type': type,
      'year': year,
      'color': color,
      'transmission': transmission,
      'fueltype': fuelType,
      'seatingcap': seatingCap,
      'withDriver': withDriver,
      'status': status,
      'image_urls': imageUrls,
      'daily_rate': dailyRate,
      'weekly_rate': weeklyRate,
      'monthly_rate': monthlyRate,
      'currency': currency,
      'license_plate': licensePlate,
      'milage': milage,
      'promo_code': promoCode,
      'discount_percent': discountPercent,
    };
  }

  /// ✅ Create a modified copy (used for instant UI refresh)
  CarModel copyWith({
    int? carId,
    String? manufacturer,
    String? model,
    String? type,
    String? year,
    String? color,
    String? transmission,
    String? fuelType,
    String? seatingCap,
    String? withDriver,
    String? status,
    List<String>? imageUrls,
    double? dailyRate,
    double? weeklyRate,
    double? monthlyRate,
    String? currency,
    String? licensePlate,
    String? milage,
    String? promoCode,
    double? discountPercent,
  }) {
    return CarModel(
      carId: carId ?? this.carId,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      type: type ?? this.type,
      year: year ?? this.year,
      color: color ?? this.color,
      transmission: transmission ?? this.transmission,
      fuelType: fuelType ?? this.fuelType,
      seatingCap: seatingCap ?? this.seatingCap,
      withDriver: withDriver ?? this.withDriver,
      status: status ?? this.status,
      imageUrls: imageUrls ?? this.imageUrls,
      dailyRate: dailyRate ?? this.dailyRate,
      weeklyRate: weeklyRate ?? this.weeklyRate,
      monthlyRate: monthlyRate ?? this.monthlyRate,
      currency: currency ?? this.currency,
      licensePlate: licensePlate ?? this.licensePlate,
      milage: milage ?? this.milage,
      promoCode: promoCode ?? this.promoCode,
      discountPercent: discountPercent ?? this.discountPercent,
    );
  }
}
