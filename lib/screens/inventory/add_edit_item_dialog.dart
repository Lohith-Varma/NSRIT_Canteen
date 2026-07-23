import 'package:flutter/material.dart';
import '../../models/inventory_item.dart';
import 'add_inventory_screen.dart';
import 'edit_inventory_screen.dart';

class AddEditItemDialog {
  static Future<void> show(
    BuildContext context, {
    InventoryItem? item,
    String? initialCategory,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => item == null
            ? AddInventoryScreen(initialCategory: initialCategory)
            : EditInventoryScreen(item: item),
      ),
    );
  }
}
