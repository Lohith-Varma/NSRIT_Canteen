import '../utils/date_parser.dart';

class StockMovementModel {
  final String id;
  final DateTime dateTime;
  final String action;
  final String reference;
  final String itemName;
  final double quantity;
  final String unit;
  final String user;

  const StockMovementModel({
    required this.id,
    required this.dateTime,
    required this.action,
    required this.reference,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.user,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dateTime': dateTime.toIso8601String(),
      'action': action,
      'reference': reference,
      'itemName': itemName,
      'quantity': quantity,
      'unit': unit,
      'user': user,
    };
  }

  factory StockMovementModel.fromMap(Map<String, dynamic> map, String docId) {
    return StockMovementModel(
      id: docId,
      dateTime: parseModelDate(map['dateTime'] ?? map['createdAt']),
      action: map['action'] ?? '',
      reference: map['reference'] ?? '',
      itemName: map['itemName'] ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] ?? '',
      user: map['user'] ?? '',
    );
  }
}
