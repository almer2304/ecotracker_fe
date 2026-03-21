import 'package:flutter/material.dart';

class AppColors {
  // Primary - Green (User Theme)
  static const Color primary = Color(0xFF2ECC71);
  static const Color primaryDark = Color(0xFF27AE60);
  static const Color primaryLight = Color(0xFFA9DFBF);
  static const Color primarySurface = Color(0xFFEAF9EE);

  // Collector Theme - Blue
  static const Color collectorPrimary = Color(0xFF3498DB);
  static const Color collectorPrimaryDark = Color(0xFF2980B9);
  static const Color collectorPrimaryLight = Color(0xFFAED6F1);
  static const Color collectorSurface = Color(0xFFEBF5FB);

  // Secondary
  static const Color secondary = Color(0xFF8B4513);
  static const Color accent = Color(0xFF3498DB);

  // Status
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF3498DB);

  // Pickup Status Colors
  static const Color statusPending = Color(0xFFF39C12);
  static const Color statusAssigned = Color(0xFF3498DB);
  static const Color statusInProgress = Color(0xFF9B59B6);
  static const Color statusArrived = Color(0xFF1ABC9C);
  static const Color statusCompleted = Color(0xFF27AE60);
  static const Color statusCancelled = Color(0xFFE74C3C);

  // Neutral
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F3F4);
  static const Color divider = Color(0xFFECF0F1);

  // Text
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);
  static const Color textHint = Color(0xFFBDC3C7);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Shadow
  static const Color shadow = Color(0x1A000000);
  static const Color shadowMedium = Color(0x26000000);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient collectorGradient = LinearGradient(
    colors: [collectorPrimary, collectorPrimaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
