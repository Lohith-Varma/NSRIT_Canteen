import 'package:flutter_test/flutter_test.dart';
import 'package:nsrit_canteen/models/inventory_item.dart';
import 'package:nsrit_canteen/models/inventory_lot.dart';

void main() {
  group('Lot-Based Inventory Calculation Tests', () {
    test('Calculates total quantity and weighted average cost accurately', () {
      // Rice example from requirement:
      // Lot 1: 20 kg @ ₹50/kg
      // Lot 2: 30 kg @ ₹60/kg
      // Expected Total Qty = 50 kg
      // Expected Avg Cost = ((20*50) + (30*60)) / 50 = (1000 + 1800) / 50 = 2800 / 50 = 56.0

      final lots = [
        InventoryLot(
          id: 'lot_1',
          itemId: 'rice_1',
          purchaseId: 'pur_1',
          quantity: 20.0,
          unit: 'kg',
          unitPrice: 50.0,
          purchaseDate: DateTime.now(),
          supplierId: 'sup_1',
          invoiceNumber: 'INV-1',
        ),
        InventoryLot(
          id: 'lot_2',
          itemId: 'rice_1',
          purchaseId: 'pur_2',
          quantity: 30.0,
          unit: 'kg',
          unitPrice: 60.0,
          purchaseDate: DateTime.now(),
          supplierId: 'sup_1',
          invoiceNumber: 'INV-2',
        ),
      ];

      final riceItem = InventoryItem(
        id: 'rice_1',
        name: 'Sona Masoori Rice',
        category: 'Grains',
        unit: 'kg',
        minStock: 25.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lots: lots,
      );

      expect(riceItem.totalStock, equals(50.0));
      expect(riceItem.averageCost, equals(56.0));
      expect(riceItem.totalValue, equals(2800.0));
      expect(riceItem.isLowStock, isFalse);
    });

    test(
      'Correctly triggers low stock warning when total stock is below minStock',
      () {
        final lowStockItem = InventoryItem(
          id: 'milk_1',
          name: 'Whole Milk',
          category: 'Dairy',
          unit: 'litre',
          minStock: 50.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          lots: [
            InventoryLot(
              id: 'lot_m1',
              itemId: 'milk_1',
              purchaseId: 'pur_m1',
              quantity: 15.0,
              unit: 'litre',
              unitPrice: 58.0,
              purchaseDate: DateTime.now(),
              supplierId: 'sup_dairy',
              invoiceNumber: 'INV-M1',
            ),
          ],
        );

        expect(lowStockItem.totalStock, equals(15.0));
        expect(lowStockItem.isLowStock, isTrue);
      },
    );
  });
}
