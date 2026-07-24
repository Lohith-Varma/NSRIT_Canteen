import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/app_constants.dart';

class DemoSeedService {
  DemoSeedService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  final Random _random = Random(42);

  Future<void> seedIfEmpty() async {
    final existingInventory = await _db
        .collection(AppConstants.inventoryCollection)
        .limit(1)
        .get();
    final existingSuppliers = await _db
        .collection(AppConstants.suppliersCollection)
        .limit(1)
        .get();
    final existingMenu = await _db
        .collection(AppConstants.menuItemsCollection)
        .limit(1)
        .get();

    if (existingMenu.docs.isNotEmpty) {
      return;
    }

    if (existingInventory.docs.isEmpty && existingSuppliers.docs.isEmpty) {
      await _seedDemoData();
    } else {
      await _seedMenuData();
    }
  }

  Future<void> _seedMenuData() async {
    final now = DateTime.now();
    final batch = _db.batch();

    for (final menu in _menuItems(now)) {
      batch.set(_db.collection(AppConstants.menuItemsCollection).doc(menu.id), {
        'id': menu.id,
        'name': menu.name,
        'section': menu.section,
        'imageUrl': _imageUrl(menu.imageQuery),
        'sellingPrice': menu.price,
        'isActive': true,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      });
    }

    await batch.commit();
  }

  Future<void> _seedDemoData() async {
    final now = DateTime.now();
    final batches = <WriteBatch>[];
    var batch = _db.batch();
    var batchSize = 0;

    void write(
      DocumentReference<Map<String, dynamic>> reference,
      Map<String, dynamic> data, {
      bool merge = false,
    }) {
      if (merge) {
        batch.set(reference, data, SetOptions(merge: true));
      } else {
        batch.set(reference, data);
      }
      batchSize++;
      if (batchSize == 450) {
        batches.add(batch);
        batch = _db.batch();
        batchSize = 0;
      }
    }

    for (final category in AppConstants.categories) {
      write(
        _db.collection(AppConstants.categoriesCollection).doc(category),
        {'name': category, 'createdAt': now.toIso8601String()},
        merge: true,
      );
    }

    final suppliers = _suppliers(now);
    for (final supplier in suppliers) {
      write(
        _db.collection(AppConstants.suppliersCollection).doc(supplier.id),
        supplier.toMap(),
      );
    }

    final items = _inventoryItems();
    final lotsByItem = <String, List<_SeedLot>>{
      for (final item in items) item.id: <_SeedLot>[],
    };
    final stockByItem = <String, double>{for (final item in items) item.id: 0};
    final lastPriceByItem = <String, double>{};
    final purchases = <_SeedPurchase>[];

    for (var i = 0; i < 150; i++) {
      final item = items[i % items.length];
      final supplier = suppliers[(i * 7) % suppliers.length];
      final purchaseId = 'demo_purchase_${(i + 1).toString().padLeft(3, '0')}';
      final lotId = 'demo_lot_${(i + 1).toString().padLeft(3, '0')}';
      final date = now.subtract(Duration(days: 120 - (i % 110), hours: i % 8));
      final price = _money(item.cost * (0.9 + ((i % 7) * 0.04)));
      final quantity = _quantityFor(item.unit, 1 + (i % 4), item.minimumStock);
      final invoice =
          'NSR-PUR-${date.year}${(i + 1).toString().padLeft(4, '0')}';

      purchases.add(
        _SeedPurchase(
          id: purchaseId,
          supplierId: supplier.id,
          supplierName: supplier.name,
          itemId: item.id,
          itemName: item.name,
          quantity: quantity,
          unit: item.unit,
          pricePerUnit: price,
          purchaseDate: date,
          invoiceNumber: invoice,
          createdAt: date.add(const Duration(hours: 2)),
        ),
      );
      lotsByItem[item.id]!.add(
        _SeedLot(
          id: lotId,
          itemId: item.id,
          purchaseId: purchaseId,
          quantity: quantity,
          unit: item.unit,
          unitPrice: price,
          purchaseDate: date,
          supplierId: supplier.id,
          invoiceNumber: invoice,
        ),
      );
      stockByItem[item.id] = (stockByItem[item.id] ?? 0) + quantity;
      lastPriceByItem[item.id] = price;
    }

    final menuItems = _menuItems(now);
    final recipeByMenu = _recipes(menuItems, now);
    final preparedFoods = <Map<String, dynamic>>[];
    final sales = <Map<String, dynamic>>[];
    final movements = <Map<String, dynamic>>[];

    for (final purchase in purchases) {
      movements.add({
        'id': 'mov_${purchase.id}',
        'dateTime': purchase.createdAt.toIso8601String(),
        'action': 'Purchases',
        'reference': purchase.invoiceNumber,
        'itemName': purchase.itemName,
        'quantity': purchase.quantity,
        'unit': purchase.unit,
        'user': purchase.supplierName,
      });
    }

    for (var i = 0; i < 72; i++) {
      final menu = menuItems[i % menuItems.length];
      final recipe = recipeByMenu[menu.id]!;
      final preparedAt = now.subtract(
        Duration(days: 45 - (i % 45), hours: i % 9),
      );
      final preparedId = 'demo_prep_${(i + 1).toString().padLeft(3, '0')}';
      var ingredientCost = 0.0;
      final lotConsumptions = <Map<String, dynamic>>[];

      for (final ingredient in recipe.ingredients) {
        final item = items.firstWhere((entry) => entry.name == ingredient.name);
        final consumed = _consumeLots(
          lotsByItem[item.id]!,
          ingredient.quantity,
          item.id,
          ingredient.name,
        );
        ingredientCost += consumed.fold(
          0,
          (runningTotal, lot) => runningTotal + (lot['totalCost'] as double),
        );
        lotConsumptions.addAll(consumed);
        stockByItem[item.id] =
            (stockByItem[item.id] ?? 0) - ingredient.quantity;
        movements.add({
          'id': 'mov_${preparedId}_${ingredient.name.replaceAll(' ', '_')}',
          'dateTime': preparedAt.toIso8601String(),
          'action': 'Food Preparation',
          'reference': preparedId,
          'itemName': ingredient.name,
          'quantity': -ingredient.quantity,
          'unit': ingredient.unit,
          'user': i.isEven ? 'Chef Ramesh' : 'Chef Lakshmi',
        });
      }

      final preparedQty = 14 + (i % 18);
      final soldQty = i < 52 ? 8 + (i % 12) : 4 + (i % 5);
      final availableQty = max(0, preparedQty - soldQty).toDouble();
      preparedFoods.add({
        'id': preparedId,
        'menuItemId': menu.id,
        'menuItemName': menu.name,
        'quantityPrepared': preparedQty.toDouble(),
        'quantityAvailable': availableQty,
        'ingredientCost': _money(ingredientCost),
        'preparationCost': recipe.preparationCost,
        'actualFoodCost': _money(ingredientCost + recipe.preparationCost),
        'sellingPrice': menu.price,
        'lotConsumptions': lotConsumptions,
        'preparedAt': preparedAt.toIso8601String(),
        'preparedBy': i.isEven ? 'Chef Ramesh' : 'Chef Lakshmi',
      });

      if (i < 52) {
        final saleId = 'demo_sale_${(i + 1).toString().padLeft(3, '0')}';
        final soldAt = preparedAt.add(Duration(hours: 2 + (i % 4)));
        sales.add({
          'id': saleId,
          'menuItemId': menu.id,
          'menuItemName': menu.name,
          'quantity': soldQty.toDouble(),
          'unitPrice': menu.price,
          'totalAmount': _money(menu.price * soldQty),
          'paymentMethod': ['Cash', 'UPI', 'Card'][i % 3],
          'soldAt': soldAt.toIso8601String(),
          'soldBy': i.isEven ? 'Counter A' : 'Counter B',
        });
        movements.add({
          'id': 'mov_$saleId',
          'dateTime': soldAt.toIso8601String(),
          'action': 'Sales',
          'reference': saleId,
          'itemName': menu.name,
          'quantity': -soldQty.toDouble(),
          'unit': 'prepared units',
          'user': i.isEven ? 'Counter A' : 'Counter B',
        });
      }
    }

    for (final item in items) {
      final remaining = max(0, stockByItem[item.id] ?? 0).toDouble();
      final purchasePrice = lastPriceByItem[item.id] ?? item.cost;
      write(_db.collection(AppConstants.inventoryCollection).doc(item.id), {
        'id': item.id,
        'itemName': item.name,
        'name': item.name,
        'category': item.category,
        'quantity': remaining,
        'unit': item.unit,
        'minimumStock': item.minimumStock,
        'minStock': item.minimumStock,
        'maximumStock': item.minimumStock * 8,
        'supplier': suppliers[items.indexOf(item) % suppliers.length].name,
        'purchasePrice': purchasePrice,
        'sellingPrice': 0,
        'storageLocation': item.storage,
        'imageUrl': _imageUrl(item.imageQuery),
        'expiryDate': item.expiryDays == null
            ? null
            : now.add(Duration(days: item.expiryDays!)).toIso8601String(),
        'notes': 'Demo stock seeded with FIFO purchase lots.',
        'createdAt': now.subtract(const Duration(days: 130)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'createdBy': 'Demo Seeder',
        'status': 'active',
        'isDeleted': false,
      });
    }

    for (final purchase in purchases) {
      write(
        _db.collection(AppConstants.purchasesCollection).doc(purchase.id),
        purchase.toMap(),
      );
    }
    for (final lots in lotsByItem.values) {
      for (final lot in lots) {
        write(
          _db.collection(AppConstants.lotsCollection).doc(lot.id),
          lot.toMap(),
        );
      }
    }
    for (final menu in menuItems) {
      write(_db.collection(AppConstants.menuItemsCollection).doc(menu.id), {
        'id': menu.id,
        'name': menu.name,
        'section': menu.section,
        'imageUrl': _imageUrl(menu.imageQuery),
        'sellingPrice': menu.price,
        'isActive': true,
        'createdAt': now.subtract(const Duration(days: 90)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
      });
    }
    for (final recipe in recipeByMenu.values) {
      write(_db.collection(AppConstants.recipesCollection).doc(recipe.id), {
        'id': recipe.id,
        'menuItemId': recipe.menuItemId,
        'menuItemName': recipe.menuItemName,
        'ingredients': recipe.ingredients
            .map(
              (ingredient) => {
                'ingredientName': ingredient.name,
                'quantity': ingredient.quantity,
                'unit': ingredient.unit,
              },
            )
            .toList(),
        'preparationCostPerUnit': recipe.preparationCost,
        'updatedAt': now.toIso8601String(),
      });
    }
    for (final food in preparedFoods) {
      write(
        _db
            .collection(AppConstants.preparedFoodCollection)
            .doc(food['id'] as String),
        food,
      );
    }
    for (final sale in sales) {
      write(
        _db.collection(AppConstants.salesCollection).doc(sale['id'] as String),
        sale,
      );
    }
    for (final movement in movements) {
      write(
        _db
            .collection(AppConstants.stockMovementsCollection)
            .doc(movement['id'] as String),
        movement,
      );
    }

    if (batchSize > 0) {
      batches.add(batch);
    }
    for (final pendingBatch in batches) {
      await pendingBatch.commit();
    }
  }

  List<Map<String, dynamic>> _consumeLots(
    List<_SeedLot> lots,
    double quantity,
    String itemId,
    String ingredientName,
  ) {
    var remaining = quantity;
    final consumptions = <Map<String, dynamic>>[];
    lots.sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));
    for (final lot in lots) {
      if (remaining <= 0) break;
      if (lot.quantity <= 0) continue;
      final used = min(remaining, lot.quantity).toDouble();
      lot.quantity -= used;
      remaining -= used;
      consumptions.add({
        'inventoryItemId': itemId,
        'ingredientName': ingredientName,
        'lotId': lot.id,
        'quantity': used,
        'unit': lot.unit,
        'unitCost': lot.unitPrice,
        'totalCost': _money(used * lot.unitPrice),
      });
    }
    return consumptions;
  }

  double _quantityFor(String unit, int multiplier, double minimumStock) {
    final base = unit == 'pieces'
        ? 80.0
        : unit == 'packets'
        ? 30.0
        : unit == 'boxes'
        ? 12.0
        : unit == 'litre'
        ? 18.0
        : 25.0;
    return max(base * multiplier, minimumStock * (1.5 + _random.nextDouble()));
  }

  double _money(double value) => double.parse(value.toStringAsFixed(2));

  String _imageUrl(String query) {
    final encoded = Uri.encodeComponent(query);
    return 'https://source.unsplash.com/600x400/?$encoded';
  }

  List<_SeedSupplier> _suppliers(DateTime now) {
    const names = [
      'Sri Venkateswara Rice Traders',
      'Godavari Fresh Vegetables',
      'Lakshmi Dairy Distributors',
      'Kakinada Spices Mart',
      'Annapurna Grains Depot',
      'Coastal Fresh Fruits',
      'Ravi Oils and Provisions',
      'Sai Bakery Supplies',
      'NSR Packaging House',
      'CleanPro Facility Supplies',
      'Andhra Pulses Wholesale',
      'Campus Beverage Agency',
      'Green Leaf Herb Suppliers',
      'Vijaya Frozen Foods',
      'Pragathi Egg Centre',
      'Sree Durga General Stores',
      'Fresh Basket Rajahmundry',
      'Amaravati Dairy Farms',
      'Elite Snacks Distributors',
      'Blue Star Cleaning Products',
    ];
    return [
      for (var i = 0; i < names.length; i++)
        _SeedSupplier(
          id: 'demo_supplier_${(i + 1).toString().padLeft(2, '0')}',
          name: names[i],
          phone: '9${(876540000 + i * 7319).toString().padLeft(9, '0')}',
          email:
              '${names[i].toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '.')}@example.com',
          address:
              '${12 + i}, Market Road, ${i.isEven ? 'Rajahmundry' : 'Kakinada'}, Andhra Pradesh',
          gstNumber: '37ABCDE${(1000 + i).toString()}Z${i % 9}',
          createdAt: now.subtract(Duration(days: 180 - i)),
        ),
    ];
  }

  List<_SeedInventoryItem> _inventoryItems() {
    final raw = <List<Object>>[
      ['Rice', 'Grains', 'kg', 45.0, 52.0, 'Dry Store A', 'raw rice grains'],
      [
        'Basmati Rice',
        'Grains',
        'kg',
        18.0,
        86.0,
        'Dry Store A',
        'basmati rice',
      ],
      ['Wheat Flour', 'Grains', 'kg', 22.0, 38.0, 'Dry Store A', 'wheat flour'],
      ['Maida', 'Grains', 'kg', 16.0, 42.0, 'Dry Store A', 'flour'],
      ['Rava', 'Grains', 'kg', 14.0, 44.0, 'Dry Store A', 'semolina'],
      ['Poha', 'Grains', 'kg', 10.0, 46.0, 'Dry Store A', 'flattened rice'],
      ['Bread', 'Bakery', 'packets', 12.0, 32.0, 'Bakery Rack', 'bread loaf'],
      [
        'Burger Buns',
        'Bakery',
        'packets',
        8.0,
        38.0,
        'Bakery Rack',
        'burger buns',
      ],
      [
        'Pizza Base',
        'Bakery',
        'packets',
        8.0,
        52.0,
        'Bakery Rack',
        'pizza base',
      ],
      ['Pav Buns', 'Bakery', 'packets', 10.0, 34.0, 'Bakery Rack', 'pav buns'],
      ['Toor Dal', 'Pulses', 'kg', 12.0, 112.0, 'Dry Store B', 'toor dal'],
      ['Moong Dal', 'Pulses', 'kg', 10.0, 118.0, 'Dry Store B', 'moong dal'],
      ['Chana Dal', 'Pulses', 'kg', 10.0, 86.0, 'Dry Store B', 'chana dal'],
      ['Urad Dal', 'Pulses', 'kg', 12.0, 124.0, 'Dry Store B', 'urad dal'],
      ['Rajma', 'Pulses', 'kg', 8.0, 132.0, 'Dry Store B', 'rajma beans'],
      ['Chickpeas', 'Pulses', 'kg', 8.0, 96.0, 'Dry Store B', 'chickpeas'],
      ['Salt', 'Spices', 'kg', 10.0, 18.0, 'Spice Shelf', 'salt'],
      ['Sugar', 'Grains', 'kg', 20.0, 44.0, 'Dry Store A', 'sugar'],
      ['Jaggery', 'Grains', 'kg', 8.0, 58.0, 'Dry Store A', 'jaggery'],
      ['Cooking Oil', 'Oils', 'litre', 24.0, 132.0, 'Oil Store', 'cooking oil'],
      [
        'Sunflower Oil',
        'Oils',
        'litre',
        16.0,
        142.0,
        'Oil Store',
        'sunflower oil',
      ],
      [
        'Groundnut Oil',
        'Oils',
        'litre',
        12.0,
        168.0,
        'Oil Store',
        'groundnut oil',
      ],
      ['Ghee', 'Dairy', 'kg', 6.0, 520.0, 'Cold Room', 'ghee'],
      ['Butter', 'Dairy', 'kg', 5.0, 480.0, 'Cold Room', 'butter'],
      ['Milk', 'Dairy', 'litre', 30.0, 58.0, 'Cold Room', 'milk'],
      ['Curd', 'Dairy', 'kg', 16.0, 70.0, 'Cold Room', 'curd'],
      ['Paneer', 'Dairy', 'kg', 8.0, 310.0, 'Cold Room', 'paneer'],
      ['Cheese', 'Dairy', 'kg', 6.0, 420.0, 'Cold Room', 'cheese'],
      ['Eggs', 'Dairy', 'pieces', 120.0, 6.5, 'Cold Room', 'eggs'],
      ['Tomato', 'Vegetables', 'kg', 24.0, 32.0, 'Vegetable Crate', 'tomato'],
      ['Onion', 'Vegetables', 'kg', 35.0, 30.0, 'Vegetable Crate', 'onion'],
      ['Potato', 'Vegetables', 'kg', 30.0, 28.0, 'Vegetable Crate', 'potato'],
      ['Carrot', 'Vegetables', 'kg', 14.0, 48.0, 'Vegetable Crate', 'carrot'],
      [
        'Beans',
        'Vegetables',
        'kg',
        10.0,
        62.0,
        'Vegetable Crate',
        'green beans',
      ],
      [
        'Capsicum',
        'Vegetables',
        'kg',
        10.0,
        76.0,
        'Vegetable Crate',
        'capsicum',
      ],
      ['Cabbage', 'Vegetables', 'kg', 12.0, 34.0, 'Vegetable Crate', 'cabbage'],
      [
        'Cauliflower',
        'Vegetables',
        'kg',
        10.0,
        46.0,
        'Vegetable Crate',
        'cauliflower',
      ],
      [
        'Green Chilli',
        'Vegetables',
        'kg',
        5.0,
        72.0,
        'Vegetable Crate',
        'green chilli',
      ],
      [
        'Coriander',
        'Vegetables',
        'kg',
        4.0,
        82.0,
        'Vegetable Crate',
        'coriander leaves',
      ],
      ['Mint', 'Vegetables', 'kg', 3.0, 90.0, 'Vegetable Crate', 'mint leaves'],
      ['Lemon', 'Fruits', 'pieces', 80.0, 3.5, 'Fruit Crate', 'lemons'],
      ['Banana', 'Fruits', 'kg', 20.0, 42.0, 'Fruit Crate', 'bananas'],
      ['Apple', 'Fruits', 'kg', 12.0, 165.0, 'Fruit Crate', 'apples'],
      ['Orange', 'Fruits', 'kg', 12.0, 92.0, 'Fruit Crate', 'oranges'],
      [
        'Tea Powder',
        'Beverages',
        'kg',
        6.0,
        280.0,
        'Beverage Shelf',
        'tea powder',
      ],
      [
        'Coffee Powder',
        'Beverages',
        'kg',
        5.0,
        420.0,
        'Beverage Shelf',
        'coffee powder',
      ],
      [
        'Boost Powder',
        'Beverages',
        'kg',
        4.0,
        360.0,
        'Beverage Shelf',
        'malt drink powder',
      ],
      [
        'Soft Drink Bottles',
        'Beverages',
        'pieces',
        60.0,
        22.0,
        'Beverage Rack',
        'soft drink bottles',
      ],
      [
        'Mineral Water Bottles',
        'Beverages',
        'pieces',
        100.0,
        10.0,
        'Beverage Rack',
        'water bottles',
      ],
      [
        'Soda Bottles',
        'Beverages',
        'pieces',
        50.0,
        14.0,
        'Beverage Rack',
        'soda bottles',
      ],
      [
        'Red Chilli Powder',
        'Spices',
        'kg',
        5.0,
        210.0,
        'Spice Shelf',
        'red chilli powder',
      ],
      [
        'Turmeric Powder',
        'Spices',
        'kg',
        4.0,
        180.0,
        'Spice Shelf',
        'turmeric powder',
      ],
      [
        'Coriander Powder',
        'Spices',
        'kg',
        5.0,
        170.0,
        'Spice Shelf',
        'coriander powder',
      ],
      [
        'Garam Masala',
        'Spices',
        'kg',
        3.0,
        360.0,
        'Spice Shelf',
        'garam masala',
      ],
      [
        'Mustard Seeds',
        'Spices',
        'kg',
        3.0,
        130.0,
        'Spice Shelf',
        'mustard seeds',
      ],
      ['Cumin Seeds', 'Spices', 'kg', 3.0, 280.0, 'Spice Shelf', 'cumin seeds'],
      ['Pepper', 'Spices', 'kg', 2.0, 620.0, 'Spice Shelf', 'black pepper'],
      ['Cardamom', 'Spices', 'kg', 1.0, 1850.0, 'Spice Shelf', 'cardamom'],
      ['Cloves', 'Spices', 'kg', 1.0, 900.0, 'Spice Shelf', 'cloves'],
      ['Cinnamon', 'Spices', 'kg', 1.0, 780.0, 'Spice Shelf', 'cinnamon'],
      ['Ginger', 'Vegetables', 'kg', 8.0, 96.0, 'Vegetable Crate', 'ginger'],
      ['Garlic', 'Vegetables', 'kg', 8.0, 140.0, 'Vegetable Crate', 'garlic'],
      [
        'Curry Leaves',
        'Vegetables',
        'kg',
        2.0,
        110.0,
        'Vegetable Crate',
        'curry leaves',
      ],
      ['Peas', 'Vegetables', 'kg', 8.0, 88.0, 'Freezer', 'green peas'],
      ['Sweet Corn', 'Vegetables', 'kg', 8.0, 92.0, 'Freezer', 'sweet corn'],
      ['Mushroom', 'Vegetables', 'kg', 5.0, 190.0, 'Cold Room', 'mushroom'],
      ['Noodles', 'Grains', 'kg', 10.0, 78.0, 'Dry Store A', 'noodles'],
      ['Pasta', 'Grains', 'kg', 8.0, 96.0, 'Dry Store A', 'pasta'],
      ['Vermicelli', 'Grains', 'kg', 8.0, 72.0, 'Dry Store A', 'vermicelli'],
      ['Idli Rice', 'Grains', 'kg', 18.0, 48.0, 'Dry Store A', 'idli rice'],
      ['Dosa Batter', 'Grains', 'kg', 20.0, 44.0, 'Cold Room', 'dosa batter'],
      ['Tamarind', 'Spices', 'kg', 5.0, 130.0, 'Spice Shelf', 'tamarind'],
      ['Coconut', 'Fruits', 'pieces', 30.0, 24.0, 'Fruit Crate', 'coconut'],
      ['Peanuts', 'Snacks', 'kg', 8.0, 118.0, 'Snack Shelf', 'peanuts'],
      ['Cashews', 'Snacks', 'kg', 3.0, 780.0, 'Snack Shelf', 'cashew nuts'],
      ['Raisins', 'Snacks', 'kg', 3.0, 320.0, 'Snack Shelf', 'raisins'],
      [
        'Biscuits',
        'Snacks',
        'packets',
        40.0,
        18.0,
        'Snack Shelf',
        'biscuit packets',
      ],
      [
        'Chips Packets',
        'Snacks',
        'packets',
        45.0,
        16.0,
        'Snack Shelf',
        'chips packets',
      ],
      [
        'Namkeen Packets',
        'Snacks',
        'packets',
        35.0,
        22.0,
        'Snack Shelf',
        'namkeen',
      ],
      ['Papad', 'Snacks', 'packets', 20.0, 36.0, 'Snack Shelf', 'papad'],
      ['Vinegar', 'Spices', 'litre', 4.0, 58.0, 'Sauce Shelf', 'vinegar'],
      ['Soy Sauce', 'Spices', 'litre', 4.0, 86.0, 'Sauce Shelf', 'soy sauce'],
      [
        'Tomato Sauce',
        'Spices',
        'litre',
        6.0,
        72.0,
        'Sauce Shelf',
        'tomato ketchup',
      ],
      ['Mayonnaise', 'Dairy', 'kg', 5.0, 180.0, 'Cold Room', 'mayonnaise'],
      [
        'Paper Plates',
        'Packaging Materials',
        'pieces',
        200.0,
        1.4,
        'Packaging Store',
        'paper plates',
      ],
      [
        'Paper Cups',
        'Packaging Materials',
        'pieces',
        300.0,
        0.8,
        'Packaging Store',
        'paper cups',
      ],
      [
        'Parcel Boxes',
        'Packaging Materials',
        'boxes',
        20.0,
        120.0,
        'Packaging Store',
        'takeaway boxes',
      ],
      [
        'Aluminium Foil',
        'Packaging Materials',
        'packets',
        10.0,
        90.0,
        'Packaging Store',
        'aluminium foil',
      ],
      [
        'Tissue Paper',
        'Packaging Materials',
        'packets',
        25.0,
        42.0,
        'Packaging Store',
        'tissue paper',
      ],
      [
        'Dishwash Liquid',
        'Cleaning Supplies',
        'litre',
        12.0,
        88.0,
        'Cleaning Store',
        'dishwash liquid',
      ],
      [
        'Floor Cleaner',
        'Cleaning Supplies',
        'litre',
        10.0,
        96.0,
        'Cleaning Store',
        'floor cleaner',
      ],
      [
        'Hand Wash',
        'Cleaning Supplies',
        'litre',
        8.0,
        110.0,
        'Cleaning Store',
        'hand wash',
      ],
      [
        'Garbage Bags',
        'Cleaning Supplies',
        'packets',
        20.0,
        65.0,
        'Cleaning Store',
        'garbage bags',
      ],
      [
        'Steel Scrubbers',
        'Cleaning Supplies',
        'packets',
        15.0,
        28.0,
        'Cleaning Store',
        'steel scrubbers',
      ],
      ['Laddu Mix', 'Snacks', 'kg', 6.0, 140.0, 'Snack Shelf', 'laddu sweet'],
      [
        'Samosa Sheets',
        'Bakery',
        'packets',
        12.0,
        70.0,
        'Freezer',
        'samosa pastry sheets',
      ],
      [
        'Ice Cream Cups',
        'Dairy',
        'pieces',
        80.0,
        18.0,
        'Freezer',
        'ice cream cups',
      ],
      [
        'Custard Powder',
        'Beverages',
        'kg',
        4.0,
        150.0,
        'Beverage Shelf',
        'custard powder',
      ],
      [
        'Rose Syrup',
        'Beverages',
        'litre',
        4.0,
        135.0,
        'Beverage Shelf',
        'rose syrup',
      ],
      [
        'Noodles Masala',
        'Spices',
        'kg',
        3.0,
        260.0,
        'Spice Shelf',
        'noodles masala',
      ],
    ];

    return [
      for (var i = 0; i < raw.length; i++)
        _SeedInventoryItem(
          id: 'demo_item_${(i + 1).toString().padLeft(3, '0')}',
          name: raw[i][0] as String,
          category: raw[i][1] as String,
          unit: raw[i][2] as String,
          minimumStock: raw[i][3] as double,
          cost: raw[i][4] as double,
          storage: raw[i][5] as String,
          imageQuery: raw[i][6] as String,
          expiryDays: _expiryDays(raw[i][1] as String),
        ),
    ];
  }

  int? _expiryDays(String category) {
    if (category == 'Vegetables' || category == 'Fruits') return 5;
    if (category == 'Dairy' || category == 'Bakery') return 7;
    return null;
  }

  List<_SeedMenuItem> _menuItems(DateTime now) {
    final raw = <List<Object>>[
      ['Idly', 'Breakfast', 30.0, 'idly'],
      ['Plain Dosa', 'Breakfast', 40.0, 'plain dosa'],
      ['Masala Dosa', 'Breakfast', 50.0, 'masala dosa'],
      ['Pesarattu', 'Breakfast', 45.0, 'pesarattu'],
      ['Upma', 'Breakfast', 35.0, 'upma'],
      ['Pongal', 'Breakfast', 40.0, 'pongal'],
      ['Vada', 'Breakfast', 20.0, 'vada'],
      ['Poori', 'Breakfast', 40.0, 'poori'],
      ['Bread Omelette', 'Breakfast', 45.0, 'bread omelette'],
      ['Tea', 'Breakfast', 15.0, 'tea'],
      ['Coffee', 'Breakfast', 20.0, 'coffee'],
      ['Veg Meals', 'Lunch', 80.0, 'south indian meals'],
      ['Chicken Meals', 'Lunch', 150.0, 'chicken meals'],
      ['Veg Biryani', 'Lunch', 100.0, 'vegetable biryani'],
      ['Chicken Biryani', 'Lunch', 160.0, 'chicken biryani'],
      ['Lemon Rice', 'Lunch', 60.0, 'lemon rice'],
      ['Tomato Rice', 'Lunch', 60.0, 'tomato rice'],
      ['Curd Rice', 'Lunch', 55.0, 'curd rice'],
      ['Veg Fried Rice', 'Lunch', 90.0, 'veg fried rice'],
      ['Egg Fried Rice', 'Lunch', 100.0, 'egg fried rice'],
      ['Chicken Fried Rice', 'Lunch', 130.0, 'chicken fried rice'],
      ['Veg Pulao', 'Lunch', 90.0, 'veg pulao'],
      ['Chapati & Curry', 'Lunch', 70.0, 'chapati curry'],
      ['Chapati', 'Dinner', 40.0, 'chapati'],
      ['Dosa', 'Dinner', 45.0, 'plain dosa'],
      ['Idly', 'Dinner', 30.0, 'idly'],
      ['Parotta', 'Dinner', 50.0, 'parotta'],
      ['Veg Curry', 'Dinner', 70.0, 'veg curry'],
      ['Paneer Curry', 'Dinner', 110.0, 'paneer curry'],
      ['Chicken Curry', 'Dinner', 140.0, 'chicken curry'],
      ['Egg Curry', 'Dinner', 90.0, 'egg curry'],
      ['Veg Fried Rice', 'Dinner', 90.0, 'veg fried rice'],
      ['Noodles', 'Dinner', 80.0, 'noodles'],
    ];
    return [
      for (var i = 0; i < raw.length; i++)
        _SeedMenuItem(
          id: 'demo_menu_${(i + 1).toString().padLeft(3, '0')}',
          name: raw[i][0] as String,
          section: raw[i][1] as String,
          price: raw[i][2] as double,
          imageQuery: raw[i][3] as String,
        ),
    ];
  }

  Map<String, _SeedRecipe> _recipes(List<_SeedMenuItem> menus, DateTime now) {
    final recipeMap = <String, List<_SeedIngredient>>{
      'Idli': [
        _ing('Idli Rice', 2, 'kg'),
        _ing('Urad Dal', .7, 'kg'),
        _ing('Salt', .08, 'kg'),
      ],
      'Masala Dosa': [
        _ing('Dosa Batter', 3, 'kg'),
        _ing('Potato', 2, 'kg'),
        _ing('Onion', .8, 'kg'),
        _ing('Cooking Oil', .5, 'litre'),
      ],
      'Pesarattu': [
        _ing('Moong Dal', 2, 'kg'),
        _ing('Green Chilli', .12, 'kg'),
        _ing('Ginger', .12, 'kg'),
        _ing('Cooking Oil', .35, 'litre'),
      ],
      'Upma': [
        _ing('Rava', 2.2, 'kg'),
        _ing('Onion', .7, 'kg'),
        _ing('Carrot', .4, 'kg'),
        _ing('Cooking Oil', .35, 'litre'),
      ],
      'Poha': [
        _ing('Poha', 2.4, 'kg'),
        _ing('Peanuts', .4, 'kg'),
        _ing('Onion', .6, 'kg'),
        _ing('Lemon', 8, 'pieces'),
      ],
      'Poori Curry': [
        _ing('Wheat Flour', 2.5, 'kg'),
        _ing('Potato', 2.5, 'kg'),
        _ing('Cooking Oil', 1.2, 'litre'),
      ],
      'Bread Omelette': [
        _ing('Bread', 8, 'packets'),
        _ing('Eggs', 40, 'pieces'),
        _ing('Onion', .6, 'kg'),
        _ing('Butter', .3, 'kg'),
      ],
      'Veg Sandwich': [
        _ing('Bread', 8, 'packets'),
        _ing('Tomato', .8, 'kg'),
        _ing('Cabbage', .6, 'kg'),
        _ing('Mayonnaise', .5, 'kg'),
      ],
      'Rava Dosa': [
        _ing('Rava', 2, 'kg'),
        _ing('Rice', 1, 'kg'),
        _ing('Curd', .7, 'kg'),
        _ing('Cooking Oil', .5, 'litre'),
      ],
      'Tea and Bun': [
        _ing('Tea Powder', .25, 'kg'),
        _ing('Milk', 6, 'litre'),
        _ing('Sugar', 1.1, 'kg'),
        _ing('Pav Buns', 8, 'packets'),
      ],
      'Veg Meals': [
        _ing('Rice', 5, 'kg'),
        _ing('Toor Dal', 1.2, 'kg'),
        _ing('Curd', 2, 'kg'),
        _ing('Cabbage', 3, 'kg'),
      ],
      'Chicken Biryani': [
        _ing('Basmati Rice', 4, 'kg'),
        _ing('Onion', 2, 'kg'),
        _ing('Garam Masala', .2, 'kg'),
        _ing('Curd', 1.5, 'kg'),
      ],
      'Veg Biryani': [
        _ing('Basmati Rice', 4, 'kg'),
        _ing('Carrot', 1, 'kg'),
        _ing('Beans', 1, 'kg'),
        _ing('Garam Masala', .18, 'kg'),
      ],
      'Curd Rice': [
        _ing('Rice', 4, 'kg'),
        _ing('Curd', 4, 'kg'),
        _ing('Milk', 2, 'litre'),
        _ing('Mustard Seeds', .08, 'kg'),
      ],
      'Tomato Rice': [
        _ing('Rice', 4, 'kg'),
        _ing('Tomato', 2.5, 'kg'),
        _ing('Onion', 1, 'kg'),
        _ing('Cooking Oil', .45, 'litre'),
      ],
      'Lemon Rice': [
        _ing('Rice', 4, 'kg'),
        _ing('Lemon', 18, 'pieces'),
        _ing('Peanuts', .6, 'kg'),
        _ing('Turmeric Powder', .08, 'kg'),
      ],
      'Paneer Fried Rice': [
        _ing('Rice', 3.5, 'kg'),
        _ing('Paneer', 1.8, 'kg'),
        _ing('Capsicum', .8, 'kg'),
        _ing('Soy Sauce', .25, 'litre'),
      ],
      'Egg Fried Rice': [
        _ing('Rice', 3.5, 'kg'),
        _ing('Eggs', 36, 'pieces'),
        _ing('Capsicum', .8, 'kg'),
        _ing('Soy Sauce', .25, 'litre'),
      ],
      'Rajma Rice': [
        _ing('Rice', 4, 'kg'),
        _ing('Rajma', 2, 'kg'),
        _ing('Tomato', 1.5, 'kg'),
        _ing('Onion', 1, 'kg'),
      ],
      'Chapati Dal': [
        _ing('Wheat Flour', 3, 'kg'),
        _ing('Toor Dal', 1.8, 'kg'),
        _ing('Onion', .8, 'kg'),
        _ing('Ghee', .25, 'kg'),
      ],
      'Samosa': [
        _ing('Samosa Sheets', 8, 'packets'),
        _ing('Potato', 3, 'kg'),
        _ing('Peas', .8, 'kg'),
        _ing('Cooking Oil', 1.5, 'litre'),
      ],
      'Mirchi Bajji': [
        _ing('Green Chilli', 1.8, 'kg'),
        _ing('Chickpeas', 1.8, 'kg'),
        _ing('Cooking Oil', 1.2, 'litre'),
      ],
      'Punugulu': [
        _ing('Dosa Batter', 3, 'kg'),
        _ing('Onion', .5, 'kg'),
        _ing('Cooking Oil', 1.2, 'litre'),
      ],
      'Veg Puff': [
        _ing('Pizza Base', 5, 'packets'),
        _ing('Potato', 1.5, 'kg'),
        _ing('Carrot', .5, 'kg'),
      ],
      'Noodles': [
        _ing('Noodles', 3, 'kg'),
        _ing('Cabbage', 1, 'kg'),
        _ing('Capsicum', .7, 'kg'),
        _ing('Noodles Masala', .25, 'kg'),
      ],
      'French Fries': [
        _ing('Potato', 4, 'kg'),
        _ing('Cooking Oil', 1.4, 'litre'),
        _ing('Salt', .08, 'kg'),
      ],
      'Tea': [
        _ing('Tea Powder', .28, 'kg'),
        _ing('Milk', 7, 'litre'),
        _ing('Sugar', 1.2, 'kg'),
      ],
      'Coffee': [
        _ing('Coffee Powder', .22, 'kg'),
        _ing('Milk', 6, 'litre'),
        _ing('Sugar', .9, 'kg'),
      ],
      'Sweet Corn Cup': [
        _ing('Sweet Corn', 3, 'kg'),
        _ing('Butter', .4, 'kg'),
        _ing('Pepper', .05, 'kg'),
      ],
      'Veg Burger': [
        _ing('Burger Buns', 8, 'packets'),
        _ing('Potato', 2, 'kg'),
        _ing('Cheese', .8, 'kg'),
        _ing('Tomato Sauce', .4, 'litre'),
      ],
      'Chapati Kurma': [
        _ing('Wheat Flour', 3, 'kg'),
        _ing('Potato', 1.5, 'kg'),
        _ing('Carrot', .8, 'kg'),
        _ing('Coconut', 8, 'pieces'),
      ],
      'Dosa': [_ing('Dosa Batter', 3, 'kg'), _ing('Cooking Oil', .45, 'litre')],
      'Fried Rice': [
        _ing('Rice', 3.5, 'kg'),
        _ing('Carrot', .8, 'kg'),
        _ing('Beans', .8, 'kg'),
        _ing('Soy Sauce', .25, 'litre'),
      ],
      'Paneer Butter Masala': [
        _ing('Paneer', 2.2, 'kg'),
        _ing('Butter', .7, 'kg'),
        _ing('Tomato', 2.2, 'kg'),
        _ing('Garam Masala', .16, 'kg'),
      ],
      'Veg Noodles': [
        _ing('Noodles', 3, 'kg'),
        _ing('Cabbage', 1.2, 'kg'),
        _ing('Capsicum', .7, 'kg'),
        _ing('Soy Sauce', .25, 'litre'),
      ],
      'Egg Curry Rice': [
        _ing('Rice', 3.5, 'kg'),
        _ing('Eggs', 32, 'pieces'),
        _ing('Tomato', 1.5, 'kg'),
        _ing('Onion', 1.2, 'kg'),
      ],
      'Mushroom Biryani': [
        _ing('Basmati Rice', 3.5, 'kg'),
        _ing('Mushroom', 2, 'kg'),
        _ing('Onion', 1.4, 'kg'),
        _ing('Garam Masala', .16, 'kg'),
      ],
      'Dal Rice': [
        _ing('Rice', 4, 'kg'),
        _ing('Toor Dal', 1.8, 'kg'),
        _ing('Ghee', .2, 'kg'),
      ],
      'Pasta': [
        _ing('Pasta', 3, 'kg'),
        _ing('Cheese', .9, 'kg'),
        _ing('Tomato Sauce', .5, 'litre'),
        _ing('Capsicum', .8, 'kg'),
      ],
      'Parotta Kurma': [
        _ing('Maida', 3, 'kg'),
        _ing('Cooking Oil', .8, 'litre'),
        _ing('Potato', 1.4, 'kg'),
        _ing('Coconut', 8, 'pieces'),
      ],
    };

    return {
      for (var i = 0; i < menus.length; i++)
        menus[i].id: _SeedRecipe(
          id: 'demo_recipe_${(i + 1).toString().padLeft(3, '0')}',
          menuItemId: menus[i].id,
          menuItemName: menus[i].name,
          ingredients: recipeMap[menus[i].name] ?? const [],
          preparationCost: 8 + (i % 6) * 2,
        ),
    };
  }

  _SeedIngredient _ing(String name, double quantity, String unit) {
    return _SeedIngredient(name: name, quantity: quantity, unit: unit);
  }
}

class _SeedInventoryItem {
  final String id;
  final String name;
  final String category;
  final String unit;
  final double minimumStock;
  final double cost;
  final String storage;
  final String imageQuery;
  final int? expiryDays;

  const _SeedInventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.minimumStock,
    required this.cost,
    required this.storage,
    required this.imageQuery,
    this.expiryDays,
  });
}

class _SeedSupplier {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String gstNumber;
  final DateTime createdAt;

  const _SeedSupplier({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.gstNumber,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'gstNumber': gstNumber,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class _SeedPurchase {
  final String id;
  final String supplierId;
  final String supplierName;
  final String itemId;
  final String itemName;
  final double quantity;
  final String unit;
  final double pricePerUnit;
  final DateTime purchaseDate;
  final String invoiceNumber;
  final DateTime createdAt;

  const _SeedPurchase({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.pricePerUnit,
    required this.purchaseDate,
    required this.invoiceNumber,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'itemId': itemId,
      'itemName': itemName,
      'quantity': quantity,
      'unit': unit,
      'pricePerUnit': pricePerUnit,
      'purchaseDate': purchaseDate.toIso8601String(),
      'invoiceNumber': invoiceNumber,
      'remarks': 'Demo purchase lot for canteen operations.',
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class _SeedLot {
  final String id;
  final String itemId;
  final String purchaseId;
  double quantity;
  final String unit;
  final double unitPrice;
  final DateTime purchaseDate;
  final String supplierId;
  final String invoiceNumber;

  _SeedLot({
    required this.id,
    required this.itemId,
    required this.purchaseId,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.purchaseDate,
    required this.supplierId,
    required this.invoiceNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemId': itemId,
      'purchaseId': purchaseId,
      'quantity': quantity,
      'unit': unit,
      'unitPrice': unitPrice,
      'purchaseDate': purchaseDate.toIso8601String(),
      'supplierId': supplierId,
      'invoiceNumber': invoiceNumber,
    };
  }
}

class _SeedMenuItem {
  final String id;
  final String name;
  final String section;
  final double price;
  final String imageQuery;

  const _SeedMenuItem({
    required this.id,
    required this.name,
    required this.section,
    required this.price,
    required this.imageQuery,
  });
}

class _SeedRecipe {
  final String id;
  final String menuItemId;
  final String menuItemName;
  final List<_SeedIngredient> ingredients;
  final double preparationCost;

  const _SeedRecipe({
    required this.id,
    required this.menuItemId,
    required this.menuItemName,
    required this.ingredients,
    required this.preparationCost,
  });
}

class _SeedIngredient {
  final String name;
  final double quantity;
  final String unit;

  const _SeedIngredient({
    required this.name,
    required this.quantity,
    required this.unit,
  });
}
