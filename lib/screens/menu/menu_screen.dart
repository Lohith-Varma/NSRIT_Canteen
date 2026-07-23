import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/menu_item_model.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/kitchen_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import 'menu_item_detail_screen.dart';
import 'recipe_list_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final kitchenProvider = Provider.of<KitchenProvider>(context);
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 1000 ? 4 : (width > 650 ? 2 : 1);

    return RefreshIndicator(
      onRefresh: kitchenProvider.loadKitchenData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: SearchBar(
                  hintText: 'Search menu items',
                  leading: const Icon(Icons.search_rounded),
                  onChanged: kitchenProvider.setMenuSearchQuery,
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                tooltip: 'Recipes',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RecipeListScreen()),
                  );
                },
                icon: const Icon(Icons.menu_book_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (kitchenProvider.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            )
          else
            GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: width > 650 ? 1.5 : 1.9,
              children: kitchenProvider.sections.map((section) {
                final items = kitchenProvider.menuItemsBySection(section);
                final icon = _sectionIcon(section);
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MenuSectionScreen(section: section),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: theme.colorScheme.primary
                                .withValues(alpha: 0.12),
                            child: Icon(icon, color: theme.colorScheme.primary),
                          ),
                          const Spacer(),
                          Text(
                            section,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('${items.length} menu items'),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  IconData _sectionIcon(String section) {
    switch (section) {
      case 'Breakfast':
        return Icons.free_breakfast_rounded;
      case 'Lunch':
        return Icons.lunch_dining_rounded;
      case 'Evening Snacks':
        return Icons.local_cafe_rounded;
      case 'Dinner':
        return Icons.dinner_dining_rounded;
      default:
        return Icons.restaurant_menu_rounded;
    }
  }
}

class MenuSectionScreen extends StatelessWidget {
  final String section;

  const MenuSectionScreen({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    final kitchenProvider = Provider.of<KitchenProvider>(context);
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final items = kitchenProvider.menuItemsBySection(section);
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 1000 ? 3 : (width > 650 ? 2 : 1);

    return Scaffold(
      appBar: AppBar(title: Text(section)),
      body: items.isEmpty
          ? const EmptyStateWidget(
              title: 'No Menu Items',
              message: 'No items match the current menu search.',
              icon: Icons.restaurant_menu_rounded,
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: width > 650 ? 1.2 : 1.05,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final available = kitchenProvider.isMenuItemAvailable(
                  item,
                  inventoryProvider.items,
                );
                return _MenuItemCard(item: item, available: available);
              },
            ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final MenuItemModel item;
  final bool available;

  const _MenuItemCard({required this.item, required this.available});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kitchenProvider = Provider.of<KitchenProvider>(
      context,
      listen: false,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MenuItemDetailScreen(menuItem: item),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.restaurant_rounded, size: 48),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(available ? 'Available' : 'Unavailable'),
                      backgroundColor: available
                          ? Colors.green.withValues(alpha: 0.18)
                          : Colors.red.withValues(alpha: 0.18),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        Formatters.currency(item.sellingPrice),
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${Formatters.number(kitchenProvider.preparedQuantityForMenuItem(item.id))} ready',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
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
