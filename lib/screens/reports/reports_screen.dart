import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/report_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/kitchen_provider.dart';
import '../../providers/purchase_provider.dart';
import '../../providers/supplier_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  static const List<String> _reportTypes = [
    'Daily Sales',
    'Weekly Sales',
    'Monthly Sales',
    'Purchase Report',
    'Inventory Report',
    'Supplier Report',
    'Stock Movement Report',
    'Profit Report',
    'Low Stock Report',
  ];

  String _selectedReport = _reportTypes.first;
  ReportModel? _report;

  void _generateReport() {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final kitchenProvider = Provider.of<KitchenProvider>(
      context,
      listen: false,
    );
    final purchaseProvider = Provider.of<PurchaseProvider>(
      context,
      listen: false,
    );
    final inventoryProvider = Provider.of<InventoryProvider>(
      context,
      listen: false,
    );
    final supplierProvider = Provider.of<SupplierProvider>(
      context,
      listen: false,
    );

    setState(() {
      _report = adminProvider.buildReport(
        type: _selectedReport,
        sales: kitchenProvider.sales,
        purchases: purchaseProvider.purchases,
        inventory: inventoryProvider.items,
        suppliers: supplierProvider.suppliers,
        movements: kitchenProvider.stockMovements,
      );
    });
  }

  Future<void> _copyExport(String label, String content) async {
    await Clipboard.setData(ClipboardData(text: content));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label copied to clipboard.')));
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 280,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedReport,
                    decoration: const InputDecoration(labelText: 'Report Type'),
                    items: _reportTypes
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedReport = value;
                        });
                      }
                    },
                  ),
                ),
                FilledButton.icon(
                  onPressed: _generateReport,
                  icon: const Icon(Icons.analytics_rounded),
                  label: const Text('Generate'),
                ),
                if (report != null) ...[
                  OutlinedButton.icon(
                    onPressed: () => _copyExport('CSV export', report.toCsv()),
                    icon: const Icon(Icons.table_view_rounded),
                    label: const Text('CSV'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _copyExport(
                      'PDF-ready report',
                      report.toPrintableText(),
                    ),
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                    label: const Text('PDF'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showPrintableReport(report),
                    icon: const Icon(Icons.print_rounded),
                    label: const Text('Print'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _copyExport(
                      'Shareable report',
                      report.toPrintableText(),
                    ),
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Share'),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (report == null)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('Select a report type and generate a report.'),
              ),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: report.columns
                          .map((column) => DataColumn(label: Text(column)))
                          .toList(),
                      rows: report.rows
                          .take(80)
                          .map(
                            (row) => DataRow(
                              cells: row
                                  .map((cell) => DataCell(Text(cell)))
                                  .toList(),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showPrintableReport(ReportModel report) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(report.title),
          content: SizedBox(
            width: 620,
            child: SingleChildScrollView(
              child: SelectableText(report.toPrintableText()),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
