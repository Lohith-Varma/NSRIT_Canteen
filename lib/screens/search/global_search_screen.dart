import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/search_result_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/kitchen_provider.dart';
import '../../providers/purchase_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final results = _buildResults(context, _query);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SearchBar(
            hintText:
                'Search inventory, suppliers, purchases, menu, recipes, sales, users',
            leading: const Icon(Icons.search_rounded),
            autoFocus: true,
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        Expanded(
          child: _query.trim().isEmpty
              ? const EmptyStateWidget(
                  title: 'Global Search',
                  message: 'Start typing to search across all modules.',
                  icon: Icons.manage_search_rounded,
                )
              : results.isEmpty
              ? const EmptyStateWidget(
                  title: 'No Results',
                  message: 'Try another search term.',
                  icon: Icons.search_off_rounded,
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final result = results[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Icon(result.icon)),
                        title: Text(result.title),
                        subtitle: Text('${result.module} - ${result.subtitle}'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap:
                            result.onTap ??
                            () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Open ${result.module}: ${result.title}',
                                  ),
                                ),
                              );
                            },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  List<SearchResultModel> _buildResults(BuildContext context, String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return const [];

    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final supplierProvider = Provider.of<SupplierProvider>(context);
    final purchaseProvider = Provider.of<PurchaseProvider>(context);
    final kitchenProvider = Provider.of<KitchenProvider>(context);
    final adminProvider = Provider.of<AdminProvider>(context);
    final results = <SearchResultModel>[];

    bool matches(String value) => value.toLowerCase().contains(normalized);

    for (final item in inventoryProvider.items) {
      if (matches(item.itemName) || matches(item.category)) {
        results.add(
          SearchResultModel(
            id: item.id,
            title: item.itemName,
            subtitle:
                '${item.category}, ${Formatters.quantityWithUnit(item.totalStock, item.unit)}',
            module: 'Inventory',
            icon: Icons.inventory_2_rounded,
          ),
        );
      }
    }

    for (final supplier in supplierProvider.suppliers) {
      if (matches(supplier.name) ||
          matches(supplier.email) ||
          matches(supplier.phone)) {
        results.add(
          SearchResultModel(
            id: supplier.id,
            title: supplier.name,
            subtitle: supplier.email,
            module: 'Suppliers',
            icon: Icons.people_rounded,
          ),
        );
      }
    }

    for (final purchase in purchaseProvider.purchases) {
      if (matches(purchase.itemName) ||
          matches(purchase.supplierName) ||
          matches(purchase.invoiceNumber)) {
        results.add(
          SearchResultModel(
            id: purchase.id,
            title: purchase.itemName,
            subtitle:
                '${purchase.supplierName}, ${Formatters.currency(purchase.totalAmount)}',
            module: 'Purchases',
            icon: Icons.shopping_cart_rounded,
          ),
        );
      }
    }

    for (final item in kitchenProvider.menuItems) {
      if (matches(item.name) || matches(item.section)) {
        results.add(
          SearchResultModel(
            id: item.id,
            title: item.name,
            subtitle:
                '${item.section}, ${Formatters.currency(item.sellingPrice)}',
            module: 'Menu',
            icon: Icons.restaurant_menu_rounded,
          ),
        );
      }
    }

    for (final recipe in kitchenProvider.recipes) {
      if (matches(recipe.menuItemName) ||
          recipe.ingredients.any(
            (ingredient) => matches(ingredient.ingredientName),
          )) {
        results.add(
          SearchResultModel(
            id: recipe.id,
            title: recipe.menuItemName,
            subtitle: '${recipe.ingredients.length} ingredients',
            module: 'Recipes',
            icon: Icons.menu_book_rounded,
          ),
        );
      }
    }

    for (final food in kitchenProvider.preparedFood) {
      if (matches(food.menuItemName)) {
        results.add(
          SearchResultModel(
            id: food.id,
            title: food.menuItemName,
            subtitle:
                '${Formatters.number(food.quantityAvailable)} prepared units',
            module: 'Prepared Food',
            icon: Icons.soup_kitchen_rounded,
          ),
        );
      }
    }

    for (final sale in kitchenProvider.sales) {
      if (matches(sale.menuItemName) || matches(sale.paymentMethod)) {
        results.add(
          SearchResultModel(
            id: sale.id,
            title: sale.menuItemName,
            subtitle:
                '${sale.paymentMethod}, ${Formatters.currency(sale.totalAmount)}',
            module: 'Sales',
            icon: Icons.point_of_sale_rounded,
          ),
        );
      }
    }

    for (final movement in kitchenProvider.stockMovements) {
      if (matches(movement.itemName) ||
          matches(movement.action) ||
          matches(movement.reference)) {
        results.add(
          SearchResultModel(
            id: movement.id,
            title: movement.itemName,
            subtitle:
                '${movement.action}, ${Formatters.quantityWithUnit(movement.quantity, movement.unit)}',
            module: 'Stock Movements',
            icon: Icons.swap_vert_rounded,
          ),
        );
      }
    }

    for (final user in adminProvider.users) {
      if (matches(user.email) ||
          matches(user.displayName ?? '') ||
          matches(user.role)) {
        results.add(
          SearchResultModel(
            id: user.uid,
            title: user.displayName ?? user.email,
            subtitle: '${user.email}, ${user.role}',
            module: 'Users',
            icon: Icons.manage_accounts_rounded,
          ),
        );
      }
    }

    return results.take(80).toList();
  }
}
