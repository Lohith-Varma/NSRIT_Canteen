import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../models/inventory_item.dart';
import '../../models/supplier_model.dart';
import '../../models/purchase_model.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../providers/purchase_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import '../inventory/add_edit_item_dialog.dart';
import '../suppliers/add_edit_supplier_dialog.dart';

class AddPurchaseScreen extends StatefulWidget {
  final InventoryItem? preselectedItem;

  const AddPurchaseScreen({super.key, this.preselectedItem});

  @override
  State<AddPurchaseScreen> createState() => _AddPurchaseScreenState();
}

class _AddPurchaseScreenState extends State<AddPurchaseScreen> {
  final _formKey = GlobalKey<FormState>();

  InventoryItem? _selectedItem;
  SupplierModel? _selectedSupplier;

  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _invoiceController = TextEditingController(
    text: 'INV-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
  );
  final TextEditingController _remarksController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedUnit = AppConstants.units.first;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedItem != null) {
      _selectedItem = widget.preselectedItem;
      _selectedUnit = widget.preselectedItem!.unit;
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _invoiceController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  double get _totalAmount {
    final qty = double.tryParse(_quantityController.text) ?? 0.0;
    final price = double.tryParse(_priceController.text) ?? 0.0;
    return qty * price;
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _handleSavePurchase() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an inventory item.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (_selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a supplier.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final purchaseProvider = Provider.of<PurchaseProvider>(context, listen: false);
    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);

    final purchase = PurchaseModel(
      id: '',
      supplierId: _selectedSupplier!.id,
      supplierName: _selectedSupplier!.name,
      itemId: _selectedItem!.id,
      itemName: _selectedItem!.name,
      quantity: double.parse(_quantityController.text.trim()),
      unit: _selectedUnit,
      pricePerUnit: double.parse(_priceController.text.trim()),
      purchaseDate: _selectedDate,
      invoiceNumber: _invoiceController.text.trim(),
      remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
      createdAt: DateTime.now(),
    );

    final success = await purchaseProvider.recordPurchase(
      purchase: purchase,
      onInventoryUpdated: () {
        inventoryProvider.loadInventory();
      },
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Purchase recorded! Stock updated for ${_selectedItem!.name}.',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(purchaseProvider.errorMessage ?? 'Failed to record purchase.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final supplierProvider = Provider.of<SupplierProvider>(context);
    final purchaseProvider = Provider.of<PurchaseProvider>(context);

    final items = inventoryProvider.items;
    final suppliers = supplierProvider.suppliers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record New Purchase'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 550),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Banner Notice
                    Card(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Saving a purchase automatically creates a new inventory lot and increases total stock while maintaining individual price history.',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Select Inventory Item Dropdown
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Inventory Item',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        TextButton.icon(
                          onPressed: () => AddEditItemDialog.show(context),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('New Item', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedItem?.id,
                      hint: const Text('Select Item to Purchase'),
                      decoration: const InputDecoration(),
                      items: items.map((item) {
                        return DropdownMenuItem(
                          value: item.id,
                          child: Text('${item.name} (${item.category})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          final selected = items.firstWhere((i) => i.id == val);
                          setState(() {
                            _selectedItem = selected;
                            _selectedUnit = selected.unit;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Select Supplier Dropdown
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Supplier',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        TextButton.icon(
                          onPressed: () => AddEditSupplierDialog.show(context),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('New Supplier', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSupplier?.id,
                      hint: const Text('Select Vendor / Supplier'),
                      decoration: const InputDecoration(),
                      items: suppliers.map((sup) {
                        return DropdownMenuItem(
                          value: sup.id,
                          child: Text(sup.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          final selected = suppliers.firstWhere((s) => s.id == val);
                          setState(() {
                            _selectedSupplier = selected;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Quantity and Unit Row
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: CustomTextField(
                            label: 'Purchase Quantity',
                            hint: 'e.g. 50',
                            controller: _quantityController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => setState(() {}),
                            validator: (v) => Validators.validateNumber(v, 'Quantity'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Unit',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedUnit,
                                decoration: const InputDecoration(),
                                items: AppConstants.units.map((u) {
                                  return DropdownMenuItem(value: u, child: Text(u));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedUnit = val;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      label: 'Price per Unit (₹)',
                      hint: 'e.g. 55.00',
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 18),
                      onChanged: (_) => setState(() {}),
                      validator: (v) => Validators.validateNumber(v, 'Price per Unit'),
                    ),
                    const SizedBox(height: 16),

                    // Total Calculation Preview Card
                    Card(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Calculated Total Amount:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              Formatters.currency(_totalAmount),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'Invoice Number',
                            hint: 'e.g. INV-2026-042',
                            controller: _invoiceController,
                            validator: (v) => Validators.validateRequired(v, 'Invoice Number'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Purchase Date',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: _selectDate,
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                                  ),
                                  child: Text(
                                    Formatters.formatDate(_selectedDate),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      label: 'Remarks / Notes (Optional)',
                      hint: 'e.g. Bulk restock for canteen mess',
                      controller: _remarksController,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),

                    PrimaryButton(
                      text: 'Save & Post Purchase',
                      isLoading: purchaseProvider.isLoading,
                      icon: Icons.check_circle_outline_rounded,
                      onPressed: _handleSavePurchase,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
