import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/menu_item_model.dart';
import '../../models/recipe_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/kitchen_provider.dart';
import '../../services/kitchen_service.dart';
import '../../utils/formatters.dart';

class MenuItemDetailScreen extends StatefulWidget {
  final MenuItemModel menuItem;

  const MenuItemDetailScreen({super.key, required this.menuItem});

  @override
  State<MenuItemDetailScreen> createState() => _MenuItemDetailScreenState();
}

class _MenuItemDetailScreenState extends State<MenuItemDetailScreen> {
  final List<_IngredientControllers> _ingredientControllers = [];
  PreparationPreview? _preview;
  bool _isPreviewLoading = false;
  String? _loadedRecipeId;

  @override
  void dispose() {
    for (final controllers in _ingredientControllers) {
      controllers.dispose();
    }
    super.dispose();
  }

  void _syncRecipeControllers(RecipeModel? recipe) {
    if (recipe == null || _loadedRecipeId == recipe.id) return;
    for (final controllers in _ingredientControllers) {
      controllers.dispose();
    }
    _ingredientControllers
      ..clear()
      ..addAll(recipe.ingredients.map(_IngredientControllers.fromIngredient));
    _loadedRecipeId = recipe.id;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPreview());
  }

  Map<String, double> _ingredientQuantities() {
    return {
      for (final controllers in _ingredientControllers)
        if (controllers.nameController.text.trim().isNotEmpty)
          controllers.nameController.text.trim():
              double.tryParse(controllers.quantityController.text.trim()) ?? 0,
    };
  }

  Future<void> _loadPreview() async {
    if (_ingredientControllers.isEmpty) return;
    setState(() {
      _isPreviewLoading = true;
    });
    try {
      final provider = Provider.of<KitchenProvider>(context, listen: false);
      final preview = await provider.buildPreparationPreview(
        menuItem: widget.menuItem,
        ingredientQuantities: _ingredientQuantities(),
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

  Future<void> _saveRecipe(RecipeModel recipe) async {
    final ingredients = _ingredientControllers
        .map((controllers) => controllers.toIngredient())
        .where(
          (ingredient) =>
              ingredient.ingredientName.trim().isNotEmpty &&
              ingredient.quantity > 0,
        )
        .toList();
    if (ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one valid ingredient.')),
      );
      return;
    }

    final provider = Provider.of<KitchenProvider>(context, listen: false);
    final success = await provider.updateRecipe(
      recipe.copyWith(ingredients: ingredients, updatedAt: DateTime.now()),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Recipe updated.'
              : provider.errorMessage ?? 'Recipe update failed.',
        ),
      ),
    );
    if (success) {
      _loadedRecipeId = null;
      _syncRecipeControllers(provider.recipeForMenuItem(widget.menuItem.id));
      await _loadPreview();
    }
  }

  Future<void> _confirmPreparation() async {
    final kitchenProvider = Provider.of<KitchenProvider>(
      context,
      listen: false,
    );
    final inventoryProvider = Provider.of<InventoryProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user =
        authProvider.user?.displayName ??
        authProvider.user?.email ??
        'Kitchen User';

    final success = await kitchenProvider.prepareMenuItem(
      menuItem: widget.menuItem,
      ingredientQuantities: _ingredientQuantities(),
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
    _syncRecipeControllers(recipe);
    final available = kitchenProvider.isMenuItemAvailable(
      widget.menuItem,
      inventoryProvider.items,
    );
    final readyQuantity = kitchenProvider.preparedQuantityForMenuItem(
      widget.menuItem.id,
    );
    final ingredientCost = _preview?.ingredientCost ?? 0;
    final estimatedProfit = widget.menuItem.sellingPrice - ingredientCost;

    return Scaffold(
      appBar: AppBar(title: Text('Prepare ${widget.menuItem.name}')),
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
                errorBuilder: (context, error, stackTrace) => const ColoredBox(
                  color: Colors.black12,
                  child: Center(
                    child: Icon(Icons.restaurant_rounded, size: 56),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SummaryCard(
            menuItem: widget.menuItem,
            ingredientCost: ingredientCost,
            estimatedProfit: estimatedProfit,
            readyQuantity: readyQuantity,
            available: available,
          ),
          const SizedBox(height: 16),
          if (recipe == null)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Recipe is not available for this menu item.'),
              ),
            )
          else
            _IngredientEditor(
              controllers: _ingredientControllers,
              preview: _preview,
              onChanged: _loadPreview,
              onAdd: () {
                setState(() {
                  _ingredientControllers.add(_IngredientControllers.empty());
                  _preview = null;
                });
              },
              onRemove: (index) {
                setState(() {
                  final removed = _ingredientControllers.removeAt(index);
                  removed.dispose();
                  _preview = null;
                });
                _loadPreview();
              },
              onSaveRecipe: () => _saveRecipe(recipe),
              isLoading: _isPreviewLoading,
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed:
                _preview?.canPrepare == true && !kitchenProvider.isLoading
                ? _confirmPreparation
                : null,
            icon: kitchenProvider.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.soup_kitchen_rounded),
            label: const Text('Prepare Food'),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final MenuItemModel menuItem;
  final double ingredientCost;
  final double estimatedProfit;
  final double readyQuantity;
  final bool available;

  const _SummaryCard({
    required this.menuItem,
    required this.ingredientCost,
    required this.estimatedProfit,
    required this.readyQuantity,
    required this.available,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              menuItem.name,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(menuItem.section)),
                Chip(
                  label: Text(
                    available ? 'Inventory Available' : 'Inventory Short',
                  ),
                ),
                Chip(
                  label: Text(
                    '${Formatters.number(readyQuantity)} prepared units ready',
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            _CostRow(label: 'Selling Price', value: menuItem.sellingPrice),
            _CostRow(label: 'Ingredient Cost', value: ingredientCost),
            _CostRow(label: 'Estimated Profit', value: estimatedProfit),
          ],
        ),
      ),
    );
  }
}

class _IngredientEditor extends StatelessWidget {
  final List<_IngredientControllers> controllers;
  final PreparationPreview? preview;
  final VoidCallback onChanged;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final VoidCallback onSaveRecipe;
  final bool isLoading;

  const _IngredientEditor({
    required this.controllers,
    required this.preview,
    required this.onChanged,
    required this.onAdd,
    required this.onRemove,
    required this.onSaveRecipe,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Ingredients',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ...controllers.asMap().entries.map((entry) {
              final controller = entry.value;
              final name = controller.nameController.text.trim();
              final inventory = preview?.inventoryByIngredient[name];
              final available = preview?.availableQuantityByIngredient[name];
              final required = preview?.requiredQuantityByIngredient[name] ?? 0;
              final isEnough =
                  inventory != null &&
                  available != null &&
                  available >= required &&
                  required > 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: controller.nameController,
                            decoration: const InputDecoration(
                              labelText: 'Ingredient Name',
                            ),
                            onChanged: (_) => onChanged(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: controller.quantityController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Quantity Used',
                            ),
                            onChanged: (_) => onChanged(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: controller.unitController,
                            decoration: const InputDecoration(
                              labelText: 'Unit',
                            ),
                            onChanged: (_) => onChanged(),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove Ingredient',
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: () => onRemove(entry.key),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          isEnough
                              ? Icons.check_circle_rounded
                              : Icons.error_rounded,
                          size: 18,
                          color: isEnough ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            inventory == null
                                ? 'Available Inventory: not found'
                                : 'Available Inventory: ${Formatters.quantityWithUnit(available ?? 0, inventory.unit)}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Ingredient'),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: onSaveRecipe,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Save Recipe'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CostRow extends StatelessWidget {
  final String label;
  final double value;

  const _CostRow({required this.label, required this.value});

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

class _IngredientControllers {
  final TextEditingController nameController;
  final TextEditingController quantityController;
  final TextEditingController unitController;

  _IngredientControllers({
    required this.nameController,
    required this.quantityController,
    required this.unitController,
  });

  factory _IngredientControllers.fromIngredient(RecipeIngredient ingredient) {
    return _IngredientControllers(
      nameController: TextEditingController(text: ingredient.ingredientName),
      quantityController: TextEditingController(
        text: Formatters.number(ingredient.quantity),
      ),
      unitController: TextEditingController(text: ingredient.unit),
    );
  }

  factory _IngredientControllers.empty() {
    return _IngredientControllers(
      nameController: TextEditingController(),
      quantityController: TextEditingController(),
      unitController: TextEditingController(text: 'kg'),
    );
  }

  RecipeIngredient toIngredient() {
    return RecipeIngredient(
      ingredientName: nameController.text.trim(),
      quantity: double.tryParse(quantityController.text.trim()) ?? 0,
      unit: unitController.text.trim().isEmpty
          ? 'kg'
          : unitController.text.trim(),
    );
  }

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    unitController.dispose();
  }
}
