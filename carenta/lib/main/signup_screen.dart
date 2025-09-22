import 'package:carenta/main/signin_screen.dart';
import 'package:carenta/service/signup_service.dart';
import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Phone number is required';
    // allow +, spaces, dashes; validate on digits count (>=10 typical, PH is 11 like 09xxxxxxxxx)
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10 || digits.length > 15) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    final formOK = _formKey.currentState?.validate() ?? false;
    if (!formOK) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    final res = await SignupService.signupUser(password, phone);

    if (!mounted) return;
    setState(() => _isLoading = false);

    final status = (res['status'] ?? '').toString();
    final message = (res['message'] ?? 'Something went wrong').toString();

    if (status == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ $message')),
      );
      // Navigate to Sign in (replace so user can’t go back)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SigninScreen()),
      );
    } else {
      // Show server-provided error or generic fallback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ $message')),
      );
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
            child: Container(
              color: Colors.white,
              child: const Center(
                child: Image(
                  image: AssetImage('assets/logo/logo_carenta.png'),
                  fit: BoxFit.contain,
                  height: 350,
                ),
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
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            labelStyle: const TextStyle(color: Colors.black),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: const Icon(Icons.phone, color: Color(0xFF0077B6)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: const TextStyle(color: Colors.black),
                          validator: _validatePhone,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: const TextStyle(color: Colors.black),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: const Icon(Icons.lock, color: Color(0xFF0077B6)),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _obscure = !_obscure),
                              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off,
                                  color: const Color(0xFF0077B6)),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: const TextStyle(color: Colors.black),
                          validator: _validatePassword,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF0077B6),
                              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Next', style: TextStyle(fontSize: 18, color: Colors.black)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          '--------------- OR ---------------',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : () {},
                                icon: const Icon(Icons.facebook, color: Colors.white),
                                label: const Text('Facebook', style: TextStyle(color: Colors.black)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3b5998),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : () {},
                                icon: const Icon(Icons.g_mobiledata, color: Colors.red),
                                label: const Text('Google', style: TextStyle(color: Colors.black)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          'By signing up, you agree to our Terms & Services',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black, fontSize: 12),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (context) => const SigninScreen()),
                                  );
                                },
                          child: const Text(
                            'Already have an account? Login',
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
}
