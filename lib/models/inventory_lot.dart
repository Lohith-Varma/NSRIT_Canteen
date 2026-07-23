import '../utils/date_parser.dart';

class InventoryLot {
  final String id;
  final String itemId;
  final String purchaseId;
  final double quantity;
  final String unit;
  final double unitPrice;
  final DateTime purchaseDate;
  final String supplierId;
  final String invoiceNumber;

  InventoryLot({
    required this.id,
    required this.itemId,
    required this.purchaseId,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.purchaseDate,
    required this.supplierId,
    required this.invoiceNumber,
  });

  double get totalLotValue => quantity * unitPrice;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemId': itemId,
      'purchaseId': purchaseId,
      'quantity': quantity,
      'unit': unit,
      'unitPrice': unitPrice,
      'purchaseDate': purchaseDate.toIso8601String(),
      'supplierId': supplierId,
      'invoiceNumber': invoiceNumber,
    };
  }

  factory InventoryLot.fromMap(Map<String, dynamic> map, String docId) {
    return InventoryLot(
      id: docId,
      itemId: map['itemId'] ?? '',
      purchaseId: map['purchaseId'] ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] ?? 'kg',
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      purchaseDate: parseModelDate(map['purchaseDate']),
      supplierId: map['supplierId'] ?? '',
      invoiceNumber: map['invoiceNumber'] ?? '',
    );
  }
}
