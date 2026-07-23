class SaleModel {
  final String id;
  final String menuItemId;
  final String menuItemName;
  final double quantity;
  final double unitPrice;
  final double totalAmount;
  final String paymentMethod;
  final DateTime soldAt;
  final String soldBy;

  const SaleModel({
    required this.id,
    required this.menuItemId,
    required this.menuItemName,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.paymentMethod,
    required this.soldAt,
    required this.soldBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'menuItemId': menuItemId,
      'menuItemName': menuItemName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'soldAt': soldAt.toIso8601String(),
      'soldBy': soldBy,
    };
  }

  factory SaleModel.fromMap(Map<String, dynamic> map, String docId) {
    return SaleModel(
      id: docId,
      menuItemId: map['menuItemId'] ?? '',
      menuItemName: map['menuItemName'] ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['paymentMethod'] ?? 'Cash',
      soldAt: _parseDate(map['soldAt']),
      soldBy: map['soldBy'] ?? '',
    );
  }
}

DateTime _parseDate(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  final seconds = value.seconds;
  if (seconds is int) {
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  }
  return DateTime.tryParse(value.toString()) ?? DateTime.now();
}
