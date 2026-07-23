import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/kitchen_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';

class StockMovementScreen extends StatelessWidget {
  const StockMovementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<KitchenProvider>(context);
    final movements = provider.stockMovements;

    return RefreshIndicator(
      onRefresh: provider.loadKitchenData,
      child: movements.isEmpty
          ? const EmptyStateWidget(
              title: 'No Stock Movements',
              message: 'Purchases, preparation, sales, and adjustments will be listed here.',
              icon: Icons.swap_vert_rounded,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: movements.length,
              itemBuilder: (context, index) {
                final movement = movements[index];
                final isIn = movement.quantity >= 0;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: (isIn ? Colors.green : Colors.orange)
                          .withValues(alpha: 0.16),
                      child: Icon(
                        isIn ? Icons.south_west_rounded : Icons.north_east_rounded,
                        color: isIn ? Colors.green : Colors.orange,
                      ),
                    ),
                    title: Text(
                      '${movement.action} - ${movement.itemName}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${Formatters.formatDateTime(movement.dateTime)} - Ref: ${movement.reference} - User: ${movement.user}',
                    ),
                    trailing: Text(
                      Formatters.quantityWithUnit(movement.quantity, movement.unit),
                      style: TextStyle(
                        color: isIn ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
