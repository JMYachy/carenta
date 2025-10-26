import 'package:flutter/material.dart';

/// Centralized navigation helper for cleaner routing.
class Nav {
  /// Navigate to a new screen using a material transition.
  static Future<T?> to<T>(BuildContext context, Widget page) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  /// Replace current screen (optional utility)
  static Future<T?> replace<T>(BuildContext context, Widget page) {
    return Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  /// Pop back safely
  static void back(BuildContext context, [dynamic result]) {
    if (Navigator.canPop(context)) Navigator.pop(context, result);
  }
}
