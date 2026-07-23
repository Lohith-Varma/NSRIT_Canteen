import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/app_constants.dart';
import '../models/inventory_item.dart';
import '../models/inventory_lot.dart';
import '../models/purchase_model.dart';
import '../models/stock_movement_model.dart';
import '../models/supplier_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<InventoryItem>> getInventoryItems() async {
    final itemsSnap = await _db
        .collection(AppConstants.inventoryCollection)
        .where('isDeleted', isEqualTo: false)
        .get();
    final lotsSnap = await _db.collection(AppConstants.lotsCollection).get();
    final allLots = lotsSnap.docs
        .map((doc) => InventoryLot.fromMap(doc.data(), doc.id))
        .toList();

    final items = itemsSnap.docs.map((doc) {
      final itemLots = allLots.where((lot) => lot.itemId == doc.id).toList();
      itemLots.sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));
      return InventoryItem.fromMap(doc.data(), doc.id, lots: itemLots);
    }).toList();
    items.sort((a, b) => a.itemName.toLowerCase().compareTo(b.itemName.toLowerCase()));
    return items;
  }

  Future<String> addInventoryItem(InventoryItem item) async {
    final docId = item.id.isNotEmpty
        ? item.id
        : _db.collection(AppConstants.inventoryCollection).doc().id;
    final now = DateTime.now();
    final newItem = item.copyWith(
      id: docId,
      createdAt: item.createdAt,
      updatedAt: now,
      isDeleted: false,
      status: item.status.isEmpty ? 'active' : item.status,
    );
    await _db.collection(AppConstants.inventoryCollection).doc(docId).set(newItem.toMap());
    return docId;
  }

  Future<void> updateInventoryItem(InventoryItem item) async {
    await _db
        .collection(AppConstants.inventoryCollection)
        .doc(item.id)
        .update(item.copyWith(updatedAt: DateTime.now()).toMap());
  }

  Future<void> deleteInventoryItem(String itemId) async {
    final batch = _db.batch();
    batch.update(_db.collection(AppConstants.inventoryCollection).doc(itemId), {
      'isDeleted': true,
      'status': 'deleted',
      'updatedAt': DateTime.now().toIso8601String(),
    });
    final lots = await _db
        .collection(AppConstants.lotsCollection)
        .where('itemId', isEqualTo: itemId)
        .get();
    for (final doc in lots.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<List<SupplierModel>> getSuppliers() async {
    final snap = await _db
        .collection(AppConstants.suppliersCollection)
        .orderBy('name')
        .limit(200)
        .get();
    return snap.docs.map((doc) => SupplierModel.fromMap(doc.data(), doc.id)).toList();
  }

  Future<String> addSupplier(SupplierModel supplier) async {
    final docId = supplier.id.isNotEmpty
        ? supplier.id
        : _db.collection(AppConstants.suppliersCollection).doc().id;
    await _db
        .collection(AppConstants.suppliersCollection)
        .doc(docId)
        .set(supplier.copyWith(id: docId).toMap());
    return docId;
  }

  Future<void> updateSupplier(SupplierModel supplier) async {
    await _db
        .collection(AppConstants.suppliersCollection)
        .doc(supplier.id)
        .update(supplier.toMap());
  }

  Future<void> deleteSupplier(String supplierId) async {
    await _db.collection(AppConstants.suppliersCollection).doc(supplierId).delete();
  }

  Future<List<PurchaseModel>> getPurchases() async {
    final snap = await _db
        .collection(AppConstants.purchasesCollection)
        .orderBy('purchaseDate', descending: true)
        .limit(200)
        .get();
    return snap.docs.map((doc) => PurchaseModel.fromMap(doc.data(), doc.id)).toList();
  }

  Future<void> addPurchase({required PurchaseModel purchase}) async {
    _validatePurchase(purchase);

    final purchaseDocId = purchase.id.isNotEmpty
        ? purchase.id
        : _db.collection(AppConstants.purchasesCollection).doc().id;
    final lotDocId = _db.collection(AppConstants.lotsCollection).doc().id;
    final now = DateTime.now();
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
      createdAt: now,
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

    await _db.runTransaction((transaction) async {
      final itemRef = _db.collection(AppConstants.inventoryCollection).doc(purchase.itemId);
      final itemSnapshot = await transaction.get(itemRef);
      if (!itemSnapshot.exists) {
        throw Exception('Inventory item not found for this purchase.');
      }

      transaction.set(
        _db.collection(AppConstants.purchasesCollection).doc(purchaseDocId),
        finalPurchase.toMap(),
      );
      transaction.set(
        _db.collection(AppConstants.lotsCollection).doc(lotDocId),
        newLot.toMap(),
      );
      transaction.update(itemRef, {
        'quantity': FieldValue.increment(purchase.quantity),
        'updatedAt': now.toIso8601String(),
      });

      final movementId = 'mov_$purchaseDocId';
      transaction.set(
        _db.collection(AppConstants.stockMovementsCollection).doc(movementId),
        StockMovementModel(
          id: movementId,
          dateTime: now,
          action: 'Purchases',
          reference: purchase.invoiceNumber.isEmpty ? purchaseDocId : purchase.invoiceNumber,
          itemName: purchase.itemName,
          quantity: purchase.quantity,
          unit: purchase.unit,
          user: purchase.supplierName,
        ).toMap(),
      );
    });
  }

  void _validatePurchase(PurchaseModel purchase) {
    if (purchase.itemId.trim().isEmpty) {
      throw Exception('Select an inventory item.');
    }
    if (purchase.supplierId.trim().isEmpty) {
      throw Exception('Select a supplier.');
    }
    if (purchase.quantity <= 0) {
      throw Exception('Purchase quantity must be greater than zero.');
    }
    if (purchase.pricePerUnit < 0) {
      throw Exception('Purchase price cannot be negative.');
    }
  }
}
