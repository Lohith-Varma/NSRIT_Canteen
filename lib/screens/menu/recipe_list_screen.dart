import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/recipe_model.dart';
import '../../providers/kitchen_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';

class RecipeListScreen extends StatelessWidget {
  const RecipeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<KitchenProvider>(context);
    final recipes = provider.filteredRecipes;

    return Scaffold(
      appBar: AppBar(title: const Text('Recipe Management')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBar(
              hintText: 'Search recipes or ingredients',
              leading: const Icon(Icons.search_rounded),
              onChanged: provider.setRecipeSearchQuery,
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : recipes.isEmpty
                    ? const EmptyStateWidget(
                        title: 'No Recipes Found',
                        message: 'Try a different recipe search.',
                        icon: Icons.menu_book_outlined,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: recipes.length,
                        itemBuilder: (context, index) {
                          final recipe = recipes[index];
                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.menu_book_rounded),
                              ),
                              title: Text(
                                recipe.menuItemName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                '${recipe.ingredients.length} ingredients - prep ${Formatters.currency(recipe.preparationCostPerUnit)} per unit',
                              ),
                              trailing: IconButton(
                                tooltip: 'Edit Recipe',
                                icon: const Icon(Icons.edit_rounded),
                                onPressed: () => _showRecipeEditor(context, recipe),
                              ),
                              onTap: () => _showRecipeEditor(context, recipe),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRecipeEditor(BuildContext context, RecipeModel recipe) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _RecipeEditDialog(recipe: recipe),
    );
  }
}

class _RecipeEditDialog extends StatefulWidget {
  final RecipeModel recipe;

  const _RecipeEditDialog({
    required this.recipe,
  });

  @override
  State<_RecipeEditDialog> createState() => _RecipeEditDialogState();
}

class _RecipeEditDialogState extends State<_RecipeEditDialog> {
  late final TextEditingController _prepCostController;
  late List<_IngredientControllers> _ingredientControllers;

  @override
  void initState() {
    super.initState();
    _prepCostController = TextEditingController(
      text: Formatters.number(widget.recipe.preparationCostPerUnit),
    );
    _ingredientControllers = widget.recipe.ingredients
        .map((ingredient) => _IngredientControllers.fromIngredient(ingredient))
        .toList();
  }

  @override
  void dispose() {
    _prepCostController.dispose();
    for (final controllers in _ingredientControllers) {
      controllers.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final ingredients = _ingredientControllers
        .map((controllers) => controllers.toIngredient())
        .where((ingredient) =>
            ingredient.ingredientName.trim().isNotEmpty && ingredient.quantity > 0)
        .toList();
    if (ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one valid ingredient.')),
      );
      return;
    }

    final updatedRecipe = widget.recipe.copyWith(
      ingredients: ingredients,
      preparationCostPerUnit: double.tryParse(_prepCostController.text) ?? 0,
      updatedAt: DateTime.now(),
    );
    final provider = Provider.of<KitchenProvider>(context, listen: false);
    final success = await provider.updateRecipe(updatedRecipe);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Recipe updated.' : provider.errorMessage ?? 'Update failed.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.recipe.menuItemName}'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _prepCostController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Preparation Cost Per Unit'),
              ),
              const SizedBox(height: 16),
              ..._ingredientControllers.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: entry.value.nameController,
                          decoration: const InputDecoration(labelText: 'Ingredient'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: entry.value.quantityController,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Qty'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: entry.value.unitController,
                          decoration: const InputDecoration(labelText: 'Unit'),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove',
                        icon: const Icon(Icons.delete_outline_rounded),
                        onPressed: () {
                          setState(() {
                            final removed = _ingredientControllers.removeAt(entry.key);
                            removed.dispose();
                          });
                        },
                      ),
                    ],
                  ),
                );
              }),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _ingredientControllers.add(_IngredientControllers.empty());
                    });
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Ingredient'),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save Recipe'),
        ),
      ],
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
      quantityController: TextEditingController(text: Formatters.number(ingredient.quantity)),
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
      unit: unitController.text.trim().isEmpty ? 'kg' : unitController.text.trim(),
    );
  }

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    unitController.dispose();
  }
}
