import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String id;
  final String customerName;
  final String customerContact;
  final String vehiclePlate;
  final String vehicleModel;
  final String vehicleBrand;
  final DateTime createdAt;

  Customer({
    required this.id,
    required this.customerName,
    required this.customerContact,
    required this.vehiclePlate,
    required this.vehicleModel,
    required this.vehicleBrand,
    required this.createdAt,
  });

  factory Customer.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Customer(
      id: doc.id, // Assuming Firestore document ID is used
      customerName: data['customerName'] ?? '',
      customerContact: data['customerContact'] ?? '',
      vehiclePlate: data['vehiclePlate'] ?? '',
      vehicleModel: data['vehicleModel'] ?? '',
      vehicleBrand: data['vehicleBrand'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerName': customerName,
      'customerContact': customerContact,
      'vehiclePlate': vehiclePlate,
      'vehicleModel': vehicleModel,
      'vehicleBrand': vehicleBrand,
      'createdAt': createdAt,
    };
  }

  Customer copyWith({
    String? id,
    String? customerName,
    String? customerContact,
    String? vehiclePlate,
    String? vehicleModel,
    String? vehicleBrand,
    String? email,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      customerContact: customerContact ?? this.customerContact,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleBrand: vehicleBrand ?? this.vehicleBrand,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
