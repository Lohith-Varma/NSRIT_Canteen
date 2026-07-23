class MenuItemModel {
  final String id;
  final String name;
  final String section;
  final String imageUrl;
  final double sellingPrice;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MenuItemModel({
    required this.id,
    required this.name,
    required this.section,
    required this.imageUrl,
    required this.sellingPrice,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'section': section,
      'imageUrl': imageUrl,
      'sellingPrice': sellingPrice,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MenuItemModel.fromMap(Map<String, dynamic> map, String docId) {
    return MenuItemModel(
      id: docId,
      name: map['name'] ?? '',
      section: map['section'] ?? 'Breakfast',
      imageUrl: map['imageUrl'] ?? '',
      sellingPrice: (map['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      isActive: map['isActive'] ?? true,
      createdAt: _parseDate(map['createdAt']),
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
