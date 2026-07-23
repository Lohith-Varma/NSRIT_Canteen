import '../utils/date_parser.dart';

class SupplierModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String? gstNumber;
  final DateTime createdAt;

  SupplierModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    this.gstNumber,
    required this.createdAt,
  });

  SupplierModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? gstNumber,
    DateTime? createdAt,
  }) {
    return SupplierModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      gstNumber: gstNumber ?? this.gstNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'gstNumber': gstNumber,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SupplierModel.fromMap(Map<String, dynamic> map, String docId) {
    return SupplierModel(
      id: docId,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      gstNumber: map['gstNumber'],
      createdAt: parseModelDate(map['createdAt']),
    );
  }
}
