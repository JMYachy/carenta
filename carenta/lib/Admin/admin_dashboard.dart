// lib/Admin/dashboard/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:carenta/Admin/sections/overview/overview_section.dart';
import 'package:carenta/Admin/sections/managers/managers_section.dart';
import 'package:carenta/Admin/sections/insights/insights_section.dart';
import 'package:carenta/Admin/sections/profile/profile_section.dart';
import 'package:carenta/Admin/widget/k_colors.dart';
import 'package:carenta/Admin/widget/k_typography.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _index = 0;

  final _titles = ['Overview', 'Managers', 'Insights', 'Profile'];
  final _tabs = const [
    OverviewSection(),
    ManagersSection(),
    AdminInsightsScreen(),
    AdminProfileSection(adminId: 1),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index], style: KText.appBar),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0077B6), Color(0xFF90E0EF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _tabs[_index],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: KColors.primary,
        unselectedItemColor: Colors.grey,
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.manage_accounts),
            label: 'Managers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights),
            label: 'Insights',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
