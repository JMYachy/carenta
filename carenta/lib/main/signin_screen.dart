import 'package:carenta/Admin/admin_dashboard.dart';
import 'package:carenta/main/signup_screen.dart';
import 'package:carenta/manager/dashboard/manager_dashboard_screen.dart';
import 'package:carenta/service/util_service/session_manager_service.dart';
import 'package:carenta/user/user_dashboard.dart';
import 'package:flutter/material.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final _loginController = TextEditingController(); // email for now
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _passwordVisible = false;
  String? _errorMessage;

  Future<void> _handleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _loginController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Please enter your email and password';
      });
      return;
    }

    try {
      final result = await SessionManagerService.login(email, password);
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        final role = (result['data']?['role'] ?? '').toLowerCase();

        Widget targetScreen;
        if (role == 'admin') {
          targetScreen = const Placeholder();
        } else if (role == 'manager') {
          targetScreen = const ManagerDashboardScreen();
        } else {
          targetScreen = const UserDashboard();
        }

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => targetScreen),
        );
      } else {
        setState(() => _errorMessage = result['message'] ?? 'Login failed');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: Center(
              child: Image.asset(
                'assets/logo/logo_carenta.png',
                fit: BoxFit.contain,
                height: 350,
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0077B6), Color(0xFF90E0EF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _loginController,
                          label: 'Email',
                          icon: Icons.email,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _passwordController,
                          label: 'Password',
                          icon: Icons.lock,
                          isPassword: true,
                        ),
                        const SizedBox(height: 20),
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleSignIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0077B6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator()
                              : const Text('Sign In',
                                  style: TextStyle(fontSize: 18)),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SignupScreen()),
                            );
                          },
                          child: const Text(
                            'Don\'t have an account? Sign Up',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? !_passwordVisible : false,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black, fontSize: 16),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF0077B6)),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _passwordVisible ? Icons.visibility : Icons.visibility_off,
                  color: const Color(0xFF0077B6),
                ),
                onPressed: () {
                  setState(() => _passwordVisible = !_passwordVisible);
                },
              )
            : null,
      ),
      style: const TextStyle(color: Colors.black),
    );
  }
}