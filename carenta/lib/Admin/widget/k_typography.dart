import 'package:flutter/material.dart';
import 'k_colors.dart';

class KText {
  static const appBar = TextStyle(
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
  static const title = TextStyle(fontWeight: FontWeight.w600, fontSize: 16);
  static const subtitle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 18,
    color: KColors.primary,
  );
  static const label = TextStyle(fontSize: 13, color: Colors.grey);
  static const value = TextStyle(fontSize: 13, color: Colors.black);
  static const small = TextStyle(fontSize: 12, color: Colors.grey);
}
