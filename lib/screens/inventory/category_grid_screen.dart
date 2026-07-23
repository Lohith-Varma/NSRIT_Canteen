import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/app_colors.dart';
import '../../providers/inventory_provider.dart';
import '../../widgets/custom_text_field.dart';
import 'item_list_screen.dart';

class CategoryGridScreen extends StatelessWidget {
  const CategoryGridScreen({super.key});

  Future<void> _showCategoryDialog(BuildContext context) async {
    final controller = TextEditingController();
    final provider = Provider.of<InventoryProvider>(context, listen: false);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Category'),
          content: CustomTextField(
            label: 'Category Name',
            hint: 'e.g. Bakery',
            controller: controller,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add'),
              onPressed: () async {
                final category = controller.text.trim();
                if (category.isEmpty) return;
                await provider.addCategory(category);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );

    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final counts = inventoryProvider.categoryCounts;

    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 900 ? 4 : (screenWidth > 600 ? 3 : 2);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Search & Header Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CustomTextField(
                label: '',
                hint: 'Search inventory items or categories...',
                prefixIcon: const Icon(Icons.search_rounded),
                onChanged: (value) {
                  inventoryProvider.setSearchQuery(value);
                },
              ),
            ),

            // View All Items Shortcut Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                color: theme.colorScheme.primary.withValues(
                  alpha: isDark ? 0.2 : 0.08,
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.list_alt_rounded,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    'View All Inventory Items',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${inventoryProvider.totalItems} Total items registered in canteen',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ItemListScreen(category: null),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Category Cards Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Inventory Categories',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemCount: inventoryProvider.categories.length,
                itemBuilder: (context, index) {
                  final category = inventoryProvider.categories[index];
                  final itemCount = counts[category] ?? 0;
                  final categoryColor = AppColors.getCategoryColor(category);
                  final icon = AppConstants.getCategoryIcon(category);

                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ItemListScreen(category: category),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: categoryColor.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    icon,
                                    color: categoryColor,
                                    size: 24,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '$itemCount items',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (!AppConstants.categories.contains(
                                          category,
                                        ) &&
                                        itemCount == 0)
                                      IconButton(
                                        tooltip: 'Delete category',
                                        visualDensity: VisualDensity.compact,
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          size: 18,
                                        ),
                                        onPressed: () => inventoryProvider
                                            .deleteCategory(category),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Tap to view items',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showCategoryDialog(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('New Category'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
