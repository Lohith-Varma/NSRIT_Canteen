import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/menu_item_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/kitchen_provider.dart';
import '../../services/kitchen_service.dart';
import '../../utils/formatters.dart';

class MenuItemDetailScreen extends StatefulWidget {
  final MenuItemModel menuItem;

  const MenuItemDetailScreen({
    super.key,
    required this.menuItem,
  });

  @override
  State<MenuItemDetailScreen> createState() => _MenuItemDetailScreenState();
}

class _MenuItemDetailScreenState extends State<MenuItemDetailScreen> {
  final TextEditingController _quantityController = TextEditingController(text: '10');
  PreparationPreview? _preview;
  bool _isPreviewLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPreview());
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _loadPreview() async {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    if (quantity <= 0) return;

    setState(() {
      _isPreviewLoading = true;
    });
    try {
      final provider = Provider.of<KitchenProvider>(context, listen: false);
      final preview = await provider.buildPreparationPreview(
        menuItem: widget.menuItem,
        preparationQuantity: quantity,
      );
      if (mounted) {
        setState(() {
          _preview = preview;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPreviewLoading = false;
        });
      }
    }
  }

  Future<void> _confirmPreparation() async {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final kitchenProvider = Provider.of<KitchenProvider>(context, listen: false);
    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user?.displayName ?? authProvider.user?.email ?? 'Kitchen User';

    final success = await kitchenProvider.prepareMenuItem(
      menuItem: widget.menuItem,
      preparationQuantity: quantity,
      user: user,
    );
    await inventoryProvider.loadInventory();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '${widget.menuItem.name} prepared successfully.'
              : kitchenProvider.errorMessage ?? 'Preparation failed.',
        ),
      ),
    );
    if (success) {
      await _loadPreview();
    }
  }

  @override
  Widget build(BuildContext context) {
    final kitchenProvider = Provider.of<KitchenProvider>(context);
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final recipe = kitchenProvider.recipeForMenuItem(widget.menuItem.id);
    final available = kitchenProvider.isMenuItemAvailable(
      widget.menuItem,
      inventoryProvider.items,
    );
    final readyQuantity = kitchenProvider.preparedQuantityForMenuItem(widget.menuItem.id);

    return Scaffold(
      appBar: AppBar(title: Text(widget.menuItem.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                widget.menuItem.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: Colors.black12,
                  child: Center(child: Icon(Icons.restaurant_rounded, size: 56)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Chip(label: Text(widget.menuItem.section)),
              Chip(label: Text(available ? 'Inventory Available' : 'Inventory Short')),
              Chip(label: Text('${Formatters.number(readyQuantity)} prepared units ready')),
              Chip(label: Text(Formatters.currency(widget.menuItem.sellingPrice))),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _quantityController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Preparation Quantity',
              suffixIcon: IconButton(
                tooltip: 'Refresh Cost',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _loadPreview,
              ),
            ),
            onSubmitted: (_) => _loadPreview(),
          ),
          const SizedBox(height: 16),
          if (recipe == null)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Recipe is not available for this menu item.'),
              ),
            )
          else if (_isPreviewLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_preview != null)
            _PreparationPreviewCard(
              menuItem: widget.menuItem,
              preview: _preview!,
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _preview?.canPrepare == true && !kitchenProvider.isLoading
                ? _confirmPreparation
                : null,
            icon: kitchenProvider.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.soup_kitchen_rounded),
            label: const Text('Confirm Preparation'),
          ),
        ],
      ),
    );
  }
}

class _PreparationPreviewCard extends StatelessWidget {
  final MenuItemModel menuItem;
  final PreparationPreview preview;

  const _PreparationPreviewCard({
    required this.menuItem,
    required this.preview,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preparationQuantity = preview.recipe.preparationCostPerUnit == 0
        ? 0.0
        : preview.preparationCost / preview.recipe.preparationCostPerUnit;
    final estimatedProfit =
        (menuItem.sellingPrice * preparationQuantity) - preview.actualFoodCost;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recipe and Inventory',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...preview.recipe.ingredients.map((ingredient) {
              final inventory = preview.inventoryByIngredient[ingredient.ingredientName];
              final requiredQty =
                  preview.requiredQuantityByIngredient[ingredient.ingredientName] ?? 0;
              final availableQty =
                  preview.availableQuantityByIngredient[ingredient.ingredientName] ?? 0;
              final cost = preview.estimatedCostByIngredient[ingredient.ingredientName] ?? 0;
              final isEnough = inventory != null && availableQty >= requiredQty;

              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  isEnough ? Icons.check_circle_rounded : Icons.error_rounded,
                  color: isEnough ? Colors.green : Colors.red,
                ),
                title: Text(ingredient.ingredientName),
                subtitle: Text(
                  'Required ${Formatters.quantityWithUnit(requiredQty, ingredient.unit)} - Available ${Formatters.quantityWithUnit(availableQty, inventory?.unit ?? ingredient.unit)}',
                ),
                trailing: Text(Formatters.currency(cost)),
              );
            }),
            const Divider(height: 28),
            _CostRow(label: 'Ingredient Cost', value: preview.ingredientCost),
            _CostRow(label: 'Preparation Cost', value: preview.preparationCost),
            _CostRow(label: 'Actual Food Cost', value: preview.actualFoodCost),
            _CostRow(label: 'Current Selling Price', value: menuItem.sellingPrice),
            _CostRow(label: 'Estimated Profit', value: estimatedProfit),
          ],
        ),
      ),
    );
  }
}

class _CostRow extends StatelessWidget {
  final String label;
  final double value;

  const _CostRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            Formatters.currency(value),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
