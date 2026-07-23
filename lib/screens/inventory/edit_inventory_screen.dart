import 'package:flutter/material.dart';

import '../../models/inventory_item.dart';
import 'add_inventory_screen.dart';

class EditInventoryScreen extends StatelessWidget {
  final InventoryItem item;

  const EditInventoryScreen({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return AddInventoryScreen(item: item);
  }
}
