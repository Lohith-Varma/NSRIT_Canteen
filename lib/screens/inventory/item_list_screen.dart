import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../models/inventory_item.dart';
import '../../providers/inventory_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/low_stock_badge.dart';
import 'add_edit_item_dialog.dart';
import 'item_detail_screen.dart';

class ItemListScreen extends StatefulWidget {
  final String? category;

  const ItemListScreen({super.key, this.category});

  @override
  State<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<InventoryProvider>(context, listen: false);
      provider.setSelectedCategory(widget.category);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleDeleteItem(InventoryItem item) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Item',
      content:
          'Are you sure you want to delete "${item.name}"? The item will be hidden from active inventory and retained for audit history.',
      confirmText: 'Delete Item',
      isDanger: true,
    );

    if (confirmed == true && mounted) {
      final provider = Provider.of<InventoryProvider>(context, listen: false);
      final success = await provider.deleteItem(item.id);
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item "${item.name}" deleted successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Failed to delete item.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final items = inventoryProvider.filteredItems;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category ?? 'All Inventory Items'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Inventory Item',
            onPressed: () {
              AddEditItemDialog.show(context, initialCategory: widget.category);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  inventoryProvider.setSearchQuery(value);
                },
                decoration: InputDecoration(
                  hintText: 'Search items by name or category...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            inventoryProvider.setSearchQuery('');
                          },
                        )
                      : null,
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: inventoryProvider.selectedStatus == null,
                    onSelected: () => inventoryProvider.setSelectedStatus(null),
                  ),
                  _FilterChip(
                    label: 'Low Stock',
                    selected: inventoryProvider.selectedStatus == 'low_stock',
                    onSelected: () =>
                        inventoryProvider.setSelectedStatus('low_stock'),
                  ),
                  _FilterChip(
                    label: 'Out of Stock',
                    selected:
                        inventoryProvider.selectedStatus == 'out_of_stock',
                    onSelected: () =>
                        inventoryProvider.setSelectedStatus('out_of_stock'),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<InventorySortOption>(
                    value: inventoryProvider.sortOption,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(
                        value: InventorySortOption.nameAsc,
                        child: Text('Name A-Z'),
                      ),
                      DropdownMenuItem(
                        value: InventorySortOption.nameDesc,
                        child: Text('Name Z-A'),
                      ),
                      DropdownMenuItem(
                        value: InventorySortOption.quantityLow,
                        child: Text('Stock Low-High'),
                      ),
                      DropdownMenuItem(
                        value: InventorySortOption.quantityHigh,
                        child: Text('Stock High-Low'),
                      ),
                      DropdownMenuItem(
                        value: InventorySortOption.updatedNewest,
                        child: Text('Recently Updated'),
                      ),
                      DropdownMenuItem(
                        value: InventorySortOption.expirySoon,
                        child: Text('Expiry Soon'),
                      ),
                    ],
                    onChanged: (option) {
                      if (option != null) {
                        inventoryProvider.setSortOption(option);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Item List Content
            Expanded(
              child: inventoryProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : items.isEmpty
                  ? EmptyStateWidget(
                      title: 'No Inventory Items Found',
                      message: widget.category != null
                          ? 'No items registered under "${widget.category}" category yet.'
                          : 'No items match your search filter.',
                      icon: Icons.inventory_2_outlined,
                      buttonText: 'Add New Item',
                      onButtonPressed: () {
                        AddEditItemDialog.show(
                          context,
                          initialCategory: widget.category,
                        );
                      },
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final categoryColor = AppColors.getCategoryColor(
                          item.category,
                        );

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ItemDetailScreen(item: item),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: categoryColor.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          AppConstants.getCategoryIcon(
                                            item.category,
                                          ),
                                          color: categoryColor,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.name,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Category: ${item.category}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: theme
                                                    .textTheme
                                                    .bodySmall
                                                    ?.color,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            AddEditItemDialog.show(
                                              context,
                                              item: item,
                                            );
                                          } else if (value == 'delete') {
                                            _handleDeleteItem(item);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.edit_outlined,
                                                  size: 18,
                                                ),
                                                SizedBox(width: 8),
                                                Text('Edit Item'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.delete_outline,
                                                  size: 18,
                                                  color: AppColors.danger,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Delete Item',
                                                  style: TextStyle(
                                                    color: AppColors.danger,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 20),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Current Stock',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: theme
                                                  .textTheme
                                                  .bodySmall
                                                  ?.color,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Text(
                                                Formatters.quantityWithUnit(
                                                  item.totalStock,
                                                  item.unit,
                                                ),
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      item.isOutOfStock ||
                                                          item.isLowStock
                                                      ? AppColors.danger
                                                      : AppColors.primary,
                                                ),
                                              ),
                                              if (item.isOutOfStock) ...[
                                                const SizedBox(width: 8),
                                                const _StatusBadge(
                                                  label: 'Out',
                                                  color: AppColors.danger,
                                                ),
                                              ] else if (item.isLowStock) ...[
                                                const SizedBox(width: 8),
                                                const LowStockBadge(
                                                  isCompact: true,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Selling Price',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: theme
                                                  .textTheme
                                                  .bodySmall
                                                  ?.color,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            Formatters.currency(
                                              item.sellingPrice,
                                            ),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
