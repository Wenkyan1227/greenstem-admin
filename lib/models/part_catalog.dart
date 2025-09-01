import 'package:cloud_firestore/cloud_firestore.dart';

class PartCatalog {
  final String id;
  final String name;
  final double basePrice;
  final String description;
  final String category;
  final int stockQuantity;

  PartCatalog({
    required this.id,
    required this.name,
    required this.basePrice,
    required this.description,
    required this.category,
    this.stockQuantity = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'basePrice': basePrice,
      'description': description,
      'category': category,
      'stockQuantity': stockQuantity,
    };
  }

  factory PartCatalog.fromMap(Map<String, dynamic> map) {
    return PartCatalog(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      basePrice: (map['basePrice'] ?? 0.0).toDouble(),
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      stockQuantity: map['stockQuantity'] ?? 0,
    );
  }

  factory PartCatalog.fromSnapshot(DocumentSnapshot snapshot) {
    return PartCatalog.fromMap(snapshot.data() as Map<String, dynamic>);
  }
}
