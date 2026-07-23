import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/inventory_item.dart';
import '../../models/purchase_model.dart';
import '../../models/sale_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/kitchen_provider.dart';
import '../../providers/purchase_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/simple_bar_chart.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);
    final kitchenProvider = Provider.of<KitchenProvider>(context);
    final purchaseProvider = Provider.of<PurchaseProvider>(context);
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final range = adminProvider.activeDateRange();
    final sales = kitchenProvider.sales
        .where((sale) => _inRange(sale.soldAt, range))
        .toList();
    final purchases = purchaseProvider.purchases
        .where((purchase) => _inRange(purchase.purchaseDate, range))
        .toList();
    final movements = kitchenProvider.stockMovements
        .where((movement) => _inRange(movement.dateTime, range))
        .toList();
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 1000 ? 2 : 1;

    return RefreshIndicator(
      onRefresh: () async {
        await kitchenProvider.loadKitchenData();
        await purchaseProvider.loadPurchases();
        await inventoryProvider.loadInventory();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _RangeSelector(adminProvider: adminProvider),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: width > 900 ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.8,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _MetricTile(
                title: 'Sales',
                value: Formatters.number(sales.length.toDouble()),
                icon: Icons.receipt_long_rounded,
              ),
              _MetricTile(
                title: 'Revenue',
                value: Formatters.currency(
                  sales.fold(0.0, (sum, sale) => sum + sale.totalAmount),
                ),
                icon: Icons.currency_rupee_rounded,
              ),
              _MetricTile(
                title: 'Purchases',
                value: Formatters.currency(
                  purchases.fold(
                    0.0,
                    (sum, purchase) => sum + purchase.totalAmount,
                  ),
                ),
                icon: Icons.shopping_cart_rounded,
              ),
              _MetricTile(
                title: 'Consumption',
                value: Formatters.number(
                  movements
                      .where((movement) => movement.quantity < 0)
                      .fold(
                        0.0,
                        (sum, movement) => sum + movement.quantity.abs(),
                      ),
                ),
                icon: Icons.fastfood_rounded,
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: crossAxisCount,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: width > 1000 ? 1.6 : 1.35,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              SimpleBarChart(
                title: 'Daily Sales Trend',
                points: _salesByDay(sales),
                color: Theme.of(context).colorScheme.primary,
              ),
              SimpleBarChart(
                title: 'Weekly Sales Trend',
                points: _salesByWeek(kitchenProvider.sales),
                color: Colors.teal,
              ),
              SimpleBarChart(
                title: 'Monthly Revenue',
                points: _monthlyRevenue(kitchenProvider.sales),
                color: Colors.indigo,
              ),
              SimpleBarChart(
                title: 'Purchase Trend',
                points: _purchaseTrend(purchases),
                color: Colors.orange,
              ),
              SimpleBarChart(
                title: 'Inventory Consumption',
                points: _movementByItem(movements),
                color: Colors.redAccent,
              ),
              SimpleBarChart(
                title: 'Category-wise Consumption',
                points: _categoryConsumption(
                  movements,
                  inventoryProvider.items,
                ),
                color: Colors.green,
              ),
              SimpleBarChart(
                title: 'Top Selling Menu Items',
                points: _sellingItems(sales, top: true),
                color: Colors.purple,
              ),
              SimpleBarChart(
                title: 'Least Selling Items',
                points: _sellingItems(sales, top: false),
                color: Colors.blueGrey,
              ),
              SimpleBarChart(
                title: 'Supplier Performance',
                points: _supplierPerformance(purchases),
                color: Colors.brown,
              ),
              SimpleBarChart(
                title: 'Inventory Value Distribution',
                points: _inventoryValue(inventoryProvider.items),
                color: Colors.cyan,
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _inRange(DateTime date, DateTimeRange range) {
    return !date.isBefore(range.start) && !date.isAfter(range.end);
  }

  List<ChartPoint> _salesByDay(List<SaleModel> sales) {
    final grouped = <String, double>{};
    for (final sale in sales) {
      final label = '${sale.soldAt.day}/${sale.soldAt.month}';
      grouped[label] = (grouped[label] ?? 0) + sale.quantity;
    }
    return grouped.entries
        .map((entry) => ChartPoint(label: entry.key, value: entry.value))
        .toList();
  }

  List<ChartPoint> _salesByWeek(List<SaleModel> sales) {
    final now = DateTime.now();
    final points = <ChartPoint>[];
    for (var i = 3; i >= 0; i--) {
      final end = now.subtract(Duration(days: i * 7));
      final start = end.subtract(const Duration(days: 6));
      final value = sales
          .where(
            (sale) => !sale.soldAt.isBefore(start) && !sale.soldAt.isAfter(end),
          )
          .fold(0.0, (sum, sale) => sum + sale.quantity);
      points.add(ChartPoint(label: 'W${4 - i}', value: value));
    }
    return points;
  }

  List<ChartPoint> _monthlyRevenue(List<SaleModel> sales) {
    final grouped = <String, double>{};
    for (final sale in sales) {
      final label =
          '${sale.soldAt.month}/${sale.soldAt.year.toString().substring(2)}';
      grouped[label] = (grouped[label] ?? 0) + sale.totalAmount;
    }
    return grouped.entries
        .take(6)
        .map((entry) => ChartPoint(label: entry.key, value: entry.value))
        .toList();
  }

  List<ChartPoint> _purchaseTrend(List<PurchaseModel> purchases) {
    final grouped = <String, double>{};
    for (final purchase in purchases) {
      final label =
          '${purchase.purchaseDate.day}/${purchase.purchaseDate.month}';
      grouped[label] = (grouped[label] ?? 0) + purchase.totalAmount;
    }
    return grouped.entries
        .map((entry) => ChartPoint(label: entry.key, value: entry.value))
        .toList();
  }

  List<ChartPoint> _movementByItem(List<dynamic> movements) {
    final grouped = <String, double>{};
    for (final movement in movements) {
      if (movement.quantity < 0) {
        grouped[movement.itemName] =
            (grouped[movement.itemName] ?? 0) + movement.quantity.abs();
      }
    }
    return _topEntries(grouped);
  }

  List<ChartPoint> _categoryConsumption(
    List<dynamic> movements,
    List<InventoryItem> items,
  ) {
    final grouped = <String, double>{};
    for (final movement in movements) {
      if (movement.quantity >= 0) continue;
      final item = items.cast<InventoryItem?>().firstWhere(
        (item) => item?.itemName == movement.itemName,
        orElse: () => null,
      );
      final category = item?.category ?? 'Prepared Food';
      grouped[category] = (grouped[category] ?? 0) + movement.quantity.abs();
    }
    return _topEntries(grouped);
  }

  List<ChartPoint> _sellingItems(List<SaleModel> sales, {required bool top}) {
    final grouped = <String, double>{};
    for (final sale in sales) {
      grouped[sale.menuItemName] =
          (grouped[sale.menuItemName] ?? 0) + sale.quantity;
    }
    final entries = grouped.entries.toList()
      ..sort(
        (a, b) => top ? b.value.compareTo(a.value) : a.value.compareTo(b.value),
      );
    return entries
        .take(5)
        .map((entry) => ChartPoint(label: entry.key, value: entry.value))
        .toList();
  }

  List<ChartPoint> _supplierPerformance(List<PurchaseModel> purchases) {
    final grouped = <String, double>{};
    for (final purchase in purchases) {
      grouped[purchase.supplierName] =
          (grouped[purchase.supplierName] ?? 0) + purchase.totalAmount;
    }
    return _topEntries(grouped);
  }

  List<ChartPoint> _inventoryValue(List<InventoryItem> items) {
    final grouped = <String, double>{};
    for (final item in items) {
      grouped[item.category] = (grouped[item.category] ?? 0) + item.totalValue;
    }
    return _topEntries(grouped);
  }

  List<ChartPoint> _topEntries(Map<String, double> grouped) {
    final entries = grouped.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries
        .take(6)
        .map((entry) => ChartPoint(label: entry.key, value: entry.value))
        .toList();
  }
}

class _RangeSelector extends StatelessWidget {
  final AdminProvider adminProvider;

  const _RangeSelector({required this.adminProvider});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _rangeChip(context, 'Today', AnalyticsRange.today),
        _rangeChip(context, 'This Week', AnalyticsRange.thisWeek),
        _rangeChip(context, 'This Month', AnalyticsRange.thisMonth),
        ActionChip(
          avatar: const Icon(Icons.date_range_rounded),
          label: const Text('Custom Range'),
          onPressed: () async {
            final now = DateTime.now();
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(now.year - 2),
              lastDate: DateTime(now.year + 1),
              initialDateRange:
                  adminProvider.customRange ??
                  DateTimeRange(
                    start: now.subtract(const Duration(days: 30)),
                    end: now,
                  ),
            );
            if (picked != null) {
              adminProvider.setAnalyticsRange(
                AnalyticsRange.custom,
                customRange: picked,
              );
            }
          },
        ),
      ],
    );
  }

  Widget _rangeChip(BuildContext context, String label, AnalyticsRange range) {
    return ChoiceChip(
      label: Text(label),
      selected: adminProvider.analyticsRange == range,
      onSelected: (_) => adminProvider.setAnalyticsRange(range),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MetricTile({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withValues(
                alpha: 0.12,
              ),
              child: Icon(icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
