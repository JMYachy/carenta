import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:carenta/service/config/service_base_url.dart';

class UserVerificationService {
  static final _url = ServiceBaseUrl.endpoint('user_submit_verification.php');

  /// New version: sends ID front, back, and Barangay document.
  static Future<Map<String, dynamic>> submitVerificationV2({
    required int userId,
    required String idType,
    required String idNumber,
    required File idFront,
    File? idBack,
    required File barangayDoc,
    String? notes,
  }) async {
    try {
      final req = http.MultipartRequest('POST', Uri.parse(_url));

      // ✅ match backend field names
      req.fields['userid'] = userId.toString();
      req.fields['id_type'] = idType;
      req.fields['id_number'] = idNumber;
      if (notes != null && notes.isNotEmpty) req.fields['notes'] = notes;

      // --- Helper for attaching files ---
      Future<void> attachFile(String field, File file) async {
        final mime = lookupMimeType(file.path) ?? 'application/octet-stream';
        final parts = mime.split('/');
        req.files.add(
          await http.MultipartFile.fromPath(
            field,
            file.path,
            contentType: MediaType(parts[0], parts[1]),
          ),
        );
      }

      // Required uploads
      await attachFile('id_front', idFront);
      if (idBack != null && await idBack.exists()) {
        await attachFile('id_back', idBack);
      }
      await attachFile('barangay_doc', barangayDoc);

      final streamed = await req.send();
      final resp = await http.Response.fromStream(streamed);
      final body = resp.body;

      if (resp.statusCode != 200) {
        return {
          "success": false,
          "message": "Server error: ${resp.statusCode}",
        };
      }

      final data = jsonDecode(body);
      return data is Map<String, dynamic>
          ? data
          : {"success": false, "message": "Invalid JSON"};
    } catch (e) {
      return {"success": false, "message": "Upload failed: $e"};
    }
  }
}
