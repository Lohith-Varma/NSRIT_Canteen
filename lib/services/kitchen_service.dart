import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/app_constants.dart';
import '../models/inventory_item.dart';
import '../models/inventory_lot.dart';
import '../models/menu_item_model.dart';
import '../models/prepared_food_model.dart';
import '../models/recipe_model.dart';
import '../models/sale_model.dart';
import '../models/stock_movement_model.dart';
import 'inventory_service.dart';

class PreparationPreview {
  final RecipeModel recipe;
  final Map<String, InventoryItem?> inventoryByIngredient;
  final Map<String, double> requiredQuantityByIngredient;
  final Map<String, double> availableQuantityByIngredient;
  final Map<String, double> estimatedCostByIngredient;
  final bool canPrepare;
  final double ingredientCost;
  final double preparationCost;
  final double actualFoodCost;

  const PreparationPreview({
    required this.recipe,
    required this.inventoryByIngredient,
    required this.requiredQuantityByIngredient,
    required this.availableQuantityByIngredient,
    required this.estimatedCostByIngredient,
    required this.canPrepare,
    required this.ingredientCost,
    required this.preparationCost,
    required this.actualFoodCost,
  });
}

class KitchenService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final InventoryService _inventoryService = InventoryService();

  Future<List<MenuItemModel>> getMenuItems() async {
    final snapshot = await _db
        .collection(AppConstants.menuItemsCollection)
        .get();
    final items = snapshot.docs
        .map((doc) => MenuItemModel.fromMap(doc.data(), doc.id))
        .toList();
    items.sort((a, b) => a.name.compareTo(b.name));
    return items;
  }

  Future<void> addMenuItem(MenuItemModel item) async {
    final ref = _db.collection(AppConstants.menuItemsCollection).doc();
    final now = DateTime.now();
    final itemToSave = MenuItemModel(
      id: ref.id,
      name: item.name,
      section: item.section,
      imageUrl: item.imageUrl,
      sellingPrice: item.sellingPrice,
      isActive: item.isActive,
      createdAt: now,
      updatedAt: now,
    );
    await ref.set(itemToSave.toMap());
  }

  Future<void> updateMenuItem(MenuItemModel item) async {
    final updatedItem = MenuItemModel(
      id: item.id,
      name: item.name,
      section: item.section,
      imageUrl: item.imageUrl,
      sellingPrice: item.sellingPrice,
      isActive: item.isActive,
      createdAt: item.createdAt,
      updatedAt: DateTime.now(),
    );
    await _db
        .collection(AppConstants.menuItemsCollection)
        .doc(item.id)
        .update(updatedItem.toMap());
  }

  Future<void> deleteMenuItem(String id) async {
    await _db.collection(AppConstants.menuItemsCollection).doc(id).delete();
  }

  Future<List<RecipeModel>> getRecipes() async {
    final snapshot = await _db.collection(AppConstants.recipesCollection).get();
    return snapshot.docs
        .map((doc) => RecipeModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<PreparedFoodModel>> getPreparedFood() async {
    final snapshot = await _db
        .collection(AppConstants.preparedFoodCollection)
        .orderBy('preparedAt', descending: true)
        .limit(100)
        .get();
    return snapshot.docs
        .map((doc) => PreparedFoodModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<SaleModel>> getSales() async {
    final snapshot = await _db
        .collection(AppConstants.salesCollection)
        .orderBy('soldAt', descending: true)
        .limit(150)
        .get();
    return snapshot.docs
        .map((doc) => SaleModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<StockMovementModel>> getStockMovements() async {
    final snapshot = await _db
        .collection(AppConstants.stockMovementsCollection)
        .orderBy('dateTime', descending: true)
        .limit(200)
        .get();
    return snapshot.docs
        .map((doc) => StockMovementModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> updateRecipe(RecipeModel recipe) async {
    final updatedRecipe = recipe.copyWith(updatedAt: DateTime.now());
    await _db
        .collection(AppConstants.recipesCollection)
        .doc(updatedRecipe.id)
        .update(updatedRecipe.toMap());
  }

  Future<PreparationPreview> buildPreparationPreview({
    required MenuItemModel menuItem,
    required RecipeModel recipe,
    required Map<String, double> ingredientQuantities,
  }) async {
    final inventoryItems = await _inventoryService.getInventoryItems();
    final inventoryByIngredient = <String, InventoryItem?>{};
    final requiredByIngredient = <String, double>{};
    final availableByIngredient = <String, double>{};
    final estimatedCostByIngredient = <String, double>{};
    var canPrepare = ingredientQuantities.values.any(
      (quantity) => quantity > 0,
    );
    var ingredientCost = 0.0;

    for (final entry in ingredientQuantities.entries) {
      final ingredientName = entry.key.trim();
      final requiredQuantity = entry.value;
      if (ingredientName.isEmpty) continue;
      final inventoryItem = _findInventoryItem(inventoryItems, ingredientName);
      final availableQuantity = inventoryItem?.totalStock ?? 0.0;
      final estimatedCost = _estimateFifoCost(inventoryItem, requiredQuantity);

      inventoryByIngredient[ingredientName] = inventoryItem;
      requiredByIngredient[ingredientName] = requiredQuantity;
      availableByIngredient[ingredientName] = availableQuantity;
      estimatedCostByIngredient[ingredientName] = estimatedCost;
      ingredientCost += estimatedCost;

      if (requiredQuantity > 0 &&
          (inventoryItem == null || availableQuantity < requiredQuantity)) {
        canPrepare = false;
      }
    }

    final preparationCost = recipe.preparationCostPerUnit;
    return PreparationPreview(
      recipe: recipe,
      inventoryByIngredient: inventoryByIngredient,
      requiredQuantityByIngredient: requiredByIngredient,
      availableQuantityByIngredient: availableByIngredient,
      estimatedCostByIngredient: estimatedCostByIngredient,
      canPrepare: canPrepare,
      ingredientCost: ingredientCost,
      preparationCost: preparationCost,
      actualFoodCost: ingredientCost + preparationCost,
    );
  }

  Future<void> prepareMenuItem({
    required MenuItemModel menuItem,
    required RecipeModel recipe,
    required Map<String, double> ingredientQuantities,
    required String user,
  }) async {
    if (!ingredientQuantities.values.any((quantity) => quantity > 0)) {
      throw Exception('Enter quantity used for at least one ingredient.');
    }

    final preparationId = 'prep_${DateTime.now().millisecondsSinceEpoch}';
    final preview = await buildPreparationPreview(
      menuItem: menuItem,
      recipe: recipe,
      ingredientQuantities: ingredientQuantities,
    );
    if (!preview.canPrepare) {
      throw Exception('Insufficient inventory for ${menuItem.name}.');
    }

    await _prepareMenuItemInFirestore(
      preparationId: preparationId,
      menuItem: menuItem,
      recipe: recipe,
      ingredientQuantities: ingredientQuantities,
      user: user,
    );
  }

  Future<void> completeSale({
    required MenuItemModel menuItem,
    required double quantity,
    required String paymentMethod,
    required String user,
  }) async {
    if (quantity <= 0) {
      throw Exception('Sale quantity must be greater than zero.');
    }

    final saleId = 'sale_${DateTime.now().millisecondsSinceEpoch}';
    await _completeSaleInFirestore(
      saleId: saleId,
      menuItem: menuItem,
      quantity: quantity,
      paymentMethod: paymentMethod,
      user: user,
    );
  }

  Future<void> _prepareMenuItemInFirestore({
    required String preparationId,
    required MenuItemModel menuItem,
    required RecipeModel recipe,
    required Map<String, double> ingredientQuantities,
    required String user,
  }) async {
    await _db.runTransaction((transaction) async {
      final inventorySnapshot = await _db
          .collection(AppConstants.inventoryCollection)
          .where('isDeleted', isEqualTo: false)
          .get();
      final lotSnapshot = await _db
          .collection(AppConstants.lotsCollection)
          .orderBy('purchaseDate')
          .get();

      final inventoryItems = inventorySnapshot.docs.map((doc) {
        final lots = lotSnapshot.docs
            .where((lotDoc) => lotDoc.data()['itemId'] == doc.id)
            .map((lotDoc) => InventoryLot.fromMap(lotDoc.data(), lotDoc.id))
            .toList();
        return InventoryItem.fromMap(doc.data(), doc.id, lots: lots);
      }).toList();

      final lotConsumptions = <LotConsumption>[];
      var ingredientCost = 0.0;

      for (final entry in ingredientQuantities.entries) {
        final ingredientName = entry.key.trim();
        final requiredQuantity = entry.value;
        if (ingredientName.isEmpty || requiredQuantity <= 0) continue;

        final inventoryItem = _findInventoryItem(
          inventoryItems,
          ingredientName,
        );
        if (inventoryItem == null ||
            inventoryItem.totalStock < requiredQuantity) {
          throw Exception('Insufficient $ingredientName.');
        }

        var remaining = requiredQuantity;
        final lots = List<InventoryLot>.from(inventoryItem.lots)
          ..sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));
        for (final lot in lots) {
          if (remaining <= 0) break;
          if (lot.quantity <= 0) continue;

          final consumed = remaining > lot.quantity ? lot.quantity : remaining;
          final totalCost = consumed * lot.unitPrice;
          ingredientCost += totalCost;
          lotConsumptions.add(
            LotConsumption(
              inventoryItemId: inventoryItem.id,
              ingredientName: ingredientName,
              lotId: lot.id,
              quantity: consumed,
              unit: lot.unit,
              unitCost: lot.unitPrice,
              totalCost: totalCost,
            ),
          );

          transaction.update(
            _db.collection(AppConstants.lotsCollection).doc(lot.id),
            {'quantity': lot.quantity - consumed},
          );
          remaining -= consumed;
        }

        transaction.update(
          _db
              .collection(AppConstants.inventoryCollection)
              .doc(inventoryItem.id),
          {
            'quantity': inventoryItem.totalStock - requiredQuantity,
            'updatedAt': DateTime.now().toIso8601String(),
          },
        );

        final movementId = 'mov_${preparationId}_${lotConsumptions.length}';
        transaction.set(
          _db.collection(AppConstants.stockMovementsCollection).doc(movementId),
          StockMovementModel(
            id: movementId,
            dateTime: DateTime.now(),
            action: 'Food Preparation',
            reference: preparationId,
            itemName: ingredientName,
            quantity: -requiredQuantity,
            unit: inventoryItem.unit,
            user: user,
          ).toMap(),
        );
      }

      final preparationCost = recipe.preparationCostPerUnit;
      final preparedFood = PreparedFoodModel(
        id: preparationId,
        menuItemId: menuItem.id,
        menuItemName: menuItem.name,
        quantityPrepared: 1,
        quantityAvailable: 1,
        ingredientCost: ingredientCost,
        preparationCost: preparationCost,
        actualFoodCost: ingredientCost + preparationCost,
        sellingPrice: menuItem.sellingPrice,
        lotConsumptions: lotConsumptions,
        preparedAt: DateTime.now(),
        preparedBy: user,
      );
      transaction.set(
        _db.collection(AppConstants.preparedFoodCollection).doc(preparationId),
        preparedFood.toMap(),
      );
    });
  }

  Future<void> _completeSaleInFirestore({
    required String saleId,
    required MenuItemModel menuItem,
    required double quantity,
    required String paymentMethod,
    required String user,
  }) async {
    await _db.runTransaction((transaction) async {
      final preparedSnapshot = await _db
          .collection(AppConstants.preparedFoodCollection)
          .where('menuItemId', isEqualTo: menuItem.id)
          .where('quantityAvailable', isGreaterThan: 0)
          .orderBy('quantityAvailable')
          .get();

      final batches =
          preparedSnapshot.docs
              .map((doc) => PreparedFoodModel.fromMap(doc.data(), doc.id))
              .toList()
            ..sort((a, b) => a.preparedAt.compareTo(b.preparedAt));
      final available = batches.fold(
        0.0,
        (total, food) => total + food.quantityAvailable,
      );
      if (available < quantity) {
        throw Exception('Only $available prepared units are available.');
      }

      var remaining = quantity;
      for (final batch in batches) {
        if (remaining <= 0) break;
        final used = remaining > batch.quantityAvailable
            ? batch.quantityAvailable
            : remaining;
        transaction.update(
          _db.collection(AppConstants.preparedFoodCollection).doc(batch.id),
          {'quantityAvailable': batch.quantityAvailable - used},
        );
        remaining -= used;
      }

      final sale = SaleModel(
        id: saleId,
        menuItemId: menuItem.id,
        menuItemName: menuItem.name,
        quantity: quantity,
        unitPrice: menuItem.sellingPrice,
        totalAmount: menuItem.sellingPrice * quantity,
        paymentMethod: paymentMethod,
        soldAt: DateTime.now(),
        soldBy: user,
      );
      transaction.set(
        _db.collection(AppConstants.salesCollection).doc(saleId),
        sale.toMap(),
      );

      final movementId = 'mov_$saleId';
      transaction.set(
        _db.collection(AppConstants.stockMovementsCollection).doc(movementId),
        StockMovementModel(
          id: movementId,
          dateTime: DateTime.now(),
          action: 'Sales',
          reference: saleId,
          itemName: menuItem.name,
          quantity: -quantity,
          unit: 'prepared units',
          user: user,
        ).toMap(),
      );
    });
  }

  InventoryItem? _findInventoryItem(
    List<InventoryItem> items,
    String ingredientName,
  ) {
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

  double _estimateFifoCost(InventoryItem? item, double requiredQuantity) {
    if (item == null || requiredQuantity <= 0) return 0.0;
    var remaining = requiredQuantity;
    var cost = 0.0;
    final lots = List<InventoryLot>.from(item.lots)
      ..sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));

    if (lots.isEmpty) {
      return requiredQuantity * item.averageCost;
    }

    for (final lot in lots) {
      if (remaining <= 0) break;
      if (lot.quantity <= 0) continue;
      final consumed = remaining > lot.quantity ? lot.quantity : remaining;
      cost += consumed * lot.unitPrice;
      remaining -= consumed;
    }
    return cost;
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}
