import 'inventory_lot.dart';
import '../utils/date_parser.dart';

class InventoryItem {
  final String id;
  final String itemName;
  final String category;
  final double quantity;
  final String unit;
  final double minimumStock;
  final double maximumStock;
  final String supplier;
  final double purchasePrice;
  final double sellingPrice;
  final String storageLocation;
  final String imageUrl;
  final DateTime? expiryDate;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String status;
  final bool isDeleted;
  final List<InventoryLot> lots;

  InventoryItem({
    required this.id,
    String? itemName,
    String? name,
    required this.category,
    double? quantity,
    required this.unit,
    double? minimumStock,
    double? minStock,
    this.maximumStock = 0,
    this.supplier = '',
    this.purchasePrice = 0,
    this.sellingPrice = 0,
    this.storageLocation = '',
    this.imageUrl = '',
    this.expiryDate,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
    this.createdBy = '',
    this.status = 'active',
    this.isDeleted = false,
    this.lots = const [],
  }) : itemName = itemName ?? name ?? '',
       quantity = quantity ?? 0,
       minimumStock = minimumStock ?? minStock ?? 0;

  String get name => itemName;

  double get minStock => minimumStock;

  double get totalStock {
    if (lots.isEmpty) return quantity;
    return lots.fold(0.0, (sum, lot) => sum + lot.quantity);
  }

  double get averageCost {
    if (purchasePrice > 0 && lots.isEmpty) return purchasePrice;
    if (lots.isEmpty || totalStock == 0) return 0.0;
    final totalCost = lots.fold(
      0.0,
      (sum, lot) => sum + (lot.quantity * lot.unitPrice),
    );
    return totalCost / totalStock;
  }

  double get totalValue => totalStock * averageCost;

  bool get isLowStock => totalStock > 0 && totalStock <= minimumStock;

  bool get isOutOfStock => totalStock <= 0;

  bool get isExpired {
    if (expiryDate == null) return false;
    final today = DateTime.now();
    final expiry = DateTime(
      expiryDate!.year,
      expiryDate!.month,
      expiryDate!.day,
    );
    final current = DateTime(today.year, today.month, today.day);
    return expiry.isBefore(current);
  }

  InventoryItem copyWith({
    String? id,
    String? itemName,
    String? name,
    String? category,
    double? quantity,
    String? unit,
    double? minimumStock,
    double? minStock,
    double? maximumStock,
    String? supplier,
    double? purchasePrice,
    double? sellingPrice,
    String? storageLocation,
    String? imageUrl,
    DateTime? expiryDate,
    bool clearExpiryDate = false,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? status,
    bool? isDeleted,
    List<InventoryLot>? lots,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      itemName: itemName ?? name ?? this.itemName,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      minimumStock: minimumStock ?? minStock ?? this.minimumStock,
      maximumStock: maximumStock ?? this.maximumStock,
      supplier: supplier ?? this.supplier,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      storageLocation: storageLocation ?? this.storageLocation,
      imageUrl: imageUrl ?? this.imageUrl,
      expiryDate: clearExpiryDate ? null : expiryDate ?? this.expiryDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      status: status ?? this.status,
      isDeleted: isDeleted ?? this.isDeleted,
      lots: lots ?? this.lots,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemName': itemName,
      'name': itemName,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'minimumStock': minimumStock,
      'minStock': minimumStock,
      'maximumStock': maximumStock,
      'supplier': supplier,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'storageLocation': storageLocation,
      'imageUrl': imageUrl,
      'expiryDate': expiryDate?.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
      'status': status,
      'isDeleted': isDeleted,
    };
  }

  factory InventoryItem.fromMap(
    Map<String, dynamic> map,
    String docId, {
    List<InventoryLot> lots = const [],
  }) {
    return InventoryItem(
      id: docId,
      itemName: map['itemName'] ?? map['name'] ?? '',
      category: map['category'] ?? 'General',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] ?? 'kg',
      minimumStock:
          (map['minimumStock'] as num?)?.toDouble() ??
          (map['minStock'] as num?)?.toDouble() ??
          0.0,
      maximumStock: (map['maximumStock'] as num?)?.toDouble() ?? 0.0,
      supplier: map['supplier'] ?? '',
      purchasePrice: (map['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (map['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      storageLocation: map['storageLocation'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      expiryDate: parseOptionalModelDate(map['expiryDate']),
      notes: map['notes'] ?? '',
      createdAt: parseModelDate(map['createdAt']),
      updatedAt: parseModelDate(map['updatedAt']),
      createdBy: map['createdBy'] ?? '',
      status: map['status'] ?? 'active',
      isDeleted: map['isDeleted'] ?? false,
      lots: lots,
    );
  }
}
