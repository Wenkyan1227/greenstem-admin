import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:greenstem_admin/models/part_catalog.dart';

class Part {
  final String id;
  final String catalogId; // Reference to the catalog part
  final String taskId;
  final String name;
  final double price;
  final int quantity;
  final DateTime addedAt;

  Part({
    required this.id,
    required this.catalogId,
    required this.taskId,
    required this.name,
    required this.price,
    required this.quantity,
    DateTime? addedAt,
  }) : this.addedAt = addedAt ?? DateTime.now();

  double get totalPrice => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'catalogId': catalogId,
      'taskId': taskId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory Part.fromMap(Map<String, dynamic> map) {
    return Part(
      id: map['id'] ?? '',
      catalogId: map['catalogId'] ?? '',
      taskId: map['taskId'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      quantity: map['quantity'] ?? 0,
      addedAt: DateTime.parse(map['addedAt']),
    );
  }

  factory Part.fromSnapshot(DocumentSnapshot snapshot) {
    return Part.fromMap(snapshot.data() as Map<String, dynamic>);
  }

  // Create a part from catalog item
  factory Part.fromCatalog(PartCatalog catalog, {required int quantity}) {
    return Part(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      catalogId: catalog.id,
      taskId: 'TEMP_ID',
      name: catalog.name,
      price: catalog.basePrice,
      quantity: quantity,
    );
  }

  Part copyWith({
    String? id,
    String? catalogId,
    String? taskId,
    String? name,
    double? price,
    int? quantity,
    String? description,
    String? category,
    DateTime? addedAt,
  }) {
    return Part(
      id: id ?? this.id,
      catalogId: catalogId ?? this.catalogId,
      taskId: taskId ?? this.taskId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}
