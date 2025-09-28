import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

class AdminAddCarService {
  static const String _endpoint = 'http://10.0.2.2/carenta/api/adminaddcar.php';

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
    required String status,       // 'available' | 'under maintenance'
    required String withDriver,   // 'Yes' | 'No'

    // Pricing: list of maps: {daily, weekly, monthly, promo, discount}
    required List<Map<String, dynamic>> prices,

    // Optional admin id for set_by_admin / uploaded_by
    int? adminId,

    // Media
    required List<File> imageFiles, // 'images[]'
    File? videoFile,                // 'video'

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

    // Sanitize pricing payload: keep keys adminaddcar.php expects
    final normalized = prices.map((p) => {
          'daily': (p['daily'] ?? '').toString(),
          'weekly': (p['weekly'] ?? '').toString(),
          'monthly': (p['monthly'] ?? '').toString(),
          if ((p['promo'] ?? '').toString().isNotEmpty) 'promo': p['promo'].toString(),
          if ((p['discount'] ?? '').toString().isNotEmpty) 'discount': p['discount'].toString(),
        }).toList();

    request.fields['prices'] = jsonEncode(normalized);

    // Images[]
    // Images[]
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

// Video (single)
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
        return {'success': false, 'message': 'Unexpected response shape.', 'raw': decoded};
      } catch (_) {
        return {
          'success': false,
          'message': 'Invalid JSON from server',
          'statusCode': response.statusCode,
          'body': response.body,
        };
      }
    } on SocketException {
      return {'success': false, 'message': 'Network error. Check your connection.'};
    } on TimeoutException {
      return {'success': false, 'message': 'Request timed out.'};
    } catch (e) {
      return {'success': false, 'message': 'Unexpected error: $e'};
    }
  }
}
