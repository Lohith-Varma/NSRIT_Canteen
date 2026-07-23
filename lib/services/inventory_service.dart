import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/app_constants.dart';
import '../models/inventory_item.dart';
import '../models/inventory_lot.dart';

class InventoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<InventoryItem>> watchInventoryItems() {
    return _db
        .collection(AppConstants.inventoryCollection)
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .asyncMap((snapshot) async {
          final itemIds = snapshot.docs.map((doc) => doc.id).toList();
          final allLots = await _loadLotsForItems(itemIds);
          final items = snapshot.docs.map((doc) {
            final itemLots =
                allLots.where((lot) => lot.itemId == doc.id).toList()
                  ..sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));
            return InventoryItem.fromMap(doc.data(), doc.id, lots: itemLots);
          }).toList();
          items.sort(
            (a, b) =>
                a.itemName.toLowerCase().compareTo(b.itemName.toLowerCase()),
          );
          return items;
        });
  }

  Future<List<InventoryItem>> getInventoryItems() async {
    final snapshot = await _db
        .collection(AppConstants.inventoryCollection)
        .where('isDeleted', isEqualTo: false)
        .get();
    final itemIds = snapshot.docs.map((doc) => doc.id).toList();
    final allLots = await _loadLotsForItems(itemIds);
    final items = snapshot.docs.map((doc) {
      final itemLots = allLots.where((lot) => lot.itemId == doc.id).toList()
        ..sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));
      return InventoryItem.fromMap(doc.data(), doc.id, lots: itemLots);
    }).toList();
    items.sort(
      (a, b) => a.itemName.toLowerCase().compareTo(b.itemName.toLowerCase()),
    );
    return items;
  }

  Future<String> addInventoryItem(InventoryItem item) async {
    _validateItem(item);
    final docId = item.id.isNotEmpty
        ? item.id
        : _db.collection(AppConstants.inventoryCollection).doc().id;
    final now = DateTime.now();
    final newItem = item.copyWith(
      id: docId,
      quantity: 0,
      createdAt: item.createdAt,
      updatedAt: now,
      isDeleted: false,
      status: item.status.isEmpty ? 'active' : item.status,
    );
    final batch = _db.batch();
    batch.set(
      _db.collection(AppConstants.inventoryCollection).doc(docId),
      newItem.toMap(),
    );
    batch.set(
      _db.collection(AppConstants.categoriesCollection).doc(newItem.category),
      {'name': newItem.category, 'createdAt': now.toIso8601String()},
      SetOptions(merge: true),
    );
    await batch.commit();
    return docId;
  }

  Future<void> updateInventoryItem(InventoryItem item) async {
    _validateItem(item);
    final updatedItem = item.copyWith(updatedAt: DateTime.now());
    final batch = _db.batch();
    batch.update(
      _db.collection(AppConstants.inventoryCollection).doc(updatedItem.id),
      updatedItem.toMap(),
    );
    batch.set(
      _db
          .collection(AppConstants.categoriesCollection)
          .doc(updatedItem.category),
      {
        'name': updatedItem.category,
        'createdAt': DateTime.now().toIso8601String(),
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Future<void> softDeleteInventoryItem(String itemId) async {
    await _db.collection(AppConstants.inventoryCollection).doc(itemId).update({
      'isDeleted': true,
      'status': 'deleted',
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Stream<List<String>> watchCategories() {
    return _db.collection(AppConstants.categoriesCollection).snapshots().map((
      snapshot,
    ) {
      final categories =
          snapshot.docs
              .map((doc) => (doc.data()['name'] ?? doc.id).toString().trim())
              .where((category) => category.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
      return categories;
    });
  }

  Future<List<String>> getCategories() async {
    final snapshot = await _db
        .collection(AppConstants.categoriesCollection)
        .get();
    final categories =
        snapshot.docs
            .map((doc) => (doc.data()['name'] ?? doc.id).toString().trim())
            .where((category) => category.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return categories;
  }

  Future<void> addCategory(String category) async {
    final trimmed = category.trim();
    if (trimmed.isEmpty) {
      throw Exception('Category name is required.');
    }
    await _db.collection(AppConstants.categoriesCollection).doc(trimmed).set({
      'name': trimmed,
      'createdAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteCategory(String category) async {
    await _db
        .collection(AppConstants.categoriesCollection)
        .doc(category)
        .delete();
  }

  Future<List<InventoryLot>> _loadLotsForItems(List<String> itemIds) async {
    if (itemIds.isEmpty) return [];
    final lots = <InventoryLot>[];
    for (var i = 0; i < itemIds.length; i += 30) {
      final chunk = itemIds.skip(i).take(30).toList();
      final snapshot = await _db
          .collection(AppConstants.lotsCollection)
          .where('itemId', whereIn: chunk)
          .get();
      lots.addAll(
        snapshot.docs.map((doc) => InventoryLot.fromMap(doc.data(), doc.id)),
      );
    }
    return lots;
  }

  void _validateItem(InventoryItem item) {
    if (item.itemName.trim().isEmpty) {
      throw Exception('Item name is required.');
    }
    if (item.category.trim().isEmpty) {
      throw Exception('Category is required.');
    }
    if (item.unit.trim().isEmpty) {
      throw Exception('Unit is required.');
    }
    if (item.minimumStock < 0 || item.maximumStock < 0) {
      throw Exception('Stock limits cannot be negative.');
    }
    if (item.sellingPrice < 0 || item.purchasePrice < 0) {
      throw Exception('Prices cannot be negative.');
    }
  }
}
