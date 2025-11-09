import 'package:carenta/main/splash_screen.dart';
import 'package:carenta/service/util_service/session_manager_service.dart';
import 'package:carenta/user/booking_screen/user_booking_screen.dart';
import 'package:carenta/user/favorite_screen/user_favorite_screen.dart';
import 'package:carenta/user/profile_screen/widgets/profile_edit_tab.dart';
import 'package:carenta/user/profile_screen/widgets/profile_header.dart';
import 'package:carenta/user/profile_screen/widgets/profile_tile.dart';
import 'package:flutter/material.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  int _selectedIndex = 0;
  int? _userId;
  String _userName = "";
  String _userEmail = "";
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final session = await SessionManagerService.checkSession();
    if (session['success'] == true) {
      final data = session['data'];
      setState(() {
        _userId = data['userid'];
        _userName = data['username'] ?? '';
        _userEmail = data['email'] ?? '';
      });
    } else {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SplashScreen()),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await SessionManagerService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (_) => false,
    );
  }

  Widget _buildMainTab() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ProfileHeader(
              name: _userName,
              email: _userEmail,
              avatarUrl: _avatarUrl,
            ),
            const SizedBox(height: 30),

            ProfileTile(
              icon: Icons.edit_rounded,
              title: "Edit Profile",
              onTap: () => setState(() => _selectedIndex = 1),
            ),
            ProfileTile(
              icon: Icons.history_rounded,
              title: "Booking History",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserBookingScreen()),
                );
              },
            ),
            ProfileTile(
              icon: Icons.favorite_rounded,
              title: "Favorites",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserFavoritesScreen()),
                );
              },
            ),
            ProfileTile(
              icon: Icons.settings_rounded,
              title: "Settings",
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Settings coming soon")),
                );
              },
            ),
            ProfileTile(
              icon: Icons.help_outline_rounded,
              title: "Help & Support",
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Help section coming soon")),
                );
              },
            ),

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text("Logout"),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    switch (_selectedIndex) {
      case 1:
        body = ProfileEditTab(
          onBack: () => setState(() => _selectedIndex = 0),
          userId: _userId,
        );
        break;
      default:
        body = _buildMainTab();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(child: body),
    );
  }
}
