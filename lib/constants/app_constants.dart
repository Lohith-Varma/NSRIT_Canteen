import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'College Canteen Inventory';

  // Supported Categories
  static const List<String> categories = [
    'Vegetables',
    'Fruits',
    'Grains',
    'Dairy',
    'Spices',
    'Oils',
    'Beverages',
    'Snacks',
    'Cleaning Supplies',
    'Packaging Materials',
  ];

  // Category Icons mapping
  static const Map<String, IconData> categoryIcons = {
    'Vegetables': Icons.eco_rounded,
    'Fruits': Icons.apple_rounded,
    'Grains': Icons.grain_rounded,
    'Dairy': Icons.water_drop_rounded,
    'Spices': Icons.flare_rounded,
    'Oils': Icons.opacity_rounded,
    'Beverages': Icons.local_cafe_rounded,
    'Snacks': Icons.fastfood_rounded,
    'Cleaning Supplies': Icons.cleaning_services_rounded,
    'Packaging Materials': Icons.inventory_2_rounded,
  };

  static IconData getCategoryIcon(String category) {
    return categoryIcons[category] ?? Icons.category_rounded;
  }

  // Supported Stock Units
  static const List<String> units = [
    'kg',
    'g',
    'litre',
    'ml',
    'pieces',
    'packets',
    'boxes',
  ];

  // Firestore Collection Names
  static const String usersCollection = 'users';
  static const String itemsCollection = 'inventory_items';
  static const String lotsCollection = 'inventory_lots';
  static const String suppliersCollection = 'suppliers';
  static const String purchasesCollection = 'purchases';
}
