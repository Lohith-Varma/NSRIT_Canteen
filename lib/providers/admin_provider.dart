import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_settings_model.dart';
import '../models/inventory_item.dart';
import '../models/notification_model.dart';
import '../models/prepared_food_model.dart';
import '../models/purchase_model.dart';
import '../models/report_model.dart';
import '../models/sale_model.dart';
import '../models/stock_movement_model.dart';
import '../models/supplier_model.dart';
import '../models/user_model.dart';
import '../services/admin_service.dart';
import '../utils/formatters.dart';

enum AnalyticsRange { today, thisWeek, thisMonth, custom }

class AdminProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService();

  List<UserModel> _users = [];
  List<NotificationModel> _notifications = [];
  AppSettingsModel _settings = AppSettingsModel.defaults();
  bool _isLoading = false;
  String? _errorMessage;
  AnalyticsRange _analyticsRange = AnalyticsRange.thisMonth;
  DateTimeRange? _customRange;
  StreamSubscription<List<UserModel>>? _userSubscription;

  List<UserModel> get users => _users;
  List<NotificationModel> get notifications => _notifications;
  AppSettingsModel get settings => _settings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AnalyticsRange get analyticsRange => _analyticsRange;
  DateTimeRange? get customRange => _customRange;

  int get unreadNotificationCount {
    return _notifications.where((item) => !item.isRead).length;
  }

  void startUserSync() {
    if (_userSubscription != null) return;
    _userSubscription?.cancel();
    _userSubscription = _adminService.watchUsers().listen(
      (users) {
        _users = users;
        notifyListeners();
      },
      onError: (Object error) {
        _errorMessage = 'Failed to sync users: $error';
        notifyListeners();
      },
    );
  }

  Future<void> loadAdminData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _adminService.getUsers(),
        _adminService.getSettings(),
        _adminService.getNotifications(),
      ]);
      _users = results[0] as List<UserModel>;
      _settings = results[1] as AppSettingsModel;
      _notifications = results[2] as List<NotificationModel>;
    } catch (e) {
      _errorMessage = 'Failed to load administration data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveUser(UserModel user) async {
    if (user.email.trim().isEmpty || !user.email.contains('@')) {
      _errorMessage = 'Enter a valid user email.';
      notifyListeners();
      return false;
    }

    try {
      await _adminService.saveUser(user);
      _users = await _adminService.getUsers();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save user: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deactivateUser(String userId) async {
    try {
      await _adminService.deactivateUser(userId);
      _users = await _adminService.getUsers();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to deactivate user: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      await _adminService.resetPassword(email);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to reset password: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveSettings(AppSettingsModel settings) async {
    if (settings.collegeName.trim().isEmpty ||
        settings.canteenName.trim().isEmpty ||
        settings.currency.trim().isEmpty) {
      _errorMessage = 'College, canteen, and currency are required.';
      notifyListeners();
      return false;
    }

    try {
      await _adminService.saveSettings(settings);
      _settings = settings;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save settings: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshGeneratedNotifications({
    required List<InventoryItem> inventory,
    required List<PurchaseModel> purchases,
    required List<SaleModel> sales,
    required List<PreparedFoodModel> preparedFood,
  }) async {
    final generated = <NotificationModel>[];
    final now = DateTime.now();

    for (final item in inventory) {
      if (item.isOutOfStock) {
        generated.add(
          NotificationModel(
            id: 'out_${item.id}',
            title: 'Out of Stock',
            description: '${item.itemName} is unavailable in inventory.',
            timestamp: now,
            isRead: false,
            type: 'Out of Stock',
            referenceId: item.id,
          ),
        );
      } else if (item.isLowStock) {
        generated.add(
          NotificationModel(
            id: 'low_${item.id}',
            title: 'Low Stock',
            description:
                '${item.itemName} is below minimum stock (${Formatters.quantityWithUnit(item.minimumStock, item.unit)}).',
            timestamp: now,
            isRead: false,
            type: 'Low Stock',
            referenceId: item.id,
          ),
        );
      }

      final expiry = item.expiryDate;
      if (expiry != null &&
          expiry.isAfter(now.subtract(const Duration(days: 1))) &&
          expiry.isBefore(now.add(const Duration(days: 7)))) {
        generated.add(
          NotificationModel(
            id: 'exp_${item.id}',
            title: 'Expiring Inventory',
            description:
                '${item.itemName} expires on ${Formatters.formatDate(expiry)}.',
            timestamp: now,
            isRead: false,
            type: 'Expiring Inventory',
            referenceId: item.id,
          ),
        );
      }
    }

    for (final purchase in purchases.take(5)) {
      generated.add(
        NotificationModel(
          id: 'purchase_${purchase.id}',
          title: 'New Purchase',
          description:
              '${purchase.itemName} purchased for ${Formatters.currency(purchase.totalAmount)}.',
          timestamp: purchase.createdAt,
          isRead: false,
          type: 'New Purchase',
          referenceId: purchase.id,
        ),
      );
    }

    for (final sale in sales.take(5)) {
      generated.add(
        NotificationModel(
          id: 'sale_${sale.id}',
          title: 'Successful Sale',
          description:
              '${sale.menuItemName} sale completed for ${Formatters.currency(sale.totalAmount)}.',
          timestamp: sale.soldAt,
          isRead: false,
          type: 'Successful Sale',
          referenceId: sale.id,
        ),
      );
    }

    for (final food in preparedFood.take(5)) {
      generated.add(
        NotificationModel(
          id: 'prep_${food.id}',
          title: 'Preparation Completed',
          description:
              '${food.menuItemName} prepared: ${Formatters.number(food.quantityPrepared)} units.',
          timestamp: food.preparedAt,
          isRead: false,
          type: 'Preparation Completed',
          referenceId: food.id,
        ),
      );
    }

    await _adminService.upsertNotifications(generated);
    _notifications = await _adminService.getNotifications();
    notifyListeners();
  }

  Future<void> markNotificationRead(String id) async {
    await _adminService.markNotificationRead(id);
    _notifications = _notifications
        .map((item) => item.id == id ? item.copyWith(isRead: true) : item)
        .toList();
    notifyListeners();
  }

  void setAnalyticsRange(AnalyticsRange range, {DateTimeRange? customRange}) {
    _analyticsRange = range;
    _customRange = customRange;
    notifyListeners();
  }

  DateTimeRange activeDateRange() {
    final now = DateTime.now();
    switch (_analyticsRange) {
      case AnalyticsRange.today:
        final start = DateTime(now.year, now.month, now.day);
        return DateTimeRange(end: now, start: start);
      case AnalyticsRange.thisWeek:
        final start = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(end: now, start: start);
      case AnalyticsRange.thisMonth:
        return DateTimeRange(start: DateTime(now.year, now.month), end: now);
      case AnalyticsRange.custom:
        return _customRange ??
            DateTimeRange(
              start: now.subtract(const Duration(days: 30)),
              end: now,
            );
    }
  }

  bool hasAccess(UserModel? user, String module) {
    final role = user?.role;
    if (module == 'Dashboard') return true;
    if (role == null) return false;
    if (role == 'Administrator') return true;
    const permissions = {
      'Store Manager': {
        'Inventory',
        'Suppliers',
        'Purchases',
        'Stock Movements',
        'Dashboard',
      },
      'Cook': {'Menu', 'Preparation', 'Dashboard'},
      'Cashier': {'Sales', 'Dashboard'},
    };
    return permissions[role]?.contains(module) ?? false;
  }

  ReportModel buildReport({
    required String type,
    required List<SaleModel> sales,
    required List<PurchaseModel> purchases,
    required List<InventoryItem> inventory,
    required List<SupplierModel> suppliers,
    required List<StockMovementModel> movements,
  }) {
    final now = DateTime.now();
    switch (type) {
      case 'Daily Sales':
      case 'Weekly Sales':
      case 'Monthly Sales':
        final filteredSales = _filterSalesByReportType(sales, type);
        return ReportModel(
          title: '$type Report',
          type: type,
          generatedAt: now,
          columns: const ['Date', 'Item', 'Qty', 'Payment', 'Amount'],
          rows: filteredSales
              .map(
                (sale) => [
                  Formatters.formatDateTime(sale.soldAt),
                  sale.menuItemName,
                  Formatters.number(sale.quantity),
                  sale.paymentMethod,
                  Formatters.currency(sale.totalAmount),
                ],
              )
              .toList(),
        );
      case 'Purchase Report':
        return ReportModel(
          title: 'Purchase Report',
          type: type,
          generatedAt: now,
          columns: const ['Date', 'Supplier', 'Item', 'Qty', 'Amount'],
          rows: purchases
              .map(
                (purchase) => [
                  Formatters.formatDate(purchase.purchaseDate),
                  purchase.supplierName,
                  purchase.itemName,
                  Formatters.quantityWithUnit(purchase.quantity, purchase.unit),
                  Formatters.currency(purchase.totalAmount),
                ],
              )
              .toList(),
        );
      case 'Inventory Report':
        return ReportModel(
          title: 'Inventory Report',
          type: type,
          generatedAt: now,
          columns: const ['Item', 'Category', 'Stock', 'Min Stock', 'Value'],
          rows: inventory
              .map(
                (item) => [
                  item.itemName,
                  item.category,
                  Formatters.quantityWithUnit(item.totalStock, item.unit),
                  Formatters.quantityWithUnit(item.minimumStock, item.unit),
                  Formatters.currency(item.totalValue),
                ],
              )
              .toList(),
        );
      case 'Supplier Report':
        return ReportModel(
          title: 'Supplier Report',
          type: type,
          generatedAt: now,
          columns: const ['Name', 'Phone', 'Email', 'GST'],
          rows: suppliers
              .map(
                (supplier) => [
                  supplier.name,
                  supplier.phone,
                  supplier.email,
                  supplier.gstNumber ?? '',
                ],
              )
              .toList(),
        );
      case 'Stock Movement Report':
        return ReportModel(
          title: 'Stock Movement Report',
          type: type,
          generatedAt: now,
          columns: const [
            'Date',
            'Action',
            'Reference',
            'Item',
            'Quantity',
            'User',
          ],
          rows: movements
              .map(
                (movement) => [
                  Formatters.formatDateTime(movement.dateTime),
                  movement.action,
                  movement.reference,
                  movement.itemName,
                  Formatters.quantityWithUnit(movement.quantity, movement.unit),
                  movement.user,
                ],
              )
              .toList(),
        );
      case 'Profit Report':
        return ReportModel(
          title: 'Profit Report',
          type: type,
          generatedAt: now,
          columns: const [
            'Item',
            'Revenue',
            'Estimated Cost',
            'Estimated Profit',
          ],
          rows: sales
              .map(
                (sale) => [
                  sale.menuItemName,
                  Formatters.currency(sale.totalAmount),
                  Formatters.currency(sale.totalAmount * 0.55),
                  Formatters.currency(sale.totalAmount * 0.45),
                ],
              )
              .toList(),
        );
      case 'Low Stock Report':
        return ReportModel(
          title: 'Low Stock Report',
          type: type,
          generatedAt: now,
          columns: const ['Item', 'Category', 'Current', 'Minimum'],
          rows: inventory
              .where((item) => item.isLowStock || item.isOutOfStock)
              .map(
                (item) => [
                  item.itemName,
                  item.category,
                  Formatters.quantityWithUnit(item.totalStock, item.unit),
                  Formatters.quantityWithUnit(item.minimumStock, item.unit),
                ],
              )
              .toList(),
        );
      default:
        return ReportModel(
          title: '$type Report',
          type: type,
          generatedAt: now,
          columns: const ['Status'],
          rows: const [
            ['No report rows available'],
          ],
        );
    }
  }

  List<SaleModel> _filterSalesByReportType(List<SaleModel> sales, String type) {
    final now = DateTime.now();
    return sales.where((sale) {
      if (type == 'Daily Sales') {
        return sale.soldAt.year == now.year &&
            sale.soldAt.month == now.month &&
            sale.soldAt.day == now.day;
      }
      if (type == 'Weekly Sales') {
        return sale.soldAt.isAfter(now.subtract(const Duration(days: 7)));
      }
      if (type == 'Monthly Sales') {
        return sale.soldAt.year == now.year && sale.soldAt.month == now.month;
      }
      return true;
    }).toList();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}
