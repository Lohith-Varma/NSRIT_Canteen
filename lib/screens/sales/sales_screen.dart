import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/menu_item_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/kitchen_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  MenuItemModel? _selectedItem;
  String _paymentMethod = 'Cash';
  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _completeSale() async {
    final item = _selectedItem;
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    if (item == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select an item and enter a valid quantity.'),
        ),
      );
      return;
    }

    final kitchenProvider = Provider.of<KitchenProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user =
        authProvider.user?.displayName ?? authProvider.user?.email ?? 'Cashier';
    final success = await kitchenProvider.completeSale(
      menuItem: item,
      quantity: quantity,
      paymentMethod: _paymentMethod,
      user: user,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Sale completed.'
              : kitchenProvider.errorMessage ?? 'Sale failed.',
        ),
      ),
    );
    if (success) {
      setState(() {
        _quantityController.text = '1';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<KitchenProvider>(context);
    final sellableItems = provider.menuItems
        .where((item) => provider.preparedQuantityForMenuItem(item.id) > 0)
        .toList();
    final selectedItemStillValid = sellableItems.any(
      (item) => item.id == _selectedItem?.id,
    );
    if (!selectedItemStillValid) {
      _selectedItem = sellableItems.isEmpty ? null : sellableItems.first;
    }
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final total = (_selectedItem?.sellingPrice ?? 0) * quantity;

    return RefreshIndicator(
      onRefresh: provider.loadKitchenData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New Sale',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<MenuItemModel>(
                    initialValue: _selectedItem,
                    decoration: const InputDecoration(labelText: 'Menu Item'),
                    items: sellableItems.map((item) {
                      final ready = provider.preparedQuantityForMenuItem(
                        item.id,
                      );
                      return DropdownMenuItem(
                        value: item,
                        child: Text(
                          '${item.name} (${Formatters.number(ready)} ready)',
                        ),
                      );
                    }).toList(),
                    onChanged: (item) {
                      setState(() {
                        _selectedItem = item;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'Cash',
                        label: Text('Cash'),
                        icon: Icon(Icons.payments_rounded),
                      ),
                      ButtonSegment(
                        value: 'UPI',
                        label: Text('UPI'),
                        icon: Icon(Icons.qr_code_rounded),
                      ),
                      ButtonSegment(
                        value: 'Card',
                        label: Text('Card'),
                        icon: Icon(Icons.credit_card_rounded),
                      ),
                    ],
                    selected: {_paymentMethod},
                    onSelectionChanged: (selection) {
                      setState(() {
                        _paymentMethod = selection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Total: ${Formatters.currency(total)}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: provider.isLoading ? null : _completeSale,
                        icon: provider.isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.point_of_sale_rounded),
                        label: const Text('Complete Sale'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SearchBar(
            hintText: 'Search sales',
            leading: const Icon(Icons.search_rounded),
            onChanged: provider.setSalesSearchQuery,
          ),
          const SizedBox(height: 12),
          if (provider.filteredSales.isEmpty)
            const EmptyStateWidget(
              title: 'No Sales Recorded',
              message: 'Prepared items sold from this screen will appear here.',
              icon: Icons.receipt_long_outlined,
            )
          else
            ...provider.filteredSales.map((sale) {
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.receipt_rounded),
                  ),
                  title: Text(
                    sale.menuItemName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${Formatters.formatDateTime(sale.soldAt)} - ${sale.paymentMethod}',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Formatters.currency(sale.totalAmount),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('${Formatters.number(sale.quantity)} qty'),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
