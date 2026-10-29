import 'package:flutter/material.dart';

/// The existing orange is kept as the primary brand colour, with a teal
/// accent for water-related readings. Swapping [accent] for a deeper blue is
/// the one-line way to go more aquatic.
class AquaColors {
  static const Color primary = Color.fromARGB(255, 206, 109, 40);
  static const Color fieldFill = Color(0xFFD7CCC8); // brown.shade100
  static const Color accent = Color(0xFF00796B); // teal 700
  static const Color healthy = Color(0xFF2E7D32);
  static const Color attention = Color(0xFFEF6C00);
  static const Color critical = Color(0xFFC62828);

  static const double radius = 10;

  static Color forStatus(String? status) {
    switch (status) {
      case 'critical':
        return critical;
      case 'attention':
        return attention;
      case 'healthy':
        return healthy;
      default:
        return accent;
    }
  }
}
