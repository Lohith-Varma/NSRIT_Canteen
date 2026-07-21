import 'inventory_lot.dart';

class InventoryItem {
  final String id;
  final String name;
  final String category;
  final String unit;
  final double minStock;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<InventoryLot> lots;

  InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.minStock,
    required this.createdAt,
    required this.updatedAt,
    this.lots = const [],
  });

  // Calculate Total Quantity from all separate lots
  double get totalStock {
    if (lots.isEmpty) return 0.0;
    return lots.fold(0.0, (sum, lot) => sum + lot.quantity);
  }

  // Weighted Average Purchase Cost: Sum(Lot Qty * Lot Price) / Total Qty
  double get averageCost {
    if (lots.isEmpty || totalStock == 0) return 0.0;
    final totalCost = lots.fold(0.0, (sum, lot) => sum + (lot.quantity * lot.unitPrice));
    return totalCost / totalStock;
  }

  // Current Inventory Value
  double get totalValue => totalStock * averageCost;

  // Low Stock Status
  bool get isLowStock => totalStock < minStock;

  InventoryItem copyWith({
    String? id,
    String? name,
    String? category,
    String? unit,
    double? minStock,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<InventoryLot>? lots,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      minStock: minStock ?? this.minStock,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lots: lots ?? this.lots,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'unit': unit,
      'minStock': minStock,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map, String docId, {List<InventoryLot> lots = const []}) {
    return InventoryItem(
      id: docId,
      name: map['name'] ?? '',
      category: map['category'] ?? 'General',
      unit: map['unit'] ?? 'kg',
      minStock: (map['minStock'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
      lots: lots,
    );
  }
}
