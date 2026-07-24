import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'College Canteen Inventory';

  // Supported Categories
  static const List<String> categories = [
    'Vegetables',
    'Fruits',
    'Grains',
    'Pulses',
    'Dairy',
    'Spices',
    'Oils',
    'Beverages',
    'Bakery',
    'Snacks',
    'Cleaning Supplies',
    'Packaging Materials',
  ];

  // Category Icons mapping
  static const Map<String, IconData> categoryIcons = {
    'Vegetables': Icons.eco_rounded,
    'Fruits': Icons.apple_rounded,
    'Grains': Icons.grain_rounded,
    'Pulses': Icons.spa_rounded,
    'Dairy': Icons.water_drop_rounded,
    'Spices': Icons.flare_rounded,
    'Oils': Icons.opacity_rounded,
    'Beverages': Icons.local_cafe_rounded,
    'Bakery': Icons.bakery_dining_rounded,
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
  static const String inventoryCollection = 'inventory';
  static const String categoriesCollection = 'categories';
  static const String itemsCollection = 'inventory_items';
  static const String lotsCollection = 'inventory_lots';
  static const String suppliersCollection = 'suppliers';
  static const String purchasesCollection = 'purchases';
  static const String menuItemsCollection = 'menu_items';
  static const String recipesCollection = 'recipes';
  static const String preparedFoodCollection = 'prepared_food';
  static const String salesCollection = 'sales';
  static const String stockMovementsCollection = 'stock_movements';
  static const String settingsCollection = 'settings';
  static const String notificationsCollection = 'notifications';
}
