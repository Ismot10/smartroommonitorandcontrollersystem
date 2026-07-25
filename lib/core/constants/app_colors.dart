import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand colours
  static const Color primary = Color(0xFF75B83B);
  static const Color primaryDark = Color(0xFF167A55);
  static const Color primaryLight = Color(0xFFCDEFA9);

  // Premium accent colours
  static const Color accentYellow = Color(0xFFFFC857);
  static const Color accentPurple = Color(0xFF7656E8);
  static const Color accentBlue = Color(0xFF4A90E2);

  // Light theme
  static const Color lightBackground = Color(0xFFF5F1E8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceSoft = Color(0xFFF0F4E9);
  static const Color lightText = Color(0xFF17201B);
  static const Color lightTextSecondary = Color(0xFF6D756F);

  // Dark theme
  static const Color darkBackground = Color(0xFF101512);
  static const Color darkSurface = Color(0xFF19201C);
  static const Color darkSurfaceSoft = Color(0xFF222B25);
  static const Color darkText = Color(0xFFF4F7F5);
  static const Color darkTextSecondary = Color(0xFFAAB5AE);

  // System-status colours
  static const Color safe = Color(0xFF36B56B);
  static const Color warning = Color(0xFFFFB547);
  static const Color danger = Color(0xFFE84D4D);
  static const Color offline = Color(0xFF909892);

  // Sensor colours
  static const Color temperature = Color(0xFFFF6B57);
  static const Color humidity = Color(0xFF42A5F5);
  static const Color gas = Color(0xFFFFA43A);
  static const Color motion = Color(0xFF62C86B);
  static const Color rain = Color(0xFF4B8FF7);
  static const Color light = Color(0xFFFFCA45);
}