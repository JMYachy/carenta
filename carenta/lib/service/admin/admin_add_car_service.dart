import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:carenta/service/config/service_base_url.dart';

class AdminAddCarService {
  static Future<Map<String, dynamic>> addCar({
    required String year,
    required String manufacturer,
    required String model,
    required String type,
    required String licensePlate,
    required String color,
    required String transmission,
    required String fuelType,
    required String milage,
    required String seatingCap,
    required String status,
    required String withDriver,
    required String dailyRate,
    required String promo1,
    required String promo2,
    required String promo3,
    required List<Map<String, dynamic>> schedule,
    int? adminId,
    List<File>? imageFiles,
    File? videoFile,
  }) async {
    try {
      // ✅ Correct centralized endpoint
      final uri = Uri.parse(ServiceBaseUrl.endpoint("manager_add_car.php"));
      final req = http.MultipartRequest("POST", uri);

      // ✅ Core car fields
      req.fields.addAll({
        "year": year,
        "manufacturer": manufacturer,
        "model": model,
        "type": type,
        "licensePlate": licensePlate,
        "color": color,
        "transmission": transmission,
        "fuelType": fuelType,
        "milage": milage,
        "seatingCap": seatingCap,
        "status": status,
        "withDriver": withDriver,
        "daily_rate": dailyRate,
        "promo1": promo1,
        "promo2": promo2,
        "promo3": promo3,
        "schedule": jsonEncode(schedule),
      });

      if (adminId != null) {
        req.fields["adminId"] = adminId.toString();
      }

      // ✅ Image uploads
      if (imageFiles != null && imageFiles.isNotEmpty) {
        for (final img in imageFiles) {
          req.files.add(await http.MultipartFile.fromPath("images[]", img.path));
        }
      }

      // ✅ Video upload
      if (videoFile != null) {
        req.files.add(await http.MultipartFile.fromPath("video", videoFile.path));
      }

      // ✅ Send request
      final res = await req.send();
      final body = await res.stream.bytesToString();
      final data = jsonDecode(body);

      if (res.statusCode == 200 && data["success"] == true) {
        return {"success": true, "message": data["message"], "data": data};
      } else {
        return {
          "success": false,
          "message": data["message"] ?? "Upload failed, please retry."
        };
      }
    } catch (e) {
      return {"success": false, "message": "Network error: $e"};
    }
  }
}
