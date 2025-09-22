import 'package:carenta/admin/admin_bookingscreen.dart';
import 'package:carenta/admin/admin_carscreen.dart';
import 'package:carenta/admin/admin_profilescreen.dart';
import 'package:flutter/material.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<String> _titles = [
    'Home',
    'Cars',
    'Bookings',
    'Profile',
  ];

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
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
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
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

  Widget _buildEmptyHome() {
    return const Center(
      child: Text(
        '',
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );
  }

  Widget _buildCarsScreen() => const AdminCarScreen();

  Widget _buildBookingsScreen() => const AdminBookingScreen();

  Widget _buildProfileScreen() => const AdminProfileScreen();
}
