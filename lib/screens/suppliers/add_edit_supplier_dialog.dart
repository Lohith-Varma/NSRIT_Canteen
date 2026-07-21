import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/supplier_model.dart';
import '../../providers/supplier_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';

class AddEditSupplierDialog extends StatefulWidget {
  final SupplierModel? supplier;

  const AddEditSupplierDialog({super.key, this.supplier});

  static Future<void> show(BuildContext context, {SupplierModel? supplier}) {
    return showDialog(
      context: context,
      builder: (context) => AddEditSupplierDialog(supplier: supplier),
    );
  }

  @override
  State<AddEditSupplierDialog> createState() => _AddEditSupplierDialogState();
}

class _AddEditSupplierDialogState extends State<AddEditSupplierDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _gstController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.supplier?.name ?? '');
    _phoneController = TextEditingController(text: widget.supplier?.phone ?? '');
    _emailController = TextEditingController(text: widget.supplier?.email ?? '');
    _addressController = TextEditingController(text: widget.supplier?.address ?? '');
    _gstController = TextEditingController(text: widget.supplier?.gstNumber ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final provider = Provider.of<SupplierProvider>(context, listen: false);

    bool success = false;
    if (widget.supplier == null) {
      final newSupplier = SupplierModel(
        id: '',
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        gstNumber: _gstController.text.trim().isEmpty ? null : _gstController.text.trim(),
        createdAt: DateTime.now(),
      );
      success = await provider.addSupplier(newSupplier);
    } else {
      final updatedSupplier = widget.supplier!.copyWith(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        gstNumber: _gstController.text.trim().isEmpty ? null : _gstController.text.trim(),
      );
      success = await provider.updateSupplier(updatedSupplier);
    }

    if (!mounted) return;
    setState(() {
      _isSaving = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.supplier == null
                ? 'Supplier "${_nameController.text}" added successfully!'
                : 'Supplier "${_nameController.text}" updated successfully!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to save supplier.'),
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
        constraints: const BoxConstraints(maxWidth: 480),
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
                        widget.supplier == null ? 'Add Supplier Profile' : 'Edit Supplier Profile',
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
                    label: 'Supplier / Business Name',
                    hint: 'e.g. Vizag Fresh Agro Traders',
                    controller: _nameController,
                    validator: (v) => Validators.validateRequired(v, 'Supplier Name'),
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    label: 'Phone Number',
                    hint: 'e.g. +91 9876543210',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    validator: Validators.validatePhone,
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    label: 'Email Address',
                    hint: 'e.g. sales@vizagagro.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.validateEmail,
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    label: 'Business Address',
                    hint: 'Plot / Shop number, Market area, City',
                    controller: _addressController,
                    maxLines: 2,
                    validator: (v) => Validators.validateRequired(v, 'Address'),
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    label: 'GST Number (Optional)',
                    hint: 'e.g. 37AAAAA0000A1Z5',
                    controller: _gstController,
                  ),
                  const SizedBox(height: 24),

                  PrimaryButton(
                    text: widget.supplier == null ? 'Create Supplier' : 'Save Changes',
                    isLoading: _isSaving,
                    icon: Icons.check_rounded,
                    backgroundColor: AppColors.secondary,
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
