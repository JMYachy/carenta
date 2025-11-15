import 'dart:io';
import 'package:carenta/manager/screen/manager_profile_screen/service/manager_profile_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'widget/profile_summary_card.dart';
import 'widget/accordion/accordion_card.dart';

// Your existing modular panels
import 'widget/panels/account_info_panel.dart';
import 'widget/panels/security_panel.dart';
import 'widget/panels/activity_panel.dart';
import 'widget/panels/profile_management_panel.dart';

import 'package:carenta/service/config/service_base_url.dart';

class ManagerProfileScreen extends StatefulWidget {
  final int adminId;
  const ManagerProfileScreen({super.key, required this.adminId});

  @override
  State<ManagerProfileScreen> createState() => _ManagerProfileScreenState();
}

class _ManagerProfileScreenState extends State<ManagerProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); // ✅ Here!
  final _picker = ImagePicker();
  final _scroll = ScrollController();

  // ✅ Use AccordionCardController instead of private _AccordionCardState
  final GlobalKey<AccordionCardController> _accountKey =
      GlobalKey<AccordionCardController>();
  final GlobalKey<AccordionCardController> _securityKey =
      GlobalKey<AccordionCardController>();
  final GlobalKey<AccordionCardController> _activityKey =
      GlobalKey<AccordionCardController>();
  final GlobalKey<AccordionCardController> _managementKey =
      GlobalKey<AccordionCardController>();

  bool _loading = true;
  bool _error = false;
  String _errorMsg = '';

  Map<String, dynamic> admin = {};
  Map<String, int> stats = {'cars': 0, 'bookings': 0, 'verifications': 0};
  List<int> activity7d = const [2, 5, 3, 6, 4, 7, 3];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
      _errorMsg = '';
    });

    try {
      final res = await ManagerProfileService.fetchProfile(widget.adminId);
      if (!mounted) return;
      if (res['ok'] != true) throw Exception(res['message'] ?? 'Server error');

      final data = Map<String, dynamic>.from(res['data'] ?? {});
      final pic = (data['profile_picture'] ?? '').toString();
      if (pic.isNotEmpty) {
        data['profile_picture'] = ServiceBaseUrl.file(pic);
      }

      setState(() {
        admin = data;
        stats = {'cars': 247, 'bookings': 1523, 'verifications': 89};
        activity7d = const [2, 5, 3, 6, 4, 7, 3];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = true;
        _errorMsg = '$e';
      });
    }
  }

  bool _scrolling = false;

  Future<void> _openAndScrollTo(GlobalKey<AccordionCardController> key) async {
    if (_scrolling) return;
    _scrolling = true;

    // ✅ Step 1: Collapse all other panels first
    for (final k in [_accountKey, _securityKey, _activityKey, _managementKey]) {
      if (k != key) k.currentState?.collapse();
    }

    // ✅ Step 2: Expand the target panel
    key.currentState?.expand();

    // ✅ Step 3: Wait for expansion animation to fully complete (~350ms)
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) {
      _scrolling = false;
      return;
    }

    // ✅ Step 4: Scroll into view only after panel is open and layout stable
    final ctx = key.currentContext;
    if (ctx != null) {
      try {
        await Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 550),
          curve: Curves.easeInOutCubicEmphasized,
          alignment: 0.05,
        );
      } catch (e) {
        debugPrint("⚠️ Scroll skipped: $e");
      }
    }

    // ✅ Step 5: Prevent re-entry for smooth UX
    await Future.delayed(const Duration(milliseconds: 200));
    _scrolling = false;
  }

  Future<void> _saveAccountInfo(Map<String, String> payload) async {
    final prev = Map<String, dynamic>.from(admin);
    setState(() {
      admin['first_name'] = payload['first_name'] ?? admin['first_name'];
      admin['last_name'] = payload['last_name'] ?? admin['last_name'];
      admin['email'] = payload['email'] ?? admin['email'];
      admin['phone_number'] = payload['phone_number'] ?? admin['phone_number'];
    });
    try {
      final res = await ManagerProfileService.updateProfile(
        adminId: widget.adminId,
        fields: payload,
      );
      if (!mounted) return;
      if (res['ok'] == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile updated')));
      } else {
        setState(() => admin = prev);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Update failed')),
        );
      }
    } catch (e) {
      setState(() => admin = prev);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Network error: $e')));
    }
  }

  Future<void> _toggle2FA(bool enabled) async {
    final prev = (admin['two_factor_enabled'] ?? 0) == 1;
    setState(() => admin['two_factor_enabled'] = enabled ? 1 : 0);
    try {
      final res = await ManagerProfileService.toggle2FA(
        adminId: widget.adminId,
        enabled: enabled,
      );
      if (!mounted) return;
      if (res['ok'] != true) {
        setState(() => admin['two_factor_enabled'] = prev ? 1 : 0);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? '2FA update failed')),
        );
      }
    } catch (e) {
      setState(() => admin['two_factor_enabled'] = prev ? 1 : 0);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Network error: $e')));
    }
  }

  Future<void> _changePassword(String current, String next) async {
    if (next.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 8 characters')),
      );
      return;
    }
    try {
      final res = await ManagerProfileService.changePassword(
        adminId: widget.adminId,
        current: current,
        next: next,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Password updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Network error: $e')));
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() => admin['profile_picture'] = picked.path);

      final res = await ManagerProfileService.uploadAvatar(
        adminId: widget.adminId,
        file: File(picked.path),
      );
      if (!mounted) return;
      if (res['ok'] == true) {
        final serverPath = (res['data']?['url'] ?? res['url'] ?? '').toString();
        setState(
          () => admin['profile_picture'] = ServiceBaseUrl.file(serverPath),
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Avatar updated')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Upload failed')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF6F7FB),
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    if (_error) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Failed to load profile',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _errorMsg,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final name =
        '${admin['first_name'] ?? ''} ${admin['last_name'] ?? ''}'.trim();
    final role = (admin['role'] ?? 'manager').toString();
    final status = (admin['status'] ?? 'active').toString();
    final email = (admin['email'] ?? '').toString();
    final phone = (admin['phone_number'] ?? '').toString();
    final lastLogin = (admin['last_login'] ?? '').toString();
    final lastIp = (admin['last_ip_address'] ?? '').toString();
    final pictureUrl = (admin['profile_picture'] ?? '').toString();
    final createdAt = (admin['created_at'] ?? '').toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProfileSummaryCard(
                    name: name.isEmpty ? (admin['username'] ?? '') : name,
                    role: role,
                    status: status,
                    email: email,
                    phone: phone,
                    pictureUrl: pictureUrl,
                    lastLogin: lastLogin,
                    lastIp: lastIp,
                    onTapEdit: () => _openAndScrollTo(_accountKey),
                    onTapSecurity: () => _openAndScrollTo(_securityKey),
                    onTapAnalytics: () => _openAndScrollTo(_activityKey),
                    onTapLogout:
                        () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Logout triggered')),
                        ),
                  ),

                  AccordionCard(
                    key: _accountKey,
                    title: 'Account Information',
                    initiallyExpanded: true,
                    child: AccountInfoPanel(
                      firstName: admin['first_name'] ?? '',
                      lastName: admin['last_name'] ?? '',
                      email: admin['email'] ?? '',
                      phone: admin['phone_number'] ?? '',
                      createdAt: createdAt,
                      lastLogin: lastLogin,
                      onSave: _saveAccountInfo,
                    ),
                  ),

                  AccordionCard(
                    key: _securityKey,
                    title: 'Security Settings',
                    child: SecurityPanel(
                      twoFactorEnabled: (admin['two_factor_enabled'] ?? 0) == 1,
                      loginAttempts: admin['login_attempts'] ?? 0,
                      lastIp: lastIp,
                      lastLogin: lastLogin,
                      onToggle2FA: _toggle2FA,
                      onChangePassword: _changePassword,
                    ),
                  ),

                  AccordionCard(
                    key: _activityKey,
                    title: 'Activity Insights',
                    child: ActivityPanel(
                      cars: stats['cars'] ?? 0,
                      bookings: stats['bookings'] ?? 0,
                      verifications: stats['verifications'] ?? 0,
                      dailyCounts: activity7d,
                    ),
                  ),

                  AccordionCard(
                    key: _managementKey,
                    title: 'Profile Management',
                    child: ProfileManagementPanel(
                      onChangePicture: _pickAndUploadAvatar,
                      onSave:
                          () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Nothing to save')),
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
