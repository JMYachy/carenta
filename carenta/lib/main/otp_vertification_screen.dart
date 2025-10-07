import 'dart:async';
import 'package:carenta/main/signin_screen.dart';
import 'package:carenta/service/main/signup_service.dart';
import 'package:carenta/service/util_service/firebase_otp_service.dart';
import 'package:flutter/material.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String verificationId;
  final String phone;
  final String password;

  const OTPVerificationScreen({
    super.key,
    required this.verificationId,
    required this.phone,
    required this.password,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isVerifying = false;
  bool _isResending = false;
  String _status = "";
  late String _currentVerificationId;

  int _resendCooldown = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentVerificationId = widget.verificationId;
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  // Start a 30-second cooldown for resending OTP
  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendCooldown = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown <= 1) {
        timer.cancel();
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  // ✅ Verify OTP
  Future<void> _verifyOTP() async {
    final code = _otpController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please enter the OTP code')),
      );
      return;
    }
    if (code.length < 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('⚠️ OTP must be 6 digits')));
      return;
    }

    setState(() {
      _isVerifying = true;
      _status = "Verifying OTP...";
    });

    final verified = await FirebaseOTPService().verifyOTP(
      _currentVerificationId,
      code,
    );

    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (verified) {
      setState(() => _status = "✅ OTP verified successfully!");
      await _registerUser();
    } else {
      setState(() => _status = "❌ Invalid or expired OTP. Try again.");
    }
  }

  // ✅ Register the verified user in your PHP backend
  Future<void> _registerUser() async {
    setState(() => _status = "Creating account...");

    final res = await SignupService.signupUser(widget.password, widget.phone);
    final status = (res['status'] ?? '').toString();
    final message = (res['message'] ?? '').toString();

    if (!mounted) return;

    if (status == 'success') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('✅ $message')));
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SigninScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('⚠️ $message')));
    }
  }

  // ✅ Resend OTP
  Future<void> _resendOTP() async {
    if (_isResending || _resendCooldown > 1) return;

    setState(() {
      _isResending = true;
      _status = "Sending new OTP...";
    });

    await FirebaseOTPService().sendOTP(
      widget.phone,
      (newVerificationId) {
        setState(() {
          _currentVerificationId = newVerificationId;
          _isResending = false;
          _status = "📩 New OTP sent!";
        });
        _startResendTimer();
      },
      (error) {
        setState(() {
          _isResending = false;
          _status = "❌ Failed to resend OTP: $error";
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Verify OTP"),
        backgroundColor: const Color(0xFF0077B6),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 30),
            Text(
              "Phone Verification",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Enter the 6-digit code sent to",
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 5),
            Text(
              widget.phone,
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFF0077B6),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),

            // OTP TextField
            TextField(
              controller: _otpController,
              maxLength: 6,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                counterText: "",
                filled: true,
                fillColor: Colors.grey.shade200,
                hintText: "______",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Verify button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isVerifying ? null : _verifyOTP,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0077B6),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _isVerifying
                        ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Text(
                          "Verify OTP",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
              ),
            ),

            const SizedBox(height: 15),

            // Resend section
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _resendCooldown > 1
                      ? "Resend available in $_resendCooldown s"
                      : "Didn't get the code?",
                  style: const TextStyle(color: Colors.black54),
                ),
                TextButton(
                  onPressed: _resendCooldown > 1 ? null : _resendOTP,
                  child: Text(
                    _isResending ? "Sending..." : "Resend OTP",
                    style: TextStyle(
                      color:
                          _resendCooldown > 1
                              ? Colors.grey
                              : const Color(0xFF0077B6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Status / Message display
            Text(
              _status,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
