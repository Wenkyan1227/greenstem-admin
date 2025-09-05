import 'package:cloud_firestore/cloud_firestore.dart';

class PartCatalog {
  final String id;
  final String name;
  final double basePrice;
  final int stockQuantity;

  PartCatalog({
    required this.id,
    required this.name,
    required this.basePrice,
    this.stockQuantity = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'basePrice': basePrice,
      'stockQuantity': stockQuantity,
    };
  }

  factory PartCatalog.fromMap(Map<String, dynamic> map) {
    return PartCatalog(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      basePrice: (map['basePrice'] ?? 0.0).toDouble(),
      stockQuantity: map['stockQuantity'] ?? 0,
    );
  }

  factory PartCatalog.fromSnapshot(DocumentSnapshot snapshot) {
    return PartCatalog.fromMap(snapshot.data() as Map<String, dynamic>);
  }
}
