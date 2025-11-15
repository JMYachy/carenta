// lib/manager/screen/manager_car_screen/manager_add_car/service/manager_add_car_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // ✅ for MediaType
import 'package:mime/mime.dart'; // ✅ for lookupMimeType
import 'package:carenta/service/config/service_base_url.dart';
import '../model/manager_add_car_form_model.dart';

class AddCarResponse {
  final bool success;
  final String message;
  final int? carId;

  AddCarResponse({required this.success, required this.message, this.carId});

  factory AddCarResponse.fromJson(Map<String, dynamic> j) => AddCarResponse(
    success: (j['success'] == true || j['ok'] == true),
    message: (j['message'] ?? j['error'] ?? 'Unknown').toString(),
    carId: j['carId'] is int ? j['carId'] : int.tryParse('${j['carId']}'),
  );
}

class ManagerAddCarService {
  static Future<AddCarResponse> addCar(ManagerAddCarFormModel form) async {
    final uri = Uri.parse(ServiceBaseUrl.endpoint('manager_add_car.php'));

    // --- build nested JSONs ---
    final Map<String, dynamic> prices = {
      "daily": _toNumOrNull(form.dailyRate),
      "weekly": null,
      "monthly": null,
      "promo": null,
      "discount": _toNumOrNull(form.promo1),
    };
    final List<Map<String, dynamic>> schedule = <Map<String, dynamic>>[];

    final req = http.MultipartRequest('POST', uri);

    // --- required fields (snake_case to match PHP) ---
    req.fields['year'] = (form.year ?? '').trim();
    req.fields['manufacturer'] = (form.manufacturer ?? '').trim();
    req.fields['model'] = (form.model ?? '').trim();
    req.fields['type'] = (form.type ?? '').trim();
    req.fields['license_plate'] = (form.licensePlate ?? '').trim();
    req.fields['color'] = (form.color ?? '').trim();
    req.fields['transmission'] = (form.transmission ?? '').trim();
    req.fields['fueltype'] = (form.fuelType ?? '').trim();
    req.fields['milage'] = (form.milage ?? '').trim();
    req.fields['seatingcap'] = (form.seatingCap ?? '').trim();
    req.fields['status'] = 'available';
    req.fields['withDriver'] = (form.withDriver ?? 'No');

    // --- optional JSONs ---
    req.fields['prices'] = jsonEncode(prices);
    req.fields['schedule'] = jsonEncode(schedule);
    if (form.adminId != null) req.fields['adminId'] = form.adminId.toString();

    // --- attach images with correct MIME type ---
    for (final f in form.imageFiles) {
      if (await f.exists()) {
        final mime = lookupMimeType(f.path) ?? 'image/jpeg';
        final parts = mime.split('/');
        req.files.add(
          await http.MultipartFile.fromPath(
            'images[]',
            f.path,
            contentType: MediaType(parts[0], parts[1]),
          ),
        );
      }
    }

    // --- attach video with correct MIME type ---
    if (form.videoFile != null && await form.videoFile!.exists()) {
      final vMime = lookupMimeType(form.videoFile!.path) ?? 'video/mp4';
      final vParts = vMime.split('/');
      req.files.add(
        await http.MultipartFile.fromPath(
          'video',
          form.videoFile!.path,
          contentType: MediaType(vParts[0], vParts[1]),
        ),
      );
    }

    try {
      final streamed = await req.send();
      final body = await streamed.stream.bytesToString();

      if (streamed.statusCode >= 400) {
        // print detailed message for debug
        return AddCarResponse(
          success: false,
          message: 'HTTP ${streamed.statusCode}: $body',
        );
      }

      final decoded = jsonDecode(body);
      final map =
          decoded is Map
              ? Map<String, dynamic>.from(decoded)
              : <String, dynamic>{};
      return AddCarResponse.fromJson(map);
    } on SocketException catch (e) {
      return AddCarResponse(
        success: false,
        message: 'Network error: ${e.message}',
      );
    } catch (e) {
      return AddCarResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  static num? _toNumOrNull(String? s) {
    if (s == null) return null;
    final t = s.trim();
    if (t.isEmpty) return null;
    return num.tryParse(t);
  }
}
