import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/supplier_model.dart';
import '../../providers/supplier_provider.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import 'add_edit_supplier_dialog.dart';

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({super.key});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleDeleteSupplier(SupplierModel supplier) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Supplier',
      content:
          'Are you sure you want to delete supplier "${supplier.name}"? This action cannot be undone.',
      confirmText: 'Delete Supplier',
      isDanger: true,
    );

    if (confirmed == true && mounted) {
      final provider = Provider.of<SupplierProvider>(context, listen: false);
      final success = await provider.deleteSupplier(supplier.id);
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Supplier "${supplier.name}" deleted successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.errorMessage ?? 'Failed to delete supplier.',
            ),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final supplierProvider = Provider.of<SupplierProvider>(context);
    final suppliers = supplierProvider.filteredSuppliers;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  supplierProvider.setSearchQuery(value);
                },
                decoration: InputDecoration(
                  hintText:
                      'Search suppliers by name, phone, GST, or address...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            supplierProvider.setSearchQuery('');
                          },
                        )
                      : null,
                ),
              ),
            ),

            // Suppliers List
            Expanded(
              child: suppliers.isEmpty
                  ? EmptyStateWidget(
                      title: 'No Suppliers Found',
                      message:
                          'No supplier profiles match your search criteria.',
                      icon: Icons.people_outline_rounded,
                      buttonText: 'Add Supplier',
                      onButtonPressed: () {
                        AddEditSupplierDialog.show(context);
                      },
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      itemCount: suppliers.length,
                      itemBuilder: (context, index) {
                        final supplier = suppliers[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppColors.secondary
                                          .withValues(alpha: 0.15),
                                      child: const Icon(
                                        Icons.business_rounded,
                                        color: AppColors.secondary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            supplier.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (supplier.gstNumber != null &&
                                              supplier.gstNumber!.isNotEmpty)
                                            Text(
                                              'GST: ${supplier.gstNumber}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color:
                                                    theme.colorScheme.secondary,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 20,
                                      ),
                                      tooltip: 'Edit Supplier',
                                      onPressed: () {
                                        AddEditSupplierDialog.show(
                                          context,
                                          supplier: supplier,
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 20,
                                        color: AppColors.danger,
                                      ),
                                      tooltip: 'Delete Supplier',
                                      onPressed: () =>
                                          _handleDeleteSupplier(supplier),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.phone_outlined,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      supplier.phone,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    const Icon(
                                      Icons.email_outlined,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        supplier.email,
                                        style: const TextStyle(fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        supplier.address,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              theme.textTheme.bodySmall?.color,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          AddEditSupplierDialog.show(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Supplier'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
