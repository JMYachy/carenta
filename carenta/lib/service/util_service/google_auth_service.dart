import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Handles Google sign-in and returns a Firebase [User] if successful
  Future<User?> signInWithGoogle() async {
    try {
      // ✅ Use the named constructor with scopes (optional)
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      // Start the Google sign-in process
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null; // user cancelled sign-in

      // ✅ The `authentication` property is now async — use `await` correctly
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // ✅ Create the Firebase credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      // ✅ Sign in to Firebase with the Google credentials
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      return userCredential.user;
    } catch (e, st) {
      print("❌ Google Sign-In failed: $e\n$st");
      return null;
    }
  }

  /// Sign out from both Firebase and Google
  Future<void> signOut() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print("❌ Google Sign-Out failed: $e");
    }
  }
}
