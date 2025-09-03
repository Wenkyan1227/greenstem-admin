import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ServiceTask {
  final String id;
  final String mechanicId;
  final String mechanicName;
  final String serviceName;
  final String? mechanicPart;
  final String description;
  final double cost;
  final Duration? estimatedDuration;
  final Duration? actualDuration;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? status;

  ServiceTask({
    required this.id,
    required this.mechanicId,
    required this.mechanicName,
    required this.serviceName,
    this.mechanicPart,
    required this.description,
    required this.cost,
    required this.estimatedDuration,
    this.actualDuration,
    this.startTime,
    this.endTime,
    this.status,
  });

  factory ServiceTask.fromFirestoreData(Map<String, dynamic> data) {
    return ServiceTask(
      id: data['id'] ?? '',
      mechanicId: data['mechanicId'] ?? '',
      mechanicName: data['mechanicName'] ?? '',
      serviceName: data['serviceName'] ?? '',
      mechanicPart: data['mechanicPart'],
      description: data['description'] ?? '',
      cost: (data['cost'] ?? 0).toDouble(),
      estimatedDuration:
          data['estimatedDuration'] != null
              ? Duration(seconds: data['estimatedDuration'])
              : Duration.zero,
      actualDuration:
          data['duration'] != null
              ? Duration(seconds: data['duration'])
              : Duration.zero,
      startTime:
          data['startTime'] != null
              ? (data['startTime'] is Timestamp
                  ? (data['startTime'] as Timestamp).toDate()
                  : DateTime.tryParse(data['startTime']))
              : null,
      endTime:
          data['endTime'] != null
              ? (data['endTime'] is Timestamp
                  ? (data['endTime'] as Timestamp).toDate()
                  : DateTime.tryParse(data['endTime']))
              : null,
      status: data['status'] ?? 'Pending',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'mechanicId': mechanicId,
      'mechanicName': mechanicName,
      'serviceName': serviceName,
      'mechanicPart': mechanicPart,
      'description': description,
      'cost': cost,
      'estimatedDuration': estimatedDuration?.inSeconds,
      'actualDuration': actualDuration?.inSeconds,
      'startTime': startTime != null ? Timestamp.fromDate(startTime!) : null,
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'status': status,
    };
  }

  Duration? get duration {
    if (startTime != null && endTime != null) {
      return endTime!.difference(startTime!);
    }
    return null;
  }

  ServiceTask copyWith({
    String? id,
    String? mechanicId,
    String? mechanicName,
    String? serviceName,
    String? mechanicPart,
    String? description,
    double? cost,
    Duration? estimatedDuration,
    Duration? actualDuration,
    DateTime? startTime,
    DateTime? endTime,
    String? status,
  }) {
    return ServiceTask(
      id: id ?? this.id,
      mechanicId: mechanicId ?? this.mechanicId,
      mechanicName: mechanicName ?? this.mechanicName,
      serviceName: serviceName ?? this.serviceName,
      mechanicPart: mechanicPart ?? this.mechanicPart,
      description: description ?? this.description,
      cost: cost ?? this.cost,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      actualDuration: actualDuration ?? this.actualDuration,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
    );
  }
}
