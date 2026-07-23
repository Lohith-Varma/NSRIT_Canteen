import '../utils/date_parser.dart';

class PurchaseModel {
  final String id;
  final String supplierId;
  final String supplierName;
  final String itemId;
  final String itemName;
  final double quantity;
  final String unit;
  final double pricePerUnit;
  final DateTime purchaseDate;
  final String invoiceNumber;
  final String? remarks;
  final DateTime createdAt;

  PurchaseModel({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.pricePerUnit,
    required this.purchaseDate,
    required this.invoiceNumber,
    this.remarks,
    required this.createdAt,
  });

  double get totalAmount => quantity * pricePerUnit;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'itemId': itemId,
      'itemName': itemName,
      'quantity': quantity,
      'unit': unit,
      'pricePerUnit': pricePerUnit,
      'purchaseDate': purchaseDate.toIso8601String(),
      'invoiceNumber': invoiceNumber,
      'remarks': remarks,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PurchaseModel.fromMap(Map<String, dynamic> map, String docId) {
    return PurchaseModel(
      id: docId,
      supplierId: map['supplierId'] ?? '',
      supplierName: map['supplierName'] ?? '',
      itemId: map['itemId'] ?? '',
      itemName: map['itemName'] ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] ?? 'kg',
      pricePerUnit: (map['pricePerUnit'] as num?)?.toDouble() ?? 0.0,
      purchaseDate: parseModelDate(map['purchaseDate']),
      invoiceNumber: map['invoiceNumber'] ?? '',
      remarks: map['remarks'],
      createdAt: parseModelDate(map['createdAt']),
    );
  }
}
