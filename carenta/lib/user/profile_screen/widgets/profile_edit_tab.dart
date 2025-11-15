import 'dart:io';
import 'package:carenta/user/profile_screen/service/user_profile_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

class ProfileEditTab extends StatefulWidget {
  final VoidCallback onBack;
  final int? userId;
  final bool requireAllFields;
  const ProfileEditTab({
    super.key,
    required this.onBack,
    this.userId,
    this.requireAllFields = true,
  });

  @override
  State<ProfileEditTab> createState() => _ProfileEditTabState();
}

class _ProfileEditTabState extends State<ProfileEditTab> {
  final _svc = UserProfileService();
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _birthdate = TextEditingController();
  String _gender = "Male";

  File? _profileImage;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.userId == null) return;
    setState(() => _loading = true);
    final res = await _svc.fetchProfile(widget.userId!);
    setState(() => _loading = false);

    final data = (res['data'] ?? {}) as Map<String, dynamic>;
    _firstName.text = (data['first_name'] ?? '').toString();
    _lastName.text = (data['last_name'] ?? '').toString();
    _username.text = (data['username'] ?? '').toString();
    _email.text = (data['email'] ?? '').toString();
    // ✅ FIX 1: Correct field name from contactno → phone_number
    _phone.text = (data['phone_number'] ?? '').toString();
    _address.text = (data['street_address'] ?? '').toString();
    _city.text = (data['city'] ?? '').toString();
    _birthdate.text = (data['birthdate'] ?? '').toString();
    _gender = (data['gender'] ?? 'Male').toString();
  }

  String? _req(String? v) {
    if (!widget.requireAllFields) return null;
    if (v == null || v.trim().isEmpty) return 'Required';
    return null;
  }

  Future<void> _pickBirthdate() async {
    final now = DateTime.now();
    final init = now.subtract(const Duration(days: 365 * 20));
    final picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      _birthdate.text = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {});
    }
  }

  Future<void> _pickProfileImage() async {
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (x != null) setState(() => _profileImage = File(x.path));
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.userId == null) return;

    setState(() => _loading = true);
    final res = await _svc.updateProfile(
      userId: widget.userId!,
      firstName: _firstName.text,
      lastName: _lastName.text,
      username: _username.text,
      email: _email.text,
      // ✅ FIX 2: Pass correct argument name phoneNumber
      phoneNumber: _phone.text,
      address: _address.text,
      city: _city.text,
      birthdate: _birthdate.text,
      gender: _gender,
      profileImage: _profileImage,
    );
    setState(() => _loading = false);

    final ok = (res['success'] == true || res['status'] == 'success');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Profile updated successfully' : (res['message'] ?? 'Failed'),
        ),
      ),
    );
    if (ok) widget.onBack();
  }

  InputDecoration _deco(String label, {IconData? icon}) => InputDecoration(
    labelText: label,
    prefixIcon: icon != null ? Icon(icon) : null,
    border: const OutlineInputBorder(),
  );

  Widget _row2(Widget a, Widget b) => Row(
    children: [
      Expanded(child: a),
      const SizedBox(width: 12),
      Expanded(child: b),
    ],
  );

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 8),
                Text(
                  'Edit Profile',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ✅ Profile Picture
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage:
                        _profileImage != null
                            ? FileImage(_profileImage!)
                            : const AssetImage('assets/default_user.png')
                                as ImageProvider,
                  ),
                  IconButton(
                    onPressed: _pickProfileImage,
                    icon: const Icon(
                      Icons.camera_alt,
                      color: Colors.blueAccent,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ✅ Two-column short fields
            _row2(
              TextFormField(
                controller: _firstName,
                decoration: _deco('First Name', icon: Icons.person),
                validator: _req,
              ),
              TextFormField(
                controller: _lastName,
                decoration: _deco('Last Name', icon: Icons.person_outline),
                validator: _req,
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _username,
              decoration: _deco('Username', icon: Icons.badge),
              validator: _req,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _email,
              decoration: _deco('Email', icon: Icons.email),
              keyboardType: TextInputType.emailAddress,
              validator: _req,
            ),
            const SizedBox(height: 12),

            _row2(
              TextFormField(
                controller: _phone,
                decoration: _deco('Contact Number', icon: Icons.phone),
                keyboardType: TextInputType.phone,
                validator: _req,
              ),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: _deco('Gender', icon: Icons.person_outline),
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _gender = v ?? 'Male'),
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _address,
              decoration: _deco('Address', icon: Icons.home),
              validator: _req,
            ),
            const SizedBox(height: 12),

            _row2(
              TextFormField(
                controller: _city,
                decoration: _deco('City', icon: Icons.location_city),
                validator: _req,
              ),
              TextFormField(
                controller: _birthdate,
                readOnly: true,
                onTap: _pickBirthdate,
                decoration: _deco('Birthdate', icon: Icons.cake),
                validator: _req,
              ),
            ),

            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loading ? null : _saveProfile,
              icon: const Icon(Icons.save),
              label: const Text("Save Changes"),
            ),
          ],
        ),
      ),
    );
  }
}
