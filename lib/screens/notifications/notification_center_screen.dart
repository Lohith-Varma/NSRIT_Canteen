import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/kitchen_provider.dart';
import '../../providers/purchase_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';

class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final purchaseProvider = Provider.of<PurchaseProvider>(context);
    final kitchenProvider = Provider.of<KitchenProvider>(context);
    final notifications = adminProvider.notifications;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await adminProvider.refreshGeneratedNotifications(
            inventory: inventoryProvider.items,
            purchases: purchaseProvider.purchases,
            sales: kitchenProvider.sales,
            preparedFood: kitchenProvider.preparedFood,
          );
        },
        child: notifications.isEmpty
            ? const EmptyStateWidget(
                title: 'No Notifications',
                message: 'Operational alerts will appear here automatically.',
                icon: Icons.notifications_none_rounded,
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: notification.isRead
                            ? Colors.grey.withValues(alpha: 0.16)
                            : Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.14),
                        child: Icon(_iconForType(notification.type)),
                      ),
                      title: Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: notification.isRead
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${notification.description}\n${Formatters.formatDateTime(notification.timestamp)}',
                      ),
                      isThreeLine: true,
                      trailing: notification.isRead
                          ? const Icon(Icons.done_rounded)
                          : IconButton(
                              tooltip: 'Mark Read',
                              icon: const Icon(Icons.mark_email_read_rounded),
                              onPressed: () => adminProvider
                                  .markNotificationRead(notification.id),
                            ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await adminProvider.refreshGeneratedNotifications(
            inventory: inventoryProvider.items,
            purchases: purchaseProvider.purchases,
            sales: kitchenProvider.sales,
            preparedFood: kitchenProvider.preparedFood,
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notifications refreshed.')),
            );
          }
        },
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Refresh'),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'Low Stock':
        return Icons.warning_amber_rounded;
      case 'Out of Stock':
        return Icons.remove_shopping_cart_rounded;
      case 'Expiring Inventory':
        return Icons.event_busy_rounded;
      case 'New Purchase':
        return Icons.add_shopping_cart_rounded;
      case 'Successful Sale':
        return Icons.point_of_sale_rounded;
      case 'Preparation Completed':
        return Icons.soup_kitchen_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }
}
