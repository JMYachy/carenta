import 'package:carenta/manager/manager_homescreen.dart';
import 'package:carenta/manager/manager_profile_screen.dart';
import 'package:carenta/manager/manager_user_vertification_screen.dart';
import 'package:carenta/service/util_service/session_manager_service.dart';
import 'package:carenta/service/admin/admin_dashboard_stats_service.dart';
import 'package:flutter/material.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _sessionData;
  bool _loadingSession = true;

  final List<String> _titles = ['Home', 'Verifications', 'Profile'];

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
      if (mounted) Navigator.pushReplacementNamed(context, "/login");
    }
  }

  void _onTabTapped(int index) {
    setState(() => _selectedIndex = index);
    Navigator.pop(context); // close drawer if open
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingSession) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final username = _sessionData?["username"] ?? "Manager";

    final List<Widget> screens = [
      _buildLiveHome(),
      const ManagerUserVerificationScreen(),
      const ManagerProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0077B6),
      ),

      // ✅ Sidebar Drawer
      drawer: Drawer(
        child: Container(
          color: const Color(0xFFE9F1F7),
          child: Column(
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0077B6), Color(0xFF90E0EF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.manage_accounts,
                        color: Color(0xFF0077B6),
                        size: 35,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            "Manager",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _drawerItem(Icons.bar_chart, "Home", 0),
              _drawerItem(Icons.verified_user, "User Verifications", 1),
              const Divider(height: 1),
              _drawerItem(Icons.person, "Profile", 2),
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
                      Navigator.pushReplacementNamed(context, "/login");
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
          BottomNavigationBarItem(
            icon: Icon(Icons.verified_user),
            label: 'Verifications',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(
        icon,
        color:
            _selectedIndex == index
                ? const Color(0xFFFF5722)
                : const Color(0xFF0077B6),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color:
              _selectedIndex == index
                  ? const Color(0xFFFF5722)
                  : Colors.black87,
        ),
      ),
      onTap: () => _onTabTapped(index),
    );
  }

  /// ✅ Live Home Dashboard
  Widget _buildLiveHome() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: AdminDashboardStatsService.pollStats(
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
          totalUsers: data["total_users"] ?? 0,
          totalCars: data["total_cars"] ?? 0,
          totalBookings: data["total_bookings"] ?? 0,
        );
      },
    );
  }
}
