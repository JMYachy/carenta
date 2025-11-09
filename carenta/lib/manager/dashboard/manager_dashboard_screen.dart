import 'package:carenta/manager/screen/manager_booking_screen/manager_booking_screen.dart';
import 'package:carenta/manager/screen/manager_car_screen/manager_car_screen.dart';
import 'package:carenta/manager/screen/manager_home_screen/manager_home_screen.dart';
import 'package:carenta/manager/screen/manager_profile_screen.dart';
import 'package:carenta/manager/screen/manager_user_vertification_screen.dart';
import 'package:flutter/material.dart';
import 'package:carenta/service/util_service/session_manager_service.dart';

import 'package:carenta/main/signin_screen.dart';

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _sessionData;
  bool _loadingSession = true;

  final GlobalKey<ManagerHomeScreenState> _homeKey = GlobalKey();

  final List<String> _titles = [
    'Dashboard',
    'Cars',
    'Bookings',
    'Verifications',
    'Profile'
  ];

  @override
  void initState() {
    super.initState();

    /// ✅ Delay session check slightly to ensure network & context ready
    Future.delayed(const Duration(milliseconds: 400), () {
      _checkSession();
    });
  }

  /// ✅ Hardened session check with retry & safe fallback
  Future<void> _checkSession() async {
    try {
      debugPrint("🧠 Checking session...");
      final res = await SessionManagerService.checkSession();

      if (res["success"] == true || res["ok"] == true) {
        debugPrint("✅ Session valid: ${res['data']}");
        setState(() {
          _sessionData = res["data"];
          _loadingSession = false;
        });
      } else {
        debugPrint("⚠️ No valid session, redirecting to login.");
        if (mounted) Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SigninScreen()),
        );
      }
    } catch (e) {
      debugPrint("❌ Session check error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Connection error, please log in again.")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SigninScreen()),
        );
      }
    }
  }

  void _onTabTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) _homeKey.currentState?.refreshDashboard();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingSession) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final username = _sessionData?["username"] ?? "Manager";
    final List<Widget> _screens = [
      ManagerHomeScreen(key: _homeKey),
      const ManagerCarScreen(filterStatus: 'all'),
      const ManagerBookingScreen(),
      const ManagerUserVerificationScreen(),
      const ManagerProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        elevation: 2,
        backgroundColor: const Color(0xFF0077B6),
        centerTitle: true,
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
            tooltip: 'Notifications',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("No new notifications."),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(username),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Container(
          key: ValueKey<int>(_selectedIndex),
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _screens[_selectedIndex],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Drawer _buildDrawer(String username) => Drawer(
        child: Container(
          color: const Color(0xFFE9F1F7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0077B6), Color(0xFF90E0EF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.manage_accounts,
                          size: 40, color: Color(0xFF0077B6)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text("Manager",
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
              _drawerItem(Icons.bar_chart, "Dashboard", 0),
              _drawerItem(Icons.directions_car, "Cars", 1),
              _drawerItem(Icons.book_online, "Bookings", 2),
              _drawerItem(Icons.verified_user, "Verifications", 3),
              const Divider(height: 1),
              _drawerItem(Icons.person, "Profile", 4),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    await SessionManagerService.logout();
                    if (mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const SigninScreen()),
                      );
                    }
                  },
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text("Logout",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _drawerItem(IconData icon, String title, int index) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon,
          color: isSelected ? const Color(0xFFFF5722) : const Color(0xFF0077B6)),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isSelected ? const Color(0xFFFF5722) : Colors.black87,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        _onTabTapped(index);
      },
    );
  }

  Widget _buildBottomNav() => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onTabTapped,
          selectedItemColor: const Color(0xFF0077B6),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: 'Cars'),
            BottomNavigationBarItem(icon: Icon(Icons.book_online), label: 'Bookings'),
            BottomNavigationBarItem(
                icon: Icon(Icons.verified_user), label: 'Verifications'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      );
}
