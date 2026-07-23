import 'dart:async';

import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
import '../constants/app_constants.dart';
import '../services/inventory_service.dart';

enum InventorySortOption {
  nameAsc,
  nameDesc,
  quantityLow,
  quantityHigh,
  updatedNewest,
  expirySoon,
}

class InventoryProvider extends ChangeNotifier {
  final InventoryService _inventoryService = InventoryService();

  List<InventoryItem> _items = [];
  List<String> _categories = List<String>.from(AppConstants.categories);
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedStatus;
  InventorySortOption _sortOption = InventorySortOption.nameAsc;
  StreamSubscription<List<InventoryItem>>? _inventorySubscription;
  StreamSubscription<List<String>>? _categorySubscription;

  List<InventoryItem> get items => _items;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;
  String? get selectedStatus => _selectedStatus;
  InventorySortOption get sortOption => _sortOption;

  InventoryProvider() {
    startRealtimeSync();
  }

  void startRealtimeSync() {
    _isLoading = true;
    notifyListeners();

    _inventorySubscription?.cancel();
    _categorySubscription?.cancel();

    _inventorySubscription = _inventoryService.watchInventoryItems().listen(
      (items) {
        _items = items;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (Object error) {
        _errorMessage = 'Failed to sync inventory: $error';
        _isLoading = false;
        notifyListeners();
      },
    );

    _categorySubscription = _inventoryService.watchCategories().listen(
      (categories) {
        _categories = categories;
        notifyListeners();
      },
      onError: (Object error) {
        _errorMessage = 'Failed to sync categories: $error';
        notifyListeners();
      },
    );
  }

  Future<void> loadInventory() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _items = await _inventoryService.getInventoryItems();
      _categories = await _inventoryService.getCategories();
    } catch (e) {
      _errorMessage = 'Failed to load inventory: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Dashboard Metrics
  int get totalItems => _items.length;

  int get outOfStockCount => _items.where((item) => item.isOutOfStock).length;

  int get healthyStockCount {
    return _items.where((item) => !item.isOutOfStock && !item.isLowStock).length;
  }

  int get totalCategories {
    final categoriesInUse = _items.map((i) => i.category).toSet();
    return categoriesInUse.isEmpty ? _categories.length : categoriesInUse.length;
  }

  double get totalInventoryValue {
    return _items.fold(0.0, (sum, item) => sum + item.totalValue);
  }

  List<InventoryItem> get lowStockItems {
    return _items.where((item) => item.isLowStock).toList();
  }

  int get lowStockCount => lowStockItems.length;

  List<InventoryItem> get outOfStockItems {
    return _items.where((item) => item.isOutOfStock).toList();
  }

  // Filtered Items (by Category and Search Query)
  List<InventoryItem> get filteredItems {
    final filtered = _items.where((item) {
      final matchesCategory = _selectedCategory == null || item.category == _selectedCategory;
      final matchesStatus = _selectedStatus == null ||
          item.status == _selectedStatus ||
          (_selectedStatus == 'low_stock' && item.isLowStock) ||
          (_selectedStatus == 'out_of_stock' && item.isOutOfStock);
      final matchesSearch = _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.supplier.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.storageLocation.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesStatus && matchesSearch;
    }).toList();

    filtered.sort((a, b) {
      switch (_sortOption) {
        case InventorySortOption.nameAsc:
          return a.itemName.toLowerCase().compareTo(b.itemName.toLowerCase());
        case InventorySortOption.nameDesc:
          return b.itemName.toLowerCase().compareTo(a.itemName.toLowerCase());
        case InventorySortOption.quantityLow:
          return a.totalStock.compareTo(b.totalStock);
        case InventorySortOption.quantityHigh:
          return b.totalStock.compareTo(a.totalStock);
        case InventorySortOption.updatedNewest:
          return b.updatedAt.compareTo(a.updatedAt);
        case InventorySortOption.expirySoon:
          final aExpiry = a.expiryDate ?? DateTime(9999);
          final bExpiry = b.expiryDate ?? DateTime(9999);
          return aExpiry.compareTo(bExpiry);
      }
    });

    return filtered;
  }

  // Items in a specific category
  List<InventoryItem> getItemsByCategory(String category) {
    return _items.where((item) => item.category == category).toList();
  }

  // Count items per category
  Map<String, int> get categoryCounts {
    final Map<String, int> counts = {
      for (var cat in _categories) cat: 0
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

  void setSelectedStatus(String? status) {
    _selectedStatus = status;
    notifyListeners();
  }

  void setSortOption(InventorySortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _selectedStatus = null;
    _sortOption = InventorySortOption.nameAsc;
    notifyListeners();
  }

  Future<bool> addItem(InventoryItem item) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _inventoryService.addInventoryItem(item);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add item: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateItem(InventoryItem item) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _inventoryService.updateInventoryItem(item);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update item: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteItem(String itemId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _inventoryService.softDeleteInventoryItem(itemId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete item: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> addCategory(String category) async {
    try {
      await _inventoryService.addCategory(category);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add category: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCategory(String category) async {
    if (_items.any((item) => item.category == category)) {
      _errorMessage = 'Move or delete items in this category before removing it.';
      notifyListeners();
      return false;
    }

    try {
      await _inventoryService.deleteCategory(category);
      _categories.remove(category);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete category: $e';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _inventorySubscription?.cancel();
    _categorySubscription?.cancel();
    super.dispose();
  }
}
