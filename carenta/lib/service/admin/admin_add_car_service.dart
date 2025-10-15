import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:carenta/service/config/service_base_url.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

class AdminAddCarService {
  static final String _endpoint = ServiceBaseUrl.endpoint("admin_add_car.php");

  /// Sends a multipart request that matches adminaddcar.php
  static Future<Map<String, dynamic>> addCar({
    // Required car fields
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
    required String status, // 'available' | 'under maintenance'
    required String withDriver, // 'Yes' | 'No'
    // Pricing: now a SINGLE map
    required Map<String, dynamic> prices,

    // Schedule: list of maps: {day, start_time, end_time}
    List<Map<String, dynamic>>? schedule,

    // Optional admin id for set_by_admin / uploaded_by
    int? adminId,

    // Media
    required List<File> imageFiles, // 'images[]'
    File? videoFile, // 'video'

    Duration timeout = const Duration(seconds: 30),
  }) async {
    final uri = Uri.parse(_endpoint);
    final request = http.MultipartRequest('POST', uri);

    // Fields expected by PHP
    request.fields.addAll({
      'year': year,
      'manufacturer': manufacturer,
      'model': model,
      'type': type,
      'licensePlate': licensePlate,
      'color': color,
      'transmission': transmission,
      'fuelType': fuelType,
      'milage': milage,
      'seatingCap': seatingCap,
      'status': status,
      'withDriver': withDriver,
    });

    if (adminId != null) {
      request.fields['adminId'] = adminId.toString();
    }

    // ---- Prices (single object) ----
    final normalizedPrice = {
      'daily': (prices['daily'] ?? '').toString(),
      'weekly': (prices['weekly'] ?? '').toString(),
      'monthly': (prices['monthly'] ?? '').toString(),
      if ((prices['promo'] ?? '').toString().isNotEmpty)
        'promo': prices['promo'].toString(),
      if ((prices['discount'] ?? '').toString().isNotEmpty)
        'discount': prices['discount'].toString(),
    };

    request.fields['prices'] = jsonEncode(normalizedPrice);

    // ---- Schedule (array) ----
    if (schedule != null && schedule.isNotEmpty) {
      request.fields['schedule'] = jsonEncode(schedule);
    }

    // ---- Images ----
    for (final img in imageFiles) {
      if (await img.exists()) {
        final mt = lookupMimeType(img.path) ?? 'image/jpeg';
        request.files.add(
          await http.MultipartFile.fromPath(
            'images[]',
            img.path,
            contentType: MediaType.parse(mt),
          ),
        );
      }
    }

    // ---- Video ----
    if (videoFile != null && await videoFile.exists()) {
      final mt = lookupMimeType(videoFile.path) ?? 'video/mp4';
      request.files.add(
        await http.MultipartFile.fromPath(
          'video',
          videoFile.path,
          contentType: MediaType.parse(mt),
        ),
      );
    }

    try {
      final streamed = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamed);

      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
        return {
          'success': false,
          'message': 'Unexpected response shape.',
          'raw': decoded,
        };
      } catch (_) {
        return {
          'success': false,
          'message': 'Invalid JSON from server',
          'statusCode': response.statusCode,
          'body': response.body,
        };
      }
    } on SocketException {
      return {
        'success': false,
        'message': 'Network error. Check your connection.',
      };
    } on TimeoutException {
      return {'success': false, 'message': 'Request timed out.'};
    } catch (e) {
      return {'success': false, 'message': 'Unexpected error: $e'};
    }
  }
}
