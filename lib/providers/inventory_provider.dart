import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
import '../services/firestore_service.dart';
import '../constants/app_constants.dart';

class InventoryProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<InventoryItem> _items = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String? _selectedCategory;

  List<InventoryItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;

  InventoryProvider() {
    loadInventory();
  }

  Future<void> loadInventory() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _items = await _firestoreService.getInventoryItems();
    } catch (e) {
      _errorMessage = 'Failed to load inventory: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Dashboard Metrics
  int get totalItems => _items.length;

  int get totalCategories {
    final categoriesInUse = _items.map((i) => i.category).toSet();
    return categoriesInUse.isEmpty ? AppConstants.categories.length : categoriesInUse.length;
  }

  double get totalInventoryValue {
    return _items.fold(0.0, (sum, item) => sum + item.totalValue);
  }

  List<InventoryItem> get lowStockItems {
    return _items.where((item) => item.isLowStock).toList();
  }

  int get lowStockCount => lowStockItems.length;

  // Filtered Items (by Category and Search Query)
  List<InventoryItem> get filteredItems {
    return _items.where((item) {
      final matchesCategory = _selectedCategory == null || item.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.category.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  // Items in a specific category
  List<InventoryItem> getItemsByCategory(String category) {
    return _items.where((item) => item.category == category).toList();
  }

  // Count items per category
  Map<String, int> get categoryCounts {
    final Map<String, int> counts = {
      for (var cat in AppConstants.categories) cat: 0
    };
    for (var item in _items) {
      counts[item.category] = (counts[item.category] ?? 0) + 1;
    }
    return counts;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<bool> addItem(InventoryItem item) async {
    try {
      await _firestoreService.addInventoryItem(item);
      await loadInventory();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add item: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateItem(InventoryItem item) async {
    try {
      await _firestoreService.updateInventoryItem(item);
      await loadInventory();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update item: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteItem(String itemId) async {
    try {
      await _firestoreService.deleteInventoryItem(itemId);
      await loadInventory();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete item: $e';
      notifyListeners();
      return false;
    }
  }
}
