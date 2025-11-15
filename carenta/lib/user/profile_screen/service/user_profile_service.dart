// lib/service/user/user_profile_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:carenta/service/config/service_base_url.dart';

class UserProfileService {
  static final _fetchUrl = ServiceBaseUrl.endpoint('user_profile.php');
  static final _updateUrl = ServiceBaseUrl.endpoint('user_profile_update.php');
  static final _uploadUrl = ServiceBaseUrl.endpoint(
    'user_profile_avatar_upload.php',
  );

  /// Fetch user profile
  Future<Map<String, dynamic>> fetchProfile(int userId) async {
    try {
      final resp = await http.get(Uri.parse('$_fetchUrl?user_id=$userId'));
      final data = jsonDecode(resp.body);
      if (data is Map<String, dynamic>) return data;
      return _err('Invalid JSON');
    } catch (e) {
      return _err('Error: $e');
    }
  }

  /// Update profile (with optional image)
  Future<Map<String, dynamic>> updateProfile({
    required int userId,
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String phoneNumber,
    required String address,
    required String city,
    required String birthdate,
    required String gender,
    File? profileImage,
  }) async {
    try {
      final req = http.MultipartRequest('POST', Uri.parse(_updateUrl));
      req.fields.addAll({
        'user_id': userId.toString(),
        'first_name': firstName,
        'last_name': lastName,
        'username': username,
        'email': email,
        'phone_number': phoneNumber, // ✅ correct field name
        'street_address': address,
        'city': city,
        'birthdate': birthdate,
        'gender': gender,
      });

      if (profileImage != null && await profileImage.exists()) {
        final mime = lookupMimeType(profileImage.path) ?? 'image/jpeg';
        final parts = mime.split('/');
        req.files.add(
          await http.MultipartFile.fromPath(
            'profile_image',
            profileImage.path,
            contentType: MediaType(parts[0], parts[1]),
          ),
        );
      }

      final streamed = await req.send();
      final body = await streamed.stream.bytesToString();
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic>
          ? decoded
          : _err('Invalid response');
    } catch (e) {
      return _err('Update failed: $e');
    }
  }

  Map<String, dynamic> _err(String msg) => {'success': false, 'message': msg};
}
