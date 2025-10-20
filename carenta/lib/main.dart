import 'package:carenta/admin/admin_add_manager_screen.dart';
import 'package:carenta/main/signup_screen.dart';
import 'package:carenta/main/splash_screen.dart';
import 'package:carenta/utils/session_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:carenta/admin/admin_dashboard.dart';
import 'package:carenta/user/user_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await SessionManager.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Carenta',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0077B6),
          primary: const Color(0xFF0077B6),
          secondary: const Color(0xFFFF5722),
        ),
        useMaterial3: true,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          elevation: 4,
          backgroundColor: Color(0xFF0077B6),
          foregroundColor: Colors.white,
        ),
      ),
      home: const SplashScreen(),

      // ✅ Named routes for navigation consistency
      routes: {
        '/login': (context) => const SignupScreen(),
        '/admin_dashboard': (context) => const AdminDashboard(),
        '/user_dashboard': (context) => const UserDashboard(),
        '/create_admin': (context) => const Placeholder(),
        '/create_manager': (context) => const AdminAddManagerScreen(),
      },
    );
  }
}
