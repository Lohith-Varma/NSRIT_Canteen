import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../models/inventory_item.dart';
import '../../providers/inventory_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';

class AddEditItemDialog extends StatefulWidget {
  final InventoryItem? item;
  final String? initialCategory;

  const AddEditItemDialog({super.key, this.item, this.initialCategory});

  static Future<void> show(BuildContext context, {InventoryItem? item, String? initialCategory}) {
    return showDialog(
      context: context,
      builder: (context) => AddEditItemDialog(item: item, initialCategory: initialCategory),
    );
  }

  @override
  State<AddEditItemDialog> createState() => _AddEditItemDialogState();
}

class _AddEditItemDialogState extends State<AddEditItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _minStockController;
  late String _selectedCategory;
  late String _selectedUnit;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _minStockController = TextEditingController(
      text: widget.item != null ? widget.item!.minStock.toString() : '10',
    );
    _selectedCategory = widget.item?.category ?? widget.initialCategory ?? AppConstants.categories.first;
    _selectedUnit = widget.item?.unit ?? AppConstants.units.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final provider = Provider.of<InventoryProvider>(context, listen: false);
    final minStock = double.parse(_minStockController.text.trim());

    bool success = false;
    if (widget.item == null) {
      final newItem = InventoryItem(
        id: '',
        name: _nameController.text.trim(),
        category: _selectedCategory,
        unit: _selectedUnit,
        minStock: minStock,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      success = await provider.addItem(newItem);
    } else {
      final updatedItem = widget.item!.copyWith(
        name: _nameController.text.trim(),
        category: _selectedCategory,
        unit: _selectedUnit,
        minStock: minStock,
        updatedAt: DateTime.now(),
      );
      success = await provider.updateItem(updatedItem);
    }

    if (!mounted) return;
    setState(() {
      _isSaving = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.item == null
                ? 'Item "${_nameController.text}" added successfully!'
                : 'Item "${_nameController.text}" updated successfully!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to save item.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.item == null ? 'Add Inventory Item' : 'Edit Inventory Item',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    label: 'Item Name',
                    hint: 'e.g. Sona Masoori Rice',
                    controller: _nameController,
                    validator: (v) => Validators.validateRequired(v, 'Item Name'),
                  ),
                  const SizedBox(height: 16),

                  // Category Dropdown
                  const Text(
                    'Category',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(),
                    items: AppConstants.categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Row(
                          children: [
                            Icon(
                              AppConstants.getCategoryIcon(cat),
                              size: 18,
                              color: AppColors.getCategoryColor(cat),
                            ),
                            const SizedBox(width: 8),
                            Text(cat),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedCategory = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Unit Dropdown
                  const Text(
                    'Unit of Measurement',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedUnit,
                    decoration: const InputDecoration(),
                    items: AppConstants.units.map((unit) {
                      return DropdownMenuItem(
                        value: unit,
                        child: Text(unit),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedUnit = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    label: 'Minimum Stock Level',
                    hint: 'e.g. 20',
                    controller: _minStockController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => Validators.validateNumber(v, 'Minimum Stock', allowZero: true),
                  ),
                  const SizedBox(height: 24),

                  PrimaryButton(
                    text: widget.item == null ? 'Create Item' : 'Save Changes',
                    isLoading: _isSaving,
                    icon: Icons.check_rounded,
                    onPressed: _handleSave,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
