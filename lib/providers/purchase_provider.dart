import 'package:flutter/material.dart';
import '../models/purchase_model.dart';
import '../services/firestore_service.dart';

class PurchaseProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<PurchaseModel> _purchases = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  List<PurchaseModel> get purchases => _purchases;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  int get totalPurchases => _purchases.length;

  List<PurchaseModel> get recentPurchases {
    return _purchases.take(5).toList();
  }

  Future<void> loadPurchases() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _purchases = await _firestoreService.getPurchases();
    } catch (e) {
      _errorMessage = 'Failed to load purchases: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<PurchaseModel> get filteredPurchases {
    if (_searchQuery.isEmpty) return _purchases;
    final query = _searchQuery.toLowerCase();
    return _purchases.where((p) {
      return p.invoiceNumber.toLowerCase().contains(query) ||
          p.itemName.toLowerCase().contains(query) ||
          p.supplierName.toLowerCase().contains(query) ||
          (p.remarks?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<bool> recordPurchase({
    required PurchaseModel purchase,
    required VoidCallback onInventoryUpdated,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestoreService.addPurchase(purchase: purchase);
      await loadPurchases();
      // Instantly notify & refresh inventory stock and weighted average cost
      onInventoryUpdated();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to record purchase: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
