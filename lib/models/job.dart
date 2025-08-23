import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class Job {
  final String id;
  final String title;
  final String description;
  final String customerName;
  final String customerContact;
  final String vehicleModel;
  final String vehiclePlate;
  final String priority;
  final String status;
  final List<ServiceTask> services;
  final DateTime scheduledDate;
  final DateTime createdDate;
  final String imageUrl;
  final String estimatedDuration;
  final List<Note> notes;
  final String? customerSignature;
  final DateTime? completionDate;
  final String? assignedTo;

  Job({
    required this.id,
    required this.title,
    required this.description,
    required this.customerName,
    required this.customerContact,
    required this.vehicleModel,
    required this.vehiclePlate,
    required this.priority,
    required this.status,
    required this.services,
    required this.scheduledDate,
    required this.createdDate,
    required this.imageUrl,
    required this.estimatedDuration,
    required this.notes,
    this.customerSignature,
    this.completionDate,
    this.assignedTo,
  });

  factory Job.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;


    return Job(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      customerName: data['customerName'] ?? '',
      customerContact: data['customerContact'] ?? '',
      vehicleModel: data['vehicleModel'] ?? '',
      vehiclePlate: data['vehiclePlate'] ?? '',
      priority: data['priority'] ?? 'medium',
      status: data['status'] ?? 'pending',
      services: [], // Will be loaded separately from subcollection
      notes: [], // Will be loaded separately from subcollection
      scheduledDate:
          (data['scheduledDate'] is Timestamp)
              ? (data['scheduledDate'] as Timestamp).toDate()
              : DateTime.parse(data['scheduledDate']),
      createdDate:
          (data['createdDate'] is Timestamp)
              ? (data['createdDate'] as Timestamp).toDate()
              : DateTime.parse(data['createdDate']),
      imageUrl: data['imageUrl'] ?? '',
      estimatedDuration: data['estimatedDuration'] ?? '',
      customerSignature: data['customerSignature'] as String?,
      completionDate:
          data['completionDate'] != null
              ? (data['completionDate'] is Timestamp
                  ? (data['completionDate'] as Timestamp).toDate()
                  : DateTime.parse(data['completionDate']))
              : null,
      assignedTo: data['assignedTo'],
    );
  }

  // Modified toFirestore to exclude subcollections from main document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'customerName': customerName,
      'customerContact': customerContact,
      'vehicleModel': vehicleModel,
      'vehiclePlate': vehiclePlate,
      'priority': priority,
      'status': status,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'createdDate': Timestamp.fromDate(createdDate),
      'imageUrl': imageUrl,
      'estimatedDuration': estimatedDuration,
      'customerSignature': customerSignature,
      'completionDate':
          completionDate != null ? Timestamp.fromDate(completionDate!) : null,
      'assignedTo': assignedTo,
      // Note: Don't include 'notes' and 'serviceTasks' here as they're in subcollections
    };
  }

  Job copyWith({
    String? id,
    String? title,
    String? description,
    String? customerName,
    String? customerContact,
    String? vehicleModel,
    String? vehiclePlate,
    String? priority,
    String? status,
    List<ServiceTask>? services,
    DateTime? scheduledDate,
    DateTime? createdDate,
    String? imageUrl,
    String? estimatedDuration,
    List<Note>? notes,
    String? customerSignature,
    DateTime? completionDate,
    String? assignedTo,
  }) {
    return Job(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      customerName: customerName ?? this.customerName,
      customerContact: customerContact ?? this.customerContact,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      services: services ?? this.services,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      createdDate: createdDate ?? this.createdDate,
      imageUrl: imageUrl ?? this.imageUrl,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      notes: notes ?? this.notes,
      customerSignature: customerSignature ?? this.customerSignature,
      completionDate: completionDate ?? this.completionDate,
      assignedTo: assignedTo ?? this.assignedTo,
    );
  }
}

class ServiceTask {
  final String id;
  final String mechanicId;
  final String mechanicName;
  final String serviceName;
  final String? mechanicPart;
  final String description;
  final double cost;
  final String estimatedDuration;
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
      estimatedDuration: data['estimatedDuration'] ?? '',
      actualDuration:
          data['actualDuration'] != null
              ? Duration(seconds: data['actualDuration'])
              : null,
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
      'estimatedDuration': estimatedDuration,
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
    String? estimatedDuration,
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

class Note {
  final String id;
  final String title;
  final String text;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> photoUrls;
  final String? serviceTaskId;

  Note({
    required this.id,
    required this.title,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
    required this.photoUrls,
    this.serviceTaskId,
  });

  factory Note.fromFirestoreData(Map<String, dynamic> data) {
    return Note(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      text: data['text'] ?? '',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.parse(data['createdAt']),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(data['updatedAt']),
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      serviceTaskId: data['serviceTaskId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'photoUrls': photoUrls,
      'serviceTaskId': serviceTaskId,
    };
  }

  Note copyWith({
    String? id,
    String? title,
    String? text,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? photoUrls,
    String? serviceTaskId,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      photoUrls: photoUrls ?? this.photoUrls,
      serviceTaskId: serviceTaskId ?? this.serviceTaskId,
    );
  }
}