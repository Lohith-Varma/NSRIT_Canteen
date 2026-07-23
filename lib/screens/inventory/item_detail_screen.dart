import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../models/inventory_item.dart';
import '../../providers/inventory_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/low_stock_badge.dart';
import 'edit_inventory_screen.dart';
import '../purchases/add_purchase_screen.dart';

class ItemDetailScreen extends StatelessWidget {
  final InventoryItem item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = AppColors.getCategoryColor(item.category);

    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Edit Inventory Item',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EditInventoryScreen(item: item),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_shopping_cart_rounded),
            tooltip: 'Add Purchase for this Item',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddPurchaseScreen(preselectedItem: item),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Main Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        AppConstants.getCategoryIcon(item.category),
                        color: categoryColor,
                        size: 36,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Chip(
                                label: Text(
                                  item.category,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: categoryColor,
                                  ),
                                ),
                                backgroundColor: categoryColor.withValues(alpha: 0.1),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              const SizedBox(width: 8),
                              Chip(
                                label: Text(
                                  'Unit: ${item.unit}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ],
                              ),
                              if (item.isOutOfStock) ...[
                                const SizedBox(height: 8),
                                const _DetailStatusBadge(
                                  label: 'Out of Stock',
                                  color: AppColors.danger,
                                  icon: Icons.remove_shopping_cart_rounded,
                                ),
                              ] else if (item.isLowStock) ...[
                                const SizedBox(height: 8),
                                const LowStockBadge(),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Key Metrics Grid
            Text(
              'Stock & Cost Metrics',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.6,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildMetricCard(
                  title: 'Total Stock',
                  value: Formatters.quantityWithUnit(item.totalStock, item.unit),
                  subtitle: 'Min: ${item.minimumStock} ${item.unit} / Max: ${item.maximumStock} ${item.unit}',
                  icon: Icons.inventory_rounded,
                  color: item.isOutOfStock || item.isLowStock ? AppColors.danger : AppColors.primary,
                ),
                _buildMetricCard(
                  title: 'Purchase Price',
                  value: Formatters.currency(item.purchasePrice),
                  subtitle: 'Per ${item.unit}',
                  icon: Icons.price_check_rounded,
                  color: AppColors.info,
                ),
                _buildMetricCard(
                  title: 'Selling Price',
                  value: Formatters.currency(item.sellingPrice),
                  subtitle: 'Per ${item.unit}',
                  icon: Icons.sell_rounded,
                  color: AppColors.success,
                ),
                _buildMetricCard(
                  title: 'Stock Value',
                  value: Formatters.currency(item.totalValue),
                  subtitle: item.lots.isEmpty ? 'Quantity x purchase price' : '${item.lots.length} lots',
                  icon: Icons.account_balance_wallet_rounded,
                  color: AppColors.secondary,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Inventory Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _InfoRow(label: 'Supplier', value: item.supplier.isEmpty ? 'Not specified' : item.supplier),
                    _InfoRow(label: 'Storage Location', value: item.storageLocation.isEmpty ? 'Not specified' : item.storageLocation),
                    _InfoRow(label: 'Expiry Date', value: item.expiryDate == null ? 'Not set' : Formatters.formatDate(item.expiryDate!)),
                    _InfoRow(label: 'Status', value: item.isOutOfStock ? 'Out of stock' : item.isLowStock ? 'Low stock' : 'Healthy'),
                    _InfoRow(label: 'Updated', value: Formatters.formatDateTime(item.updatedAt)),
                    if (item.notes.isNotEmpty) _InfoRow(label: 'Notes', value: item.notes),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Lot Breakdown Section (CRITICAL REQUIREMENT)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Lot History Breakdown',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${item.lots.length} Active Lots',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Every purchase is stored as a separate lot. Average cost is computed as: Sum(Lot Qty × Lot Price) / Total Qty.',
              style: TextStyle(
                fontSize: 12,
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),

            item.lots.isEmpty
                ? const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(
                        child: Text(
                          'No purchase lots recorded for this item yet. Record a purchase entry to create lot 1.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: item.lots.length,
                    itemBuilder: (context, index) {
                      final lot = item.lots[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Lot #${index + 1} (${lot.invoiceNumber.isNotEmpty ? lot.invoiceNumber : lot.id})',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    Formatters.formatDate(lot.purchaseDate),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.textTheme.bodySmall?.color,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Quantity: ${Formatters.quantityWithUnit(lot.quantity, lot.unit)}',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    'Purchase Price: ₹${lot.unitPrice} / ${lot.unit}',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'Lot Total Value: ${Formatters.currency(lot.totalLotValue)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
              ),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Delete Inventory Item'),
              onPressed: () async {
                final confirmed = await ConfirmDialog.show(
                  context,
                  title: 'Delete Item',
                  content: 'This will soft delete "${item.name}" from active inventory.',
                  confirmText: 'Delete',
                  isDanger: true,
                );
                if (confirmed == true && context.mounted) {
                  final provider = context.read<InventoryProvider>();
                  final success = await provider.deleteItem(item.id);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? '${item.name} deleted successfully.'
                            : provider.errorMessage ?? 'Failed to delete item.',
                      ),
                      backgroundColor: success ? AppColors.success : AppColors.danger,
                    ),
                  );
                  if (success) {
                    Navigator.of(context).pop();
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
                ),
                Icon(icon, color: color, size: 18),
              ],
            ),
            Text(
              value,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailStatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _DetailStatusBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
