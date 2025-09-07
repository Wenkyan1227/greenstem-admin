import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceTaskCatalog {
  final String id; // Firestore doc id
  final String serviceName; // e.g. "Oil Change"
  final String description; // e.g. "Replace engine oil and filter"
  final double serviceFee; // e.g. 120.0
  final Duration estimatedDuration; // e.g. "1h 30m"
  final DateTime createdAt;

  ServiceTaskCatalog({
    required this.id,
    required this.serviceName,
    required this.description,
    required this.serviceFee,
    required this.estimatedDuration,
    required this.createdAt,
  });

  factory ServiceTaskCatalog.fromFirestoreData(
    String id,
    Map<String, dynamic> map,
  ) {
    return ServiceTaskCatalog(
      id: id,
      serviceName: map['serviceName'] ?? '',
      description: map['description'] ?? '',
      serviceFee: (map['serviceFee'] ?? 0).toDouble(),
      estimatedDuration:
          map['estimatedDuration'] != null
              ? Duration(
                seconds:
                    map['estimatedDuration'] is int
                        ? map['estimatedDuration'] as int
                        : 0,
              ) // Safely handle type checking
              : Duration.zero,
      createdAt:
          (map['createdAt'] is Timestamp)
              ? (map['createdAt'] as Timestamp).toDate()
              : DateTime.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'serviceName': serviceName,
      'description': description,
      'serviceFee': serviceFee,
      'estimatedDuration': estimatedDuration.inSeconds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ServiceTaskCatalog copyWith({
    String? id,
    String? serviceName,
    String? description,
    double? serviceFee,
    Duration? estimatedDuration,
    DateTime? createdAt,
  }) {
    return ServiceTaskCatalog(
      id: id ?? this.id,
      serviceName: serviceName ?? this.serviceName,
      description: description ?? this.description,
      serviceFee: serviceFee ?? this.serviceFee,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
