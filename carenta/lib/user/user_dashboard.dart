import 'package:carenta/user/check_booking_screen/user_booking_screen.dart';
import 'package:carenta/user/user_favorite_screen.dart';
import 'package:carenta/user/user_homescreen.dart';
import 'package:carenta/user/user_profile_screen.dart';
import 'package:carenta/user/message_screen/user_messages_screen.dart';
import 'package:flutter/material.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  int _selectedIndex = 0;

  final List<String> _titles = [
    'Home',
    'Favorites',
    'Bookings',
    'Messages',
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
      _buildHomeScreen(),
      _buildFavoritesScreen(),
      _buildBookingsScreen(),
      _buildMessagesScreen(), // ✅ real chat screen
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
          onPressed: () {
            // 🔹 Add drawer or settings later if needed
          },
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
            onPressed: () {
              // 🔹 Future: open notifications page
            },
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_online),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  // 🔹 Sections
  Widget _buildHomeScreen() => const UserHomescreen();

  Widget _buildFavoritesScreen() => const UserFavoritesScreen();

  Widget _buildBookingsScreen() => const UserBookingScreen();

  Widget _buildMessagesScreen() => const UserMessagesScreen();

  Widget _buildProfileScreen() => const UserProfileScreen();
}
