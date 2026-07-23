import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _collegeController;
  late TextEditingController _canteenController;
  late TextEditingController _currencyController;
  late TextEditingController _unitsController;
  bool _lowStock = true;
  bool _sales = true;
  bool _preparation = true;

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<AdminProvider>(
      context,
      listen: false,
    ).settings;
    _collegeController = TextEditingController(text: settings.collegeName);
    _canteenController = TextEditingController(text: settings.canteenName);
    _currencyController = TextEditingController(text: settings.currency);
    _unitsController = TextEditingController(
      text: settings.measurementUnits.join(', '),
    );
    _lowStock = settings.lowStockNotifications;
    _sales = settings.salesNotifications;
    _preparation = settings.preparationNotifications;
  }

  @override
  void dispose() {
    _collegeController.dispose();
    _canteenController.dispose();
    _currencyController.dispose();
    _unitsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final settings = AppSettingsModel(
      collegeName: _collegeController.text.trim(),
      canteenName: _canteenController.text.trim(),
      currency: _currencyController.text.trim(),
      measurementUnits: _unitsController.text
          .split(',')
          .map((unit) => unit.trim())
          .where((unit) => unit.isNotEmpty)
          .toList(),
      darkMode: themeProvider.isDarkMode,
      lowStockNotifications: _lowStock,
      salesNotifications: _sales,
      preparationNotifications: _preparation,
      appVersion: adminProvider.settings.appVersion,
    );
    final success = await adminProvider.saveSettings(settings);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Settings saved.'
              : adminProvider.errorMessage ?? 'Save failed.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final settings = Provider.of<AdminProvider>(context).settings;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _collegeController,
                  decoration: const InputDecoration(labelText: 'College Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _canteenController,
                  decoration: const InputDecoration(labelText: 'Canteen Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _currencyController,
                  decoration: const InputDecoration(labelText: 'Currency'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _unitsController,
                  decoration: const InputDecoration(
                    labelText: 'Measurement Units',
                  ),
                ),
                SwitchListTile(
                  value: themeProvider.isDarkMode,
                  title: const Text('Dark Mode'),
                  secondary: const Icon(Icons.dark_mode_rounded),
                  onChanged: themeProvider.toggleTheme,
                ),
                SwitchListTile(
                  value: _lowStock,
                  title: const Text('Low Stock Notifications'),
                  onChanged: (value) => setState(() => _lowStock = value),
                ),
                SwitchListTile(
                  value: _sales,
                  title: const Text('Sales Notifications'),
                  onChanged: (value) => setState(() => _sales = value),
                ),
                SwitchListTile(
                  value: _preparation,
                  title: const Text('Preparation Notifications'),
                  onChanged: (value) => setState(() => _preparation = value),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Save Settings'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.backup_rounded),
            title: const Text('Backup & Restore'),
            subtitle: const Text(
              'Placeholder for future cloud backup integration.',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Backup & Restore will be available soon.'),
                ),
              );
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: Text('Application Version ${settings.appVersion}'),
            subtitle: Text('${settings.collegeName} - ${settings.canteenName}'),
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.restaurant_rounded),
            title: Text('About'),
            subtitle: Text('Smart Canteen Inventory Management System'),
          ),
        ),
      ],
    );
  }
}
