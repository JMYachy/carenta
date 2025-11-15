import 'dart:io';

class ManagerAddCarFormModel {
  // Basic Details
  String year = '';
  String manufacturer = '';
  String model = '';
  String type = '';
  String licensePlate = '';
  String color = '';
  String transmission = '';
  String fuelType = '';
  String milage = '';
  String seatingCap = '';

  // Options (status fixed to 'available' on create)
  final String status = 'available';
  String withDriver = 'No';

  // Pricing
  String dailyRate = '';
  String promo1 = '10';
  String promo2 = '15';
  String promo3 = '20';

  int? adminId;

  // Media
  List<File> imageFiles = [];
  File? videoFile;

  Map<String, String> toFields() => {
    'year': year,
    'manufacturer': manufacturer,
    'model': model,
    'type': type,
    'license_plate': licensePlate,
    'color': color,
    'transmission': transmission,
    'fueltype': fuelType,
    'milage': milage,
    'seatingcap': seatingCap,
    'status': status, // <-- always 'available'
    'withDriver': withDriver,
    'daily_rate': dailyRate,
    if (adminId != null) 'adminId': adminId.toString(),
  };
}
