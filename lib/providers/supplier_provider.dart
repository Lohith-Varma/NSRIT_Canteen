import 'package:flutter/material.dart';
import '../models/supplier_model.dart';
import '../services/firestore_service.dart';

class SupplierProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<SupplierModel> _suppliers = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  List<SupplierModel> get suppliers => _suppliers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  int get totalSuppliers => _suppliers.length;

  Future<void> loadSuppliers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _suppliers = await _firestoreService.getSuppliers();
    } catch (e) {
      _errorMessage = 'Failed to load suppliers: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<SupplierModel> get filteredSuppliers {
    if (_searchQuery.isEmpty) return _suppliers;
    final query = _searchQuery.toLowerCase();
    return _suppliers.where((s) {
      return s.name.toLowerCase().contains(query) ||
          s.phone.contains(query) ||
          s.email.toLowerCase().contains(query) ||
          s.address.toLowerCase().contains(query) ||
          (s.gstNumber?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<bool> addSupplier(SupplierModel supplier) async {
    try {
      await _firestoreService.addSupplier(supplier);
      await loadSuppliers();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add supplier: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSupplier(SupplierModel supplier) async {
    try {
      await _firestoreService.updateSupplier(supplier);
      await loadSuppliers();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update supplier: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSupplier(String supplierId) async {
    try {
      await _firestoreService.deleteSupplier(supplierId);
      await loadSuppliers();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete supplier: $e';
      notifyListeners();
      return false;
    }
  }
}
