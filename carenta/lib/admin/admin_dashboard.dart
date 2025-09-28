import 'dart:async';
import 'package:carenta/admin/admin_booking_screen.dart';
import 'package:carenta/admin/admin_car_screen.dart';
import 'package:carenta/admin/home_screen/admin_homescreen.dart';
import 'package:carenta/admin/admin_profilescreen.dart';
import 'package:carenta/service/admin/admin_dashboard_stats_service.dart';
import 'package:carenta/service/util_service/session_manager_service.dart';
import 'package:flutter/material.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _sessionData; // store session info
  bool _loadingSession = true;

  final List<String> _titles = [
    'Home',
    'Cars',
    'Bookings',
    'Profile',
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
        // No active session → back to login screen
        if (mounted) {
          Navigator.pushReplacementNamed(context, "/login");
        }
      }
    } catch (e) {
      debugPrint("Session check error: $e");
      if (mounted) {
        Navigator.pushReplacementNamed(context, "/login");
      }
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    await SessionService.logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, "/login");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingSession) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final List<Widget> screens = [
      _buildEmptyHome(),
      _buildCarsScreen(),
      _buildBookingsScreen(),
      _buildProfileScreen(),
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
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {},
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
          if (_sessionData != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Center(
                child: Text(
                  _sessionData?["username"] ?? "Admin",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: _logout,
            ),
          ],
        ],
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
            icon: Icon(Icons.directions_car),
            label: 'Cars',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_online),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  // inside AdminDashboardState
Widget _buildEmptyHome() {
  return FutureBuilder<Map<String, dynamic>>(
    future: AdminDashboardService.fetchStats(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(child: Text("Error: ${snapshot.error}"));
      }

      final data = snapshot.data?["data"] ?? {};
      return AdminHomeScreen(
        totalUsers: data["total_users"] ?? 0,
        totalCars: data["total_cars"] ?? 0,
        totalBookings: data["total_bookings"] ?? 0,
        totalRevenue: (data["total_revenue"] ?? 0).toDouble(),
      );
    },
  );
}

  Widget _buildCarsScreen() => const AdminCarScreen();

  Widget _buildBookingsScreen() => const AdminBookingScreen();

  Widget _buildProfileScreen() => const AdminProfileScreen();
}
