import 'package:firebase_auth/firebase_auth.dart';

/// Handles Firebase OTP (SMS) operations for Carenta.
/// Use this service only for verification — not as the main login system.
class FirebaseOTPService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Send an OTP SMS to the given [phoneNumber].
  ///
  /// The [onCodeSent] callback will be called with a [verificationId]
  /// that you’ll need to verify later in [verifyOTP].
  ///
  /// The [onError] callback will return a user-friendly error message.
  Future<void> sendOTP(
    String phoneNumber,
    Function(String verificationId) onCodeSent,
    Function(String error) onError,
  ) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),

        // Automatically called when verification is done (some devices)
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          // Optional: you can call onCodeSent again or handle auto-verification here
        },

        // Called when verification fails
        verificationFailed: (FirebaseAuthException e) {
          String message;
          switch (e.code) {
            case 'invalid-phone-number':
              message = 'Invalid phone number format.';
              break;
            case 'too-many-requests':
              message =
                  'Too many OTP requests. Please wait before trying again.';
              break;
            case 'quota-exceeded':
              message =
                  'SMS quota exceeded. Try again later or use a different number.';
              break;
            default:
              message = e.message ?? 'Verification failed. Please try again.';
          }
          onError(message);
        },

        // Called when the SMS is sent
        codeSent: (String verificationId, int? resendToken) async {
          onCodeSent(verificationId);
        },

        // Called when timeout expires
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      onError('Error sending OTP: $e');
    }
  }

  /// Verify the OTP [smsCode] sent to the user.
  ///
  /// Returns `true` if verified successfully, otherwise `false`.
  Future<bool> verifyOTP(String verificationId, String smsCode) async {
    try {
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      await _auth.signInWithCredential(credential);
      return true;
    } on FirebaseAuthException catch (e) {
      // Handle Firebase error codes gracefully
      switch (e.code) {
        case 'invalid-verification-code':
          return false;
        case 'session-expired':
          return false;
        default:
          return false;
      }
    } catch (_) {
      return false;
    }
  }
}
