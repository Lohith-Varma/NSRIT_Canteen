import 'package:flutter/material.dart';

import '../models/inventory_item.dart';
import '../models/menu_item_model.dart';
import '../models/prepared_food_model.dart';
import '../models/recipe_model.dart';
import '../models/sale_model.dart';
import '../models/stock_movement_model.dart';
import '../services/kitchen_service.dart';

class KitchenProvider extends ChangeNotifier {
  final KitchenService _kitchenService = KitchenService();

  List<MenuItemModel> _menuItems = [];
  List<RecipeModel> _recipes = [];
  List<PreparedFoodModel> _preparedFood = [];
  List<SaleModel> _sales = [];
  List<StockMovementModel> _stockMovements = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _menuSearchQuery = '';
  String _recipeSearchQuery = '';
  String _salesSearchQuery = '';

  List<MenuItemModel> get menuItems => _menuItems;
  List<RecipeModel> get recipes => _recipes;
  List<PreparedFoodModel> get preparedFood => _preparedFood;
  List<SaleModel> get sales => _sales;
  List<StockMovementModel> get stockMovements => _stockMovements;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get menuSearchQuery => _menuSearchQuery;
  String get recipeSearchQuery => _recipeSearchQuery;
  String get salesSearchQuery => _salesSearchQuery;

  int get totalMenuItems => _menuItems.length;
  double get totalSalesAmount {
    return _sales.fold(0.0, (sum, sale) => sum + sale.totalAmount);
  }

  double get preparedFoodAvailable {
    return _preparedFood.fold(0.0, (sum, food) => sum + food.quantityAvailable);
  }

  List<SaleModel> get recentSales => _sales.take(5).toList();

  KitchenProvider() {
    loadKitchenData();
  }

  Future<void> loadKitchenData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _kitchenService.getMenuItems(),
        _kitchenService.getRecipes(),
        _kitchenService.getPreparedFood(),
        _kitchenService.getSales(),
        _kitchenService.getStockMovements(),
      ]);
      _menuItems = results[0] as List<MenuItemModel>;
      _recipes = results[1] as List<RecipeModel>;
      _preparedFood = results[2] as List<PreparedFoodModel>;
      _sales = results[3] as List<SaleModel>;
      _stockMovements = results[4] as List<StockMovementModel>;
    } catch (e) {
      _errorMessage = 'Failed to load kitchen data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<String> get sections => const [
        'Breakfast',
        'Lunch',
        'Evening Snacks',
        'Dinner',
      ];

  List<MenuItemModel> menuItemsBySection(String section) {
    final query = _menuSearchQuery.toLowerCase();
    return _menuItems.where((item) {
      final matchesSection = item.section == section;
      final matchesSearch = query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.section.toLowerCase().contains(query);
      return matchesSection && matchesSearch;
    }).toList();
  }

  List<RecipeModel> get filteredRecipes {
    final query = _recipeSearchQuery.toLowerCase();
    if (query.isEmpty) return _recipes;
    return _recipes.where((recipe) {
      return recipe.menuItemName.toLowerCase().contains(query) ||
          recipe.ingredients.any(
            (ingredient) => ingredient.ingredientName.toLowerCase().contains(query),
          );
    }).toList();
  }

  List<SaleModel> get filteredSales {
    final query = _salesSearchQuery.toLowerCase();
    if (query.isEmpty) return _sales;
    return _sales.where((sale) {
      return sale.menuItemName.toLowerCase().contains(query) ||
          sale.paymentMethod.toLowerCase().contains(query) ||
          sale.soldBy.toLowerCase().contains(query);
    }).toList();
  }

  RecipeModel? recipeForMenuItem(String menuItemId) {
    for (final recipe in _recipes) {
      if (recipe.menuItemId == menuItemId) return recipe;
    }
    return null;
  }

  double preparedQuantityForMenuItem(String menuItemId) {
    return _preparedFood
        .where((food) => food.menuItemId == menuItemId)
        .fold(0.0, (sum, food) => sum + food.quantityAvailable);
  }

  bool isMenuItemAvailable(MenuItemModel item, List<InventoryItem> inventoryItems) {
    final recipe = recipeForMenuItem(item.id);
    if (recipe == null || !item.isActive) return false;

    for (final ingredient in recipe.ingredients) {
      final inventoryItem = _findInventoryItem(inventoryItems, ingredient.ingredientName);
      if (inventoryItem == null || inventoryItem.totalStock < ingredient.quantity) {
        return false;
      }
    }
    return true;
  }

  Future<PreparationPreview> buildPreparationPreview({
    required MenuItemModel menuItem,
    required double preparationQuantity,
  }) async {
    final recipe = recipeForMenuItem(menuItem.id);
    if (recipe == null) {
      throw Exception('Recipe not found for ${menuItem.name}.');
    }
    return _kitchenService.buildPreparationPreview(
      menuItem: menuItem,
      recipe: recipe,
      preparationQuantity: preparationQuantity,
    );
  }

  Future<bool> prepareMenuItem({
    required MenuItemModel menuItem,
    required double preparationQuantity,
    required String user,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final recipe = recipeForMenuItem(menuItem.id);
      if (recipe == null) {
        throw Exception('Recipe not found for ${menuItem.name}.');
      }
      await _kitchenService.prepareMenuItem(
        menuItem: menuItem,
        recipe: recipe,
        preparationQuantity: preparationQuantity,
        user: user,
      );
      await loadKitchenData();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeSale({
    required MenuItemModel menuItem,
    required double quantity,
    required String paymentMethod,
    required String user,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _kitchenService.completeSale(
        menuItem: menuItem,
        quantity: quantity,
        paymentMethod: paymentMethod,
        user: user,
      );
      await loadKitchenData();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateRecipe(RecipeModel recipe) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _kitchenService.updateRecipe(recipe);
      await loadKitchenData();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update recipe: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void setMenuSearchQuery(String query) {
    _menuSearchQuery = query;
    notifyListeners();
  }

  void setRecipeSearchQuery(String query) {
    _recipeSearchQuery = query;
    notifyListeners();
  }

  void setSalesSearchQuery(String query) {
    _salesSearchQuery = query;
    notifyListeners();
  }

  InventoryItem? _findInventoryItem(List<InventoryItem> items, String ingredientName) {
    final ingredientKey = _normalize(ingredientName);
    for (final item in items) {
      final itemKey = _normalize(item.itemName);
      final categoryKey = _normalize(item.category);
      if (itemKey == ingredientKey ||
          categoryKey == ingredientKey ||
          itemKey.contains(ingredientKey) ||
          ingredientKey.contains(itemKey)) {
        return item;
      }
    }
    return null;
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}
