// lib/user/profile_screen/user_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:carenta/service/util_service/session_manager_service.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_tile.dart';
import 'widgets/profile_edit_tab.dart';
import 'user_vertification_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  int _tabIndex = 0; // 0 = profile, 1 = edit

  int? _userId;
  String _name = '';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final session = await SessionManagerService.getSession();
    if (!mounted) return;

    setState(() {
      _userId = session?.userId;
      _name = session?.username ?? 'User';
      _email = session?.email ?? 'user@example.com';
    });
  }

  Widget _profileHome(BuildContext context) {
    return Column(
      children: [
        ProfileHeader(name: _name, email: _email),
        const SizedBox(height: 12),

        ProfileTile(
          icon: Icons.person,
          title: 'Edit Profile',
          onTap: () => setState(() => _tabIndex = 1),
        ),
        const SizedBox(height: 8),
        ProfileTile(
          icon: Icons.verified_user,
          title: 'Verify Account',
          onTap: () {
            if (_userId == null) return;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => UserVertificationScreen(userId: _userId!),
              ),
            );
          },
        ),

        const Spacer(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Complete your profile and submit verification to be approved by admin.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final body =
        _tabIndex == 1
            ? ProfileEditTab(
              // ✅ pass userId so the edit screen can pre-fill ALL data (incl. phone_number)
              userId: _userId,
              requireAllFields: true,
              // when user taps “Save”, go back AND refresh header data
              onBack: () async {
                setState(() => _tabIndex = 0);
                await _loadSession(); // ✅ refresh name/email after update
              },
            )
            : _profileHome(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(child: body),
    );
  }
}
