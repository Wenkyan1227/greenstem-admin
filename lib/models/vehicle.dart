import 'package:cloud_firestore/cloud_firestore.dart';

class Vehicle {
  final String id;
  final String brand;
  final String model;
  final String imageUrl;
  final DateTime createdAt;

  Vehicle({
    required this.id,
    required this.brand,
    required this.model,
    required this.imageUrl,
    required this.createdAt,
  });

  factory Vehicle.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Vehicle(
      id: doc.id,
      brand: data['brand'] ?? '',
      model: data['model'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'brand': brand,
      'model': model,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Vehicle copyWith({
    String? id,
    String? brand,
    String? model,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class VehicleBrand {
  final String id;
  final String name;
  final String logoUrl;
  final List<VehicleModel> models;

  VehicleBrand({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.models,
  });

  factory VehicleBrand.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    List<VehicleModel> models = [];
    if (data['models'] != null) {
      models = (data['models'] as List)
          .map((model) => VehicleModel.fromMap(model))
          .toList();
    }
    
    return VehicleBrand(
      id: doc.id,
      name: data['name'] ?? '',
      logoUrl: data['logoUrl'] ?? '',
      models: models,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'logoUrl': logoUrl,
      'models': models.map((model) => model.toMap()).toList(),
    };
  }
}

class VehicleModel {
  final String id;
  final String name;
  final String imageUrl;

  VehicleModel({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  factory VehicleModel.fromMap(Map<String, dynamic> map) {
    return VehicleModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
    };
  }
} 