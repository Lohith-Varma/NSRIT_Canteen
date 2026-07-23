import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../providers/purchase_provider.dart';
import '../../providers/kitchen_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/low_stock_badge.dart';
import '../../widgets/empty_state.dart';
import '../purchases/add_purchase_screen.dart';
import '../inventory/add_inventory_screen.dart';
import '../inventory/item_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final supplierProvider = Provider.of<SupplierProvider>(context);
    final purchaseProvider = Provider.of<PurchaseProvider>(context);
    final kitchenProvider = Provider.of<KitchenProvider>(context);

    final screenWidth = MediaQuery.of(context).size.width;
    final gridCrossAxisCount = screenWidth > 900 ? 3 : (screenWidth > 600 ? 2 : 2);

    final lowStockList = inventoryProvider.lowStockItems;
    final recentPurchases = purchaseProvider.recentPurchases;

    return RefreshIndicator(
      onRefresh: () async {
        await inventoryProvider.loadInventory();
        await supplierProvider.loadSuppliers();
        await purchaseProvider.loadPurchases();
        await kitchenProvider.loadKitchenData();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick action banner
            Card(
              color: isDark ? AppColors.darkSurface : AppColors.primary,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Smart Canteen Inventory',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Lot-based cost tracking & automated stock updates',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AddPurchaseScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_shopping_cart, size: 18),
                          label: const Text('+ Purchase'),
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.7)),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AddInventoryScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Item'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Summary KPI Cards Grid
            Text(
              'Overview Statistics',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: gridCrossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                StatCard(
                  title: 'Total Items',
                  value: Formatters.number(inventoryProvider.totalItems.toDouble()),
                  icon: Icons.inventory_2_rounded,
                  color: AppColors.primary,
                ),
                StatCard(
                  title: 'Total Categories',
                  value: Formatters.number(inventoryProvider.totalCategories.toDouble()),
                  icon: Icons.category_rounded,
                  color: AppColors.info,
                ),
                StatCard(
                  title: 'Total Suppliers',
                  value: Formatters.number(supplierProvider.totalSuppliers.toDouble()),
                  icon: Icons.people_rounded,
                  color: AppColors.secondary,
                ),
                StatCard(
                  title: 'Total Purchases',
                  value: Formatters.number(purchaseProvider.totalPurchases.toDouble()),
                  icon: Icons.shopping_bag_rounded,
                  color: const Color(0xFF8B5CF6),
                ),
                StatCard(
                  title: 'Total Inventory Value',
                  value: Formatters.currency(inventoryProvider.totalInventoryValue),
                  icon: Icons.account_balance_wallet_rounded,
                  color: AppColors.success,
                  subtitle: 'Weighted Avg Valuation',
                ),
                StatCard(
                  title: 'Low Stock Alert',
                  value: Formatters.number(inventoryProvider.lowStockCount.toDouble()),
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.danger,
                  subtitle: inventoryProvider.lowStockCount > 0 ? 'Requires Restock' : 'Stock Healthy',
                ),
                StatCard(
                  title: 'Out of Stock',
                  value: Formatters.number(inventoryProvider.outOfStockCount.toDouble()),
                  icon: Icons.remove_shopping_cart_rounded,
                  color: AppColors.warning,
                  subtitle: inventoryProvider.outOfStockCount > 0 ? 'Immediate Action' : 'None',
                ),
                StatCard(
                  title: 'Healthy Stock',
                  value: Formatters.number(inventoryProvider.healthyStockCount.toDouble()),
                  icon: Icons.check_circle_rounded,
                  color: AppColors.success,
                  subtitle: 'Above minimum',
                ),
                StatCard(
                  title: 'Menu Items',
                  value: Formatters.number(kitchenProvider.totalMenuItems.toDouble()),
                  icon: Icons.restaurant_menu_rounded,
                  color: AppColors.info,
                  subtitle: 'Smart kitchen',
                ),
                StatCard(
                  title: 'Prepared Food',
                  value: Formatters.number(kitchenProvider.preparedFoodAvailable),
                  icon: Icons.soup_kitchen_rounded,
                  color: AppColors.secondary,
                  subtitle: 'Available units',
                ),
                StatCard(
                  title: 'Sales Revenue',
                  value: Formatters.currency(kitchenProvider.totalSalesAmount),
                  icon: Icons.point_of_sale_rounded,
                  color: AppColors.success,
                  subtitle: 'Recorded sales',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Low Stock Items Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
                    const SizedBox(width: 8),
                    Text(
                      'Low Stock Items',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (lowStockList.isNotEmpty)
                  Chip(
                    backgroundColor: AppColors.danger.withValues(alpha: 0.15),
                    label: Text(
                      '${lowStockList.length} Items Below Min',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            lowStockList.isEmpty
                ? const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: AppColors.success, size: 32),
                          SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'All inventory stock levels are healthy!',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'No items currently fall below their specified minimum stock threshold.',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: lowStockList.length,
                    itemBuilder: (context, index) {
                      final item = lowStockList[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ItemDetailScreen(item: item),
                              ),
                            );
                          },
                          leading: CircleAvatar(
                            backgroundColor: AppColors.danger.withValues(alpha: 0.15),
                            child: const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 20),
                          ),
                          title: Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Category: ${item.category} • Min Required: ${Formatters.quantityWithUnit(item.minStock, item.unit)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                Formatters.quantityWithUnit(item.totalStock, item.unit),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.danger,
                                  fontSize: 14,
                                ),
                              ),
                              const LowStockBadge(isCompact: true),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 24),

            // Recent Purchases Feed Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history_rounded, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Recent Purchases',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            recentPurchases.isEmpty
                ? const EmptyStateWidget(
                    title: 'No Purchases Recorded',
                    message: 'Click "+ Purchase" above to add your first canteen purchase entry.',
                    icon: Icons.receipt_long_outlined,
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentPurchases.length,
                    itemBuilder: (context, index) {
                      final purchase = recentPurchases[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 20),
                          ),
                          title: Text(
                            purchase.itemName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${purchase.supplierName} • ${Formatters.formatDate(purchase.purchaseDate)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                Formatters.currency(purchase.totalAmount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${Formatters.number(purchase.quantity)} ${purchase.unit} @ ₹${purchase.pricePerUnit}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
