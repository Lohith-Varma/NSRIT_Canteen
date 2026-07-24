import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/menu_item_model.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/kitchen_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import 'menu_item_detail_screen.dart';
import 'recipe_list_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final kitchenProvider = Provider.of<KitchenProvider>(context);

    return Scaffold(
      body: RefreshIndicator(
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
                      MaterialPageRoute(
                        builder: (_) => const RecipeListScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.menu_book_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (kitchenProvider.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  kitchenProvider.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (kitchenProvider.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              ...kitchenProvider.sections.map(
                (section) => _MenuSectionGroup(section: section),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMenuItemDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Menu Item'),
      ),
    );
  }
}

class _MenuSectionGroup extends StatelessWidget {
  final String section;

  const _MenuSectionGroup({required this.section});

  @override
  Widget build(BuildContext context) {
    final kitchenProvider = Provider.of<KitchenProvider>(context);
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final items = kitchenProvider.menuItemsBySection(section);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_sectionIcon(section), color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                section,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Chip(
                visualDensity: VisualDensity.compact,
                label: Text('${items.length} items'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const EmptyStateWidget(
              title: 'No Menu Items',
              message: 'Add menu items to this section.',
              icon: Icons.restaurant_menu_rounded,
            )
          else
            ...items.map((item) {
              final available = kitchenProvider.isMenuItemAvailable(
                item,
                inventoryProvider.items,
              );
              return _MenuItemTile(item: item, available: available);
            }),
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
      case 'Dinner':
        return Icons.dinner_dining_rounded;
      default:
        return Icons.restaurant_menu_rounded;
    }
  }
}

class _MenuItemTile extends StatelessWidget {
  final MenuItemModel item;
  final bool available;

  const _MenuItemTile({required this.item, required this.available});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 56,
            height: 56,
            child: Image.network(
              item.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => ColoredBox(
                color: theme.colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.restaurant_rounded),
              ),
            ),
          ),
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${Formatters.currency(item.sellingPrice)} • '
          '${item.isActive ? 'Active' : 'Inactive'} • '
          '${available ? 'Available' : 'Unavailable'}',
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_rounded),
              onPressed: () => _showMenuItemDialog(context, item: item),
            ),
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => _deleteMenuItem(context, item),
            ),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MenuItemDetailScreen(menuItem: item),
            ),
          );
        },
      ),
    );
  }
}

Future<void> _showMenuItemDialog(
  BuildContext context, {
  MenuItemModel? item,
}) async {
  final provider = context.read<KitchenProvider>();
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController(text: item?.name ?? '');
  final priceController = TextEditingController(
    text: item == null ? '' : item.sellingPrice.toStringAsFixed(0),
  );
  final imageController = TextEditingController(text: item?.imageUrl ?? '');
  var section = item?.section ?? provider.sections.first;
  var isActive = item?.isActive ?? true;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(item == null ? 'Add Menu Item' : 'Edit Menu Item'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Item name'),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter item name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: section,
                      decoration: const InputDecoration(labelText: 'Section'),
                      items: provider.sections
                          .map(
                            (entry) => DropdownMenuItem(
                              value: entry,
                              child: Text(entry),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => section = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: priceController,
                      decoration: const InputDecoration(labelText: 'Price'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final price = double.tryParse(value ?? '');
                        if (price == null || price <= 0) {
                          return 'Enter a valid price';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: imageController,
                      decoration: const InputDecoration(
                        labelText: 'Image URL',
                        hintText: 'Optional',
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Active'),
                      value: isActive,
                      onChanged: (value) => setState(() => isActive = value),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final now = DateTime.now();
                  final name = nameController.text.trim();
                  final menuItem = MenuItemModel(
                    id: item?.id ?? '',
                    name: name,
                    section: section,
                    imageUrl: _imageUrlOrDefault(
                      imageController.text.trim(),
                      name,
                    ),
                    sellingPrice: double.parse(priceController.text),
                    isActive: isActive,
                    createdAt: item?.createdAt ?? now,
                    updatedAt: now,
                  );
                  final success = item == null
                      ? await provider.addMenuItem(menuItem)
                      : await provider.updateMenuItem(menuItem);
                  if (success && dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );

  nameController.dispose();
  priceController.dispose();
  imageController.dispose();
}

Future<void> _deleteMenuItem(BuildContext context, MenuItemModel item) async {
  final confirmed = await ConfirmDialog.show(
    context,
    title: 'Delete Menu Item',
    content: 'Delete ${item.name} from the menu?',
    confirmText: 'Delete',
    cancelText: 'Cancel',
    isDanger: true,
  );
  if (confirmed != true || !context.mounted) return;

  final success = await context.read<KitchenProvider>().deleteMenuItem(item.id);
  if (!success || !context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('${item.name} deleted')),
  );
}

String _imageUrlOrDefault(String value, String name) {
  if (value.isNotEmpty) return value;
  final encoded = Uri.encodeComponent(name);
  return 'https://source.unsplash.com/600x400/?$encoded';
}
