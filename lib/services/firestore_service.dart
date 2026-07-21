import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';
import '../models/inventory_item.dart';
import '../models/inventory_lot.dart';
import '../models/supplier_model.dart';
import '../models/purchase_model.dart';
import 'firebase_service.dart';

class FirestoreService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // In-memory demo fallback storage when Firestore is uninitialized/offline
  final List<SupplierModel> _demoSuppliers = [
    SupplierModel(
      id: 'sup_1',
      name: 'Vizag Fresh Agro Traders',
      phone: '+919876543210',
      email: 'sales@vizagfreshagro.com',
      address: 'Plot 45, Gajuwaka Market, Visakhapatnam',
      gstNumber: '37AAAAA0000A1Z5',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    SupplierModel(
      id: 'sup_2',
      name: 'Godavari Dairy Products Co.',
      phone: '+919123456789',
      email: 'orders@godavaridairy.in',
      address: 'NH-16 Dairy Complex, Rajahmundry',
      gstNumber: '37BBBBB1111B2Z6',
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
    ),
    SupplierModel(
      id: 'sup_3',
      name: 'Sri Venkateswara Rice & Spice Mills',
      phone: '+919988776655',
      email: 'svspices@gmail.com',
      address: 'Industrial Area, Anakapalle',
      gstNumber: '37CCCCC2222C3Z7',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
    SupplierModel(
      id: 'sup_4',
      name: 'Coastal Beverage & Packagers',
      phone: '+919440011223',
      email: 'coastalpacks@outlets.com',
      address: 'MVP Colony, Visakhapatnam',
      gstNumber: '37DDDDD3333D4Z8',
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
  ];

  final List<InventoryItem> _demoItems = [
    InventoryItem(
      id: 'item_1',
      name: 'Sona Masoori Rice',
      category: 'Grains',
      unit: 'kg',
      minStock: 100.0,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      lots: [
        InventoryLot(
          id: 'lot_1_1',
          itemId: 'item_1',
          purchaseId: 'pur_1',
          quantity: 50.0,
          unit: 'kg',
          unitPrice: 52.0,
          purchaseDate: DateTime.now().subtract(const Duration(days: 15)),
          supplierId: 'sup_3',
          invoiceNumber: 'INV-2026-001',
        ),
        InventoryLot(
          id: 'lot_1_2',
          itemId: 'item_1',
          purchaseId: 'pur_4',
          quantity: 80.0,
          unit: 'kg',
          unitPrice: 55.0,
          purchaseDate: DateTime.now().subtract(const Duration(days: 2)),
          supplierId: 'sup_3',
          invoiceNumber: 'INV-2026-009',
        ),
      ],
    ),
    InventoryItem(
      id: 'item_2',
      name: 'Fresh Whole Milk',
      category: 'Dairy',
      unit: 'litre',
      minStock: 40.0,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      lots: [
        InventoryLot(
          id: 'lot_2_1',
          itemId: 'item_2',
          purchaseId: 'pur_2',
          quantity: 25.0,
          unit: 'litre',
          unitPrice: 58.0,
          purchaseDate: DateTime.now().subtract(const Duration(days: 1)),
          supplierId: 'sup_2',
          invoiceNumber: 'INV-2026-004',
        ),
      ],
    ),
    InventoryItem(
      id: 'item_3',
      name: 'Onions',
      category: 'Vegetables',
      unit: 'kg',
      minStock: 30.0,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      lots: [
        InventoryLot(
          id: 'lot_3_1',
          itemId: 'item_3',
          purchaseId: 'pur_3',
          quantity: 15.0,
          unit: 'kg',
          unitPrice: 35.0,
          purchaseDate: DateTime.now().subtract(const Duration(days: 3)),
          supplierId: 'sup_1',
          invoiceNumber: 'INV-2026-006',
        ),
      ],
    ),
    InventoryItem(
      id: 'item_4',
      name: 'Refined Sunflower Oil',
      category: 'Oils',
      unit: 'litre',
      minStock: 50.0,
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      lots: [
        InventoryLot(
          id: 'lot_4_1',
          itemId: 'item_4',
          purchaseId: 'pur_5',
          quantity: 60.0,
          unit: 'litre',
          unitPrice: 135.0,
          purchaseDate: DateTime.now().subtract(const Duration(days: 5)),
          supplierId: 'sup_1',
          invoiceNumber: 'INV-2026-008',
        ),
      ],
    ),
    InventoryItem(
      id: 'item_5',
      name: 'Red Chilli Powder',
      category: 'Spices',
      unit: 'kg',
      minStock: 10.0,
      createdAt: DateTime.now().subtract(const Duration(days: 18)),
      updatedAt: DateTime.now().subtract(const Duration(days: 6)),
      lots: [
        InventoryLot(
          id: 'lot_5_1',
          itemId: 'item_5',
          purchaseId: 'pur_6',
          quantity: 12.0,
          unit: 'kg',
          unitPrice: 240.0,
          purchaseDate: DateTime.now().subtract(const Duration(days: 6)),
          supplierId: 'sup_3',
          invoiceNumber: 'INV-2026-005',
        ),
      ],
    ),
    InventoryItem(
      id: 'item_6',
      name: 'Paper Tea Cups 150ml',
      category: 'Packaging Materials',
      unit: 'packets',
      minStock: 25.0,
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
      updatedAt: DateTime.now().subtract(const Duration(days: 4)),
      lots: [
        InventoryLot(
          id: 'lot_6_1',
          itemId: 'item_6',
          purchaseId: 'pur_7',
          quantity: 8.0,
          unit: 'packets',
          unitPrice: 65.0,
          purchaseDate: DateTime.now().subtract(const Duration(days: 4)),
          supplierId: 'sup_4',
          invoiceNumber: 'INV-2026-007',
        ),
      ],
    ),
  ];

  final List<PurchaseModel> _demoPurchases = [
    PurchaseModel(
      id: 'pur_4',
      supplierId: 'sup_3',
      supplierName: 'Sri Venkateswara Rice & Spice Mills',
      itemId: 'item_1',
      itemName: 'Sona Masoori Rice',
      quantity: 80.0,
      unit: 'kg',
      pricePerUnit: 55.0,
      purchaseDate: DateTime.now().subtract(const Duration(days: 2)),
      invoiceNumber: 'INV-2026-009',
      remarks: 'Bulk restock for hostel mess',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    PurchaseModel(
      id: 'pur_3',
      supplierId: 'sup_1',
      supplierName: 'Vizag Fresh Agro Traders',
      itemId: 'item_3',
      itemName: 'Onions',
      quantity: 15.0,
      unit: 'kg',
      pricePerUnit: 35.0,
      purchaseDate: DateTime.now().subtract(const Duration(days: 3)),
      invoiceNumber: 'INV-2026-006',
      remarks: 'Fresh Grade A onions',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    PurchaseModel(
      id: 'pur_2',
      supplierId: 'sup_2',
      supplierName: 'Godavari Dairy Products Co.',
      itemId: 'item_2',
      itemName: 'Fresh Whole Milk',
      quantity: 25.0,
      unit: 'litre',
      pricePerUnit: 58.0,
      purchaseDate: DateTime.now().subtract(const Duration(days: 1)),
      invoiceNumber: 'INV-2026-004',
      remarks: 'Daily morning delivery',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  // ==========================================
  // INVENTORY ITEMS & LOTS APIs
  // ==========================================

  Future<List<InventoryItem>> getInventoryItems() async {
    if (FirebaseService.isInitialized) {
      try {
        final itemsSnap = await _db.collection(AppConstants.itemsCollection).get();
        final lotsSnap = await _db.collection(AppConstants.lotsCollection).get();

        final allLots = lotsSnap.docs
            .map((doc) => InventoryLot.fromMap(doc.data(), doc.id))
            .toList();

        return itemsSnap.docs.map((doc) {
          final itemLots = allLots.where((lot) => lot.itemId == doc.id).toList();
          return InventoryItem.fromMap(doc.data(), doc.id, lots: itemLots);
        }).toList();
      } catch (e) {
        // Fallback to demo data
      }
    }
    return _demoItems;
  }

  Future<String> addInventoryItem(InventoryItem item) async {
    final docId = 'item_${DateTime.now().millisecondsSinceEpoch}';
    final newItem = item.copyWith(id: docId);
    if (FirebaseService.isInitialized) {
      try {
        await _db.collection(AppConstants.itemsCollection).doc(docId).set(newItem.toMap());
        return docId;
      } catch (e) {
        // Fallback to demo data
      }
    }
    _demoItems.add(newItem);
    return docId;
  }

  Future<void> updateInventoryItem(InventoryItem item) async {
    if (FirebaseService.isInitialized) {
      try {
        await _db
            .collection(AppConstants.itemsCollection)
            .doc(item.id)
            .update(item.toMap());
        return;
      } catch (e) {
        // Fallback to demo data
      }
    }
    final index = _demoItems.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _demoItems[index] = item;
    }
  }

  Future<void> deleteInventoryItem(String itemId) async {
    if (FirebaseService.isInitialized) {
      try {
        await _db.collection(AppConstants.itemsCollection).doc(itemId).delete();
        final lots = await _db
            .collection(AppConstants.lotsCollection)
            .where('itemId', isEqualTo: itemId)
            .get();
        for (var doc in lots.docs) {
          await doc.reference.delete();
        }
        return;
      } catch (e) {
        // Fallback to demo data
      }
    }
    _demoItems.removeWhere((i) => i.id == itemId);
  }

  // ==========================================
  // SUPPLIERS APIs
  // ==========================================

  Future<List<SupplierModel>> getSuppliers() async {
    if (FirebaseService.isInitialized) {
      try {
        final snap = await _db.collection(AppConstants.suppliersCollection).get();
        return snap.docs
            .map((doc) => SupplierModel.fromMap(doc.data(), doc.id))
            .toList();
      } catch (e) {
        // Fallback to demo data
      }
    }
    return _demoSuppliers;
  }

  Future<String> addSupplier(SupplierModel supplier) async {
    final docId = 'sup_${DateTime.now().millisecondsSinceEpoch}';
    final newSupplier = supplier.copyWith(id: docId);
    if (FirebaseService.isInitialized) {
      try {
        await _db
            .collection(AppConstants.suppliersCollection)
            .doc(docId)
            .set(newSupplier.toMap());
        return docId;
      } catch (e) {
        // Fallback to demo data
      }
    }
    _demoSuppliers.add(newSupplier);
    return docId;
  }

  Future<void> updateSupplier(SupplierModel supplier) async {
    if (FirebaseService.isInitialized) {
      try {
        await _db
            .collection(AppConstants.suppliersCollection)
            .doc(supplier.id)
            .update(supplier.toMap());
        return;
      } catch (e) {
        // Fallback to demo data
      }
    }
    final index = _demoSuppliers.indexWhere((s) => s.id == supplier.id);
    if (index != -1) {
      _demoSuppliers[index] = supplier;
    }
  }

  Future<void> deleteSupplier(String supplierId) async {
    if (FirebaseService.isInitialized) {
      try {
        await _db
            .collection(AppConstants.suppliersCollection)
            .doc(supplierId)
            .delete();
        return;
      } catch (e) {
        // Fallback to demo data
      }
    }
    _demoSuppliers.removeWhere((s) => s.id == supplierId);
  }

  // ==========================================
  // PURCHASES & LOT AUTO-UPDATE APIs
  // ==========================================

  Future<List<PurchaseModel>> getPurchases() async {
    if (FirebaseService.isInitialized) {
      try {
        final snap = await _db
            .collection(AppConstants.purchasesCollection)
            .orderBy('purchaseDate', descending: true)
            .get();
        return snap.docs
            .map((doc) => PurchaseModel.fromMap(doc.data(), doc.id))
            .toList();
      } catch (e) {
        // Fallback to demo data
      }
    }
    return _demoPurchases;
  }

  Future<void> addPurchase({
    required PurchaseModel purchase,
  }) async {
    final purchaseDocId = 'pur_${DateTime.now().millisecondsSinceEpoch}';
    final lotDocId = 'lot_${DateTime.now().millisecondsSinceEpoch}';

    final finalPurchase = PurchaseModel(
      id: purchaseDocId,
      supplierId: purchase.supplierId,
      supplierName: purchase.supplierName,
      itemId: purchase.itemId,
      itemName: purchase.itemName,
      quantity: purchase.quantity,
      unit: purchase.unit,
      pricePerUnit: purchase.pricePerUnit,
      purchaseDate: purchase.purchaseDate,
      invoiceNumber: purchase.invoiceNumber,
      remarks: purchase.remarks,
      createdAt: DateTime.now(),
    );

    final newLot = InventoryLot(
      id: lotDocId,
      itemId: purchase.itemId,
      purchaseId: purchaseDocId,
      quantity: purchase.quantity,
      unit: purchase.unit,
      unitPrice: purchase.pricePerUnit,
      purchaseDate: purchase.purchaseDate,
      supplierId: purchase.supplierId,
      invoiceNumber: purchase.invoiceNumber,
    );

    if (FirebaseService.isInitialized) {
      try {
        final batch = _db.batch();
        final pRef = _db.collection(AppConstants.purchasesCollection).doc(purchaseDocId);
        final lRef = _db.collection(AppConstants.lotsCollection).doc(lotDocId);
        
        batch.set(pRef, finalPurchase.toMap());
        batch.set(lRef, newLot.toMap());

        // Update item updated timestamp
        final itemRef = _db.collection(AppConstants.itemsCollection).doc(purchase.itemId);
        batch.update(itemRef, {'updatedAt': DateTime.now().toIso8601String()});

        await batch.commit();
        return;
      } catch (e) {
        // Fallback to demo data
      }
    }

    // Demo in-memory lot addition & stock update
    _demoPurchases.insert(0, finalPurchase);
    final itemIndex = _demoItems.indexWhere((i) => i.id == purchase.itemId);
    if (itemIndex != -1) {
      final existingItem = _demoItems[itemIndex];
      final updatedLots = List<InventoryLot>.from(existingItem.lots)..add(newLot);
      _demoItems[itemIndex] = existingItem.copyWith(
        lots: updatedLots,
        updatedAt: DateTime.now(),
      );
    }
  }
}
