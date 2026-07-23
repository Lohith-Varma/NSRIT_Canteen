import '../utils/date_parser.dart';

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
      createdAt: parseModelDate(map['createdAt']),
      updatedAt: parseModelDate(map['updatedAt']),
    );
  }
}
