class RecipeIngredient {
  final String ingredientName;
  final double quantity;
  final String unit;

  const RecipeIngredient({
    required this.ingredientName,
    required this.quantity,
    required this.unit,
  });

  Map<String, dynamic> toMap() {
    return {
      'ingredientName': ingredientName,
      'quantity': quantity,
      'unit': unit,
    };
  }

  factory RecipeIngredient.fromMap(Map<String, dynamic> map) {
    return RecipeIngredient(
      ingredientName: map['ingredientName'] ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] ?? 'kg',
    );
  }
}

class RecipeModel {
  final String id;
  final String menuItemId;
  final String menuItemName;
  final List<RecipeIngredient> ingredients;
  final double preparationCostPerUnit;
  final DateTime updatedAt;

  const RecipeModel({
    required this.id,
    required this.menuItemId,
    required this.menuItemName,
    required this.ingredients,
    required this.preparationCostPerUnit,
    required this.updatedAt,
  });

  RecipeModel copyWith({
    List<RecipeIngredient>? ingredients,
    double? preparationCostPerUnit,
    DateTime? updatedAt,
  }) {
    return RecipeModel(
      id: id,
      menuItemId: menuItemId,
      menuItemName: menuItemName,
      ingredients: ingredients ?? this.ingredients,
      preparationCostPerUnit:
          preparationCostPerUnit ?? this.preparationCostPerUnit,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'menuItemId': menuItemId,
      'menuItemName': menuItemName,
      'ingredients': ingredients.map((ingredient) => ingredient.toMap()).toList(),
      'preparationCostPerUnit': preparationCostPerUnit,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory RecipeModel.fromMap(Map<String, dynamic> map, String docId) {
    final rawIngredients = map['ingredients'];
    return RecipeModel(
      id: docId,
      menuItemId: map['menuItemId'] ?? '',
      menuItemName: map['menuItemName'] ?? '',
      ingredients: rawIngredients is List
          ? rawIngredients
              .whereType<Map>()
              .map((ingredient) => RecipeIngredient.fromMap(
                    Map<String, dynamic>.from(ingredient),
                  ))
              .toList()
          : const [],
      preparationCostPerUnit:
          (map['preparationCostPerUnit'] as num?)?.toDouble() ?? 0.0,
      updatedAt: _parseDate(map['updatedAt']),
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
