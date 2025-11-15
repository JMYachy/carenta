import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:carenta/service/config/service_base_url.dart';

class AdminProfileService {
  final int adminId;
  late final String _url;

  AdminProfileService(this.adminId) {
    _url = ServiceBaseUrl.endpoint('admin_profile.php');
  }

  Map<String, dynamic> _decode(http.Response res) {
    final data = jsonDecode(res.body);
    if (data is Map<String, dynamic>) return data;
    throw Exception('Invalid response: ${res.body}');
  }

  Future<Map<String, dynamic>> fetchProfile() async {
    final uri = Uri.parse('$_url?adminid=$adminId');
    final res = await http.get(uri);
    return _decode(res);
  }

  Future<Map<String, dynamic>> updateInfo({
    String? firstName,
    String? lastName,
    String? phoneNumber,
  }) async {
    final req =
        http.MultipartRequest('POST', Uri.parse(_url))
          ..fields['action'] = 'update_info'
          ..fields['adminid'] = adminId.toString();

    if (firstName != null) req.fields['first_name'] = firstName;
    if (lastName != null) req.fields['last_name'] = lastName;
    if (phoneNumber != null) req.fields['phone_number'] = phoneNumber;

    final res = await http.Response.fromStream(await req.send());
    return _decode(res);
  }

  Future<Map<String, dynamic>> changePassword({
    required String current,
    required String next,
  }) async {
    final req =
        http.MultipartRequest('POST', Uri.parse(_url))
          ..fields['action'] = 'change_password'
          ..fields['adminid'] = adminId.toString()
          ..fields['current'] = current
          ..fields['next'] = next;

    final res = await http.Response.fromStream(await req.send());
    return _decode(res);
  }

  Future<Map<String, dynamic>> uploadAvatar({required File imageFile}) async {
    final req =
        http.MultipartRequest('POST', Uri.parse(_url))
          ..fields['action'] = 'upload_avatar'
          ..fields['adminid'] = adminId.toString()
          ..files.add(
            await http.MultipartFile.fromPath('image', imageFile.path),
          );

    final res = await http.Response.fromStream(await req.send());
    return _decode(res);
  }
}
