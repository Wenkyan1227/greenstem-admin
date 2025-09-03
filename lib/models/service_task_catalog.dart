import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceTaskCatalog {
  final String id;                // Firestore doc id
  final String serviceName;       // e.g. "Oil Change"
  final String description;       // e.g. "Replace engine oil and filter"
  final double cost;              // e.g. 120.0
  final Duration estimatedDuration; // e.g. "1h 30m"

  ServiceTaskCatalog({
    required this.id,
    required this.serviceName,
    required this.description,
    required this.cost,
    required this.estimatedDuration,
  });

  factory ServiceTaskCatalog.fromFirestoreData(String id, Map<String, dynamic> map) {
    return ServiceTaskCatalog(
      id: id,
      serviceName: map['serviceName'] ?? '',
      description: map['description'] ?? '',
      cost: (map['cost'] ?? 0).toDouble(),
      estimatedDuration:
          map['estimatedDuration'] != null
              ? Duration(seconds: map['estimatedDuration'] as int)
              : Duration.zero,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'serviceName': serviceName,
      'description': description,
      'cost': cost,
      'estimatedDuration': estimatedDuration.inSeconds,
    };
  }
}
