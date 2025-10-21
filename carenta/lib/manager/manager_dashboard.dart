import 'package:carenta/manager/manager_homescreen.dart';
import 'package:carenta/manager/manager_user_vertification_screen.dart';
import 'package:flutter/material.dart';

// ✅ Screens
import 'package:carenta/manager/manager_car_screen.dart';
import 'package:carenta/manager/manager_booking_screen.dart';
import 'package:carenta/manager/manager_profile_screen.dart';

// ✅ Services
import 'package:carenta/service/util_service/session_manager_service.dart';
import 'package:carenta/main/signin_screen.dart';
import 'package:carenta/service/manager/manager_dashboard_stats_service.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _sessionData;
  bool _loadingSession = true;

  final List<String> _titles = [
    'Home',
    'Cars',
    'Bookings',
    'Verifications',
    'Profile'
  ];

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    try {
      final res = await SessionService.checkSession();
      if (res["success"] == true) {
        setState(() {
          _sessionData = res["data"];
          _loadingSession = false;
        });
      } else {
        if (mounted) Navigator.pushReplacementNamed(context, "/login");
      }
    } catch (e) {
      debugPrint("Session check error: $e");
      if (mounted) Navigator.pushReplacementNamed(context, "/login");
    }
  }

  void _onTabTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingSession) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final username = _sessionData?["username"] ?? "Manager";

    final List<Widget> screens = [
      _buildLiveHome(), // ✅ Dynamic manager stats
      const ManagerCarScreen(),
      const ManagerBookingScreen(),
      const ManagerUserVerificationScreen(),
      const ManagerProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 4,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF90E0EF), Color(0xFF0077B6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        centerTitle: true,
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
            letterSpacing: 1.1,
          ),
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
          const SizedBox(width: 8),
        ],
      ),

      // ✅ Drawer Sidebar
      drawer: Drawer(
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
                      child: Icon(
                        Icons.manage_accounts,
                        size: 40,
                        color: Color(0xFF0077B6),
                      ),
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
                    const Text(
                      "Manager",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),

              _drawerItem(Icons.bar_chart, "Home", 0),
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
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    await SessionService.logout();
                    if (mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SigninScreen(),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text(
                    "Logout",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      body: screens[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        selectedItemColor: const Color(0xFFFF5722),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: 'Cars'),
          BottomNavigationBarItem(icon: Icon(Icons.book_online), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.verified_user), label: 'Verifications'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  /// 🧮 Build dynamic live manager stats (like pending verifications, etc.)
  Widget _buildLiveHome() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: ManagerDashboardStatsService.pollStats(
        interval: const Duration(seconds: 5),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = snapshot.data!;
        if (stats["success"] != true) {
          return Center(child: Text("Error: ${stats['message']}"));
        }

        final data = stats["data"] ?? {};
        return ManagerHomeScreen(
          pendingVerifications: data["pending_verifications"] ?? 0,
          availableCars: data["available_cars"] ?? 0,
          activeRentals: data["active_rentals"] ?? 0,
          bookingsToday: data["bookings_today"] ?? 0,
        );
      },
    );
  }

  Widget _drawerItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(
        icon,
        color: _selectedIndex == index
            ? const Color(0xFFFF5722)
            : const Color(0xFF0077B6),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: _selectedIndex == index
              ? const Color(0xFFFF5722)
              : Colors.black87,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        _onTabTapped(index);
      },
    );
  }
}
