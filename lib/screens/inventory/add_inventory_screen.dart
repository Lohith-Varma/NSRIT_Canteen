import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../models/inventory_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';

class AddInventoryScreen extends StatefulWidget {
  final InventoryItem? item;
  final String? initialCategory;

  const AddInventoryScreen({
    super.key,
    this.item,
    this.initialCategory,
  });

  bool get isEditing => item != null;

  @override
  State<AddInventoryScreen> createState() => _AddInventoryScreenState();
}

class _AddInventoryScreenState extends State<AddInventoryScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _minimumStockController;
  late final TextEditingController _maximumStockController;
  late final TextEditingController _supplierController;
  late final TextEditingController _purchasePriceController;
  late final TextEditingController _sellingPriceController;
  late final TextEditingController _storageLocationController;
  late final TextEditingController _notesController;
  late String _selectedCategory;
  late String _selectedUnit;
  DateTime? _expiryDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?.itemName ?? '');
    _quantityController = TextEditingController(text: _initialNumber(item?.quantity));
    _minimumStockController = TextEditingController(text: _initialNumber(item?.minimumStock, fallback: '10'));
    _maximumStockController = TextEditingController(text: _initialNumber(item?.maximumStock));
    _supplierController = TextEditingController(text: item?.supplier ?? '');
    _purchasePriceController = TextEditingController(text: _initialNumber(item?.purchasePrice));
    _sellingPriceController = TextEditingController(text: _initialNumber(item?.sellingPrice));
    _storageLocationController = TextEditingController(text: item?.storageLocation ?? '');
    _notesController = TextEditingController(text: item?.notes ?? '');
    _selectedCategory = item?.category ?? widget.initialCategory ?? AppConstants.categories.first;
    _selectedUnit = item?.unit ?? AppConstants.units.first;
    _expiryDate = item?.expiryDate;
  }

  String _initialNumber(double? value, {String fallback = '0'}) {
    if (value == null) return fallback;
    if (value == 0) return fallback == '0' ? '0' : fallback;
    return value.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _minimumStockController.dispose();
    _maximumStockController.dispose();
    _supplierController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _storageLocationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _expiryDate = pickedDate;
      });
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final provider = context.read<InventoryProvider>();
    final authProvider = context.read<AuthProvider>();
    final now = DateTime.now();
    final item = widget.item;
    final createdBy = item?.createdBy.isNotEmpty == true
        ? item!.createdBy
        : authProvider.user?.uid ?? authProvider.user?.email ?? 'system';

    final inventoryItem = InventoryItem(
      id: item?.id ?? '',
      itemName: _nameController.text.trim(),
      category: _selectedCategory,
      quantity: double.parse(_quantityController.text.trim()),
      unit: _selectedUnit,
      minimumStock: double.parse(_minimumStockController.text.trim()),
      maximumStock: double.parse(_maximumStockController.text.trim()),
      supplier: _supplierController.text.trim(),
      purchasePrice: double.parse(_purchasePriceController.text.trim()),
      sellingPrice: double.parse(_sellingPriceController.text.trim()),
      storageLocation: _storageLocationController.text.trim(),
      expiryDate: _expiryDate,
      notes: _notesController.text.trim(),
      createdAt: item?.createdAt ?? now,
      updatedAt: now,
      createdBy: createdBy,
      status: 'active',
      isDeleted: false,
      lots: item?.lots ?? const [],
    );

    final success = widget.isEditing
        ? await provider.updateItem(inventoryItem)
        : await provider.addItem(inventoryItem);

    if (!mounted) return;
    setState(() {
      _isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '${inventoryItem.itemName} ${widget.isEditing ? 'updated' : 'added'} successfully.'
              : provider.errorMessage ?? 'Failed to save inventory item.',
        ),
        backgroundColor: success ? AppColors.success : AppColors.danger,
      ),
    );

    if (success) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = context.watch<InventoryProvider>().categories;
    final availableCategories = {
      ...categories,
      _selectedCategory,
    }.where((category) => category.trim().isNotEmpty).toList()
      ..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Inventory' : 'Add Inventory'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionTitle(title: 'Item Details', icon: Icons.inventory_2_rounded),
              CustomTextField(
                label: 'Item Name',
                hint: 'e.g. Sona Masoori Rice',
                controller: _nameController,
                validator: (value) => Validators.validateRequired(value, 'Item name'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_rounded),
                ),
                items: availableCategories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Quantity',
                      controller: _quantityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) => Validators.validateNumber(value, 'Quantity', allowZero: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedUnit,
                      decoration: const InputDecoration(labelText: 'Unit'),
                      items: AppConstants.units.map((unit) {
                        return DropdownMenuItem(value: unit, child: Text(unit));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedUnit = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Minimum Stock',
                      controller: _minimumStockController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) => Validators.validateNumber(value, 'Minimum stock', allowZero: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      label: 'Maximum Stock',
                      controller: _maximumStockController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) => Validators.validateNumber(value, 'Maximum stock', allowZero: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _SectionTitle(title: 'Pricing & Supplier', icon: Icons.payments_rounded),
              CustomTextField(
                label: 'Supplier',
                hint: 'Supplier name',
                controller: _supplierController,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Purchase Price',
                      controller: _purchasePriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) => Validators.validateNumber(value, 'Purchase price', allowZero: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      label: 'Selling Price',
                      controller: _sellingPriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) => Validators.validateNumber(value, 'Selling price', allowZero: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _SectionTitle(title: 'Storage', icon: Icons.store_mall_directory_rounded),
              CustomTextField(
                label: 'Storage Location',
                hint: 'e.g. Dry Store Rack A',
                controller: _storageLocationController,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_rounded),
                title: const Text('Expiry Date'),
                subtitle: Text(_expiryDate == null ? 'Not set' : Formatters.formatDate(_expiryDate!)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_expiryDate != null)
                      IconButton(
                        tooltip: 'Clear expiry date',
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          setState(() {
                            _expiryDate = null;
                          });
                        },
                      ),
                    IconButton(
                      tooltip: 'Pick expiry date',
                      icon: const Icon(Icons.calendar_month_rounded),
                      onPressed: _pickExpiryDate,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Notes',
                hint: 'Optional handling or reorder notes',
                controller: _notesController,
                maxLines: 3,
              ),
              const SizedBox(height: 28),
              Text(
                'Status will be calculated from the current stock levels on the list and dashboard.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                text: widget.isEditing ? 'Save Changes' : 'Add Inventory',
                icon: widget.isEditing ? Icons.save_rounded : Icons.add_rounded,
                isLoading: _isSaving,
                onPressed: _saveItem,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
