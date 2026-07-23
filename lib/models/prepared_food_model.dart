import '../utils/date_parser.dart';

class LotConsumption {
  final String inventoryItemId;
  final String ingredientName;
  final String lotId;
  final double quantity;
  final String unit;
  final double unitCost;
  final double totalCost;

  const LotConsumption({
    required this.inventoryItemId,
    required this.ingredientName,
    required this.lotId,
    required this.quantity,
    required this.unit,
    required this.unitCost,
    required this.totalCost,
  });

  Map<String, dynamic> toMap() {
    return {
      'inventoryItemId': inventoryItemId,
      'ingredientName': ingredientName,
      'lotId': lotId,
      'quantity': quantity,
      'unit': unit,
      'unitCost': unitCost,
      'totalCost': totalCost,
    };
  }

  factory LotConsumption.fromMap(Map<String, dynamic> map) {
    return LotConsumption(
      inventoryItemId: map['inventoryItemId'] ?? '',
      ingredientName: map['ingredientName'] ?? '',
      lotId: map['lotId'] ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] ?? '',
      unitCost: (map['unitCost'] as num?)?.toDouble() ?? 0.0,
      totalCost: (map['totalCost'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PreparedFoodModel {
  final String id;
  final String menuItemId;
  final String menuItemName;
  final double quantityPrepared;
  final double quantityAvailable;
  final double ingredientCost;
  final double preparationCost;
  final double actualFoodCost;
  final double sellingPrice;
  final List<LotConsumption> lotConsumptions;
  final DateTime preparedAt;
  final String preparedBy;

  const PreparedFoodModel({
    required this.id,
    required this.menuItemId,
    required this.menuItemName,
    required this.quantityPrepared,
    required this.quantityAvailable,
    required this.ingredientCost,
    required this.preparationCost,
    required this.actualFoodCost,
    required this.sellingPrice,
    required this.lotConsumptions,
    required this.preparedAt,
    required this.preparedBy,
  });

  double get estimatedProfit =>
      (sellingPrice * quantityPrepared) - actualFoodCost;
  double get costPerUnit =>
      quantityPrepared == 0 ? 0 : actualFoodCost / quantityPrepared;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'menuItemId': menuItemId,
      'menuItemName': menuItemName,
      'quantityPrepared': quantityPrepared,
      'quantityAvailable': quantityAvailable,
      'ingredientCost': ingredientCost,
      'preparationCost': preparationCost,
      'actualFoodCost': actualFoodCost,
      'sellingPrice': sellingPrice,
      'lotConsumptions': lotConsumptions.map((lot) => lot.toMap()).toList(),
      'preparedAt': preparedAt.toIso8601String(),
      'preparedBy': preparedBy,
    };
  }

  factory PreparedFoodModel.fromMap(Map<String, dynamic> map, String docId) {
    final rawLots = map['lotConsumptions'];
    return PreparedFoodModel(
      id: docId,
      menuItemId: map['menuItemId'] ?? '',
      menuItemName: map['menuItemName'] ?? '',
      quantityPrepared: (map['quantityPrepared'] as num?)?.toDouble() ?? 0.0,
      quantityAvailable: (map['quantityAvailable'] as num?)?.toDouble() ?? 0.0,
      ingredientCost: (map['ingredientCost'] as num?)?.toDouble() ?? 0.0,
      preparationCost: (map['preparationCost'] as num?)?.toDouble() ?? 0.0,
      actualFoodCost: (map['actualFoodCost'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (map['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      lotConsumptions: rawLots is List
          ? rawLots
                .whereType<Map>()
                .map(
                  (lot) =>
                      LotConsumption.fromMap(Map<String, dynamic>.from(lot)),
                )
                .toList()
          : const [],
      preparedAt: parseModelDate(map['preparedAt']),
      preparedBy: map['preparedBy'] ?? '',
    );
  }
}
