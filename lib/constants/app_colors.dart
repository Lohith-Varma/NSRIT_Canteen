import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette - Deep Emerald & Teal
  static const Color primary = Color(0xFF0F5132);
  static const Color primaryLight = Color(0xFF198754);
  static const Color primaryDark = Color(0xFF0A3622);
  static const Color onPrimary = Colors.white;

  // Secondary Palette - Warm Amber / Gold Accent
  static const Color secondary = Color(0xFFD97706);
  static const Color secondaryLight = Color(0xFFF59E0B);
  static const Color onSecondary = Colors.white;

  // Status & Badges
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Light Theme Neutral Colors
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCardBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // Dark Theme Neutral Colors
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkCardBorder = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // Category Accent Colors
  static const Map<String, Color> categoryColors = {
    'Vegetables': Color(0xFF22C55E),
    'Fruits': Color(0xFFEF4444),
    'Grains': Color(0xFFF59E0B),
    'Dairy': Color(0xFF3B82F6),
    'Spices': Color(0xFF8B5CF6),
    'Oils': Color(0xFFEC4899),
    'Beverages': Color(0xFF06B6D4),
    'Snacks': Color(0xFFF97316),
    'Cleaning Supplies': Color(0xFF14B8A6),
    'Packaging Materials': Color(0xFF6366F1),
  };

  static Color getCategoryColor(String category) {
    return categoryColors[category] ?? primary;
  }
}
