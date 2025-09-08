import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:greenstem_admin/models/note.dart';
import 'package:greenstem_admin/models/service_task.dart';
import 'package:greenstem_admin/models/part.dart';

class Job {
  final String id;
  final String description;
  final String customerName;
  final String customerContact;
  final String vehicleModel;
  final String vehiclePlate;
  final String priority;
  final String status;
  final List<ServiceTask> services;
  final List<Part> parts;
  final DateTime scheduledDate;
  final DateTime createdDate;
  final String imageUrl;
  final Duration estimatedDuration;
  final List<Note> notes;
  final String? customerSignature;
  final DateTime? completionDate;
  final String? assignedTo;
  final double? totalCost;

  Job({
    required this.id,
    required this.description,
    required this.customerName,
    required this.customerContact,
    required this.vehicleModel,
    required this.vehiclePlate,
    required this.priority,
    required this.status,
    required this.services,
    this.parts = const [],
    required this.scheduledDate,
    required this.createdDate,
    required this.imageUrl,
    required this.estimatedDuration,
    required this.notes,
    this.customerSignature,
    this.completionDate,
    this.assignedTo,
    required this.totalCost,
  });

  factory Job.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Job(
      id: doc.id,
      description: data['description'] ?? '',
      customerName: data['customerName'] ?? '',
      customerContact: data['customerContact'] ?? '',
      vehicleModel: data['vehicleModel'] ?? '',
      vehiclePlate: data['vehiclePlate'] ?? '',
      priority: data['priority'] ?? 'medium',
      status: data['status'] ?? 'pending',
      services: [], // Will be loaded separately from subcollection
      parts: [], // Will be loaded separately from subcollection
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
      estimatedDuration: () {
        final value = data['estimatedDuration'];
        if (value == null) return Duration.zero;

        if (value is int) {
          return Duration(seconds: value);
        } else if (value is String) {
          return Duration(seconds: int.tryParse(value) ?? 0);
        } else {
          return Duration.zero;
        }
      }(),
      customerSignature: data['customerSignature'] as String?,
      completionDate:
          data['completionDate'] != null
              ? (data['completionDate'] is Timestamp
                  ? (data['completionDate'] as Timestamp).toDate()
                  : DateTime.parse(data['completionDate']))
              : null,
      assignedTo: data['assignedTo'],
      totalCost: (data['totalCost'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // Modified toFirestore to exclude subcollections from main document
  Map<String, dynamic> toFirestore() {
    return {
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
      'estimatedDuration': estimatedDuration.inSeconds,
      'customerSignature': customerSignature,
      'completionDate':
          completionDate != null ? Timestamp.fromDate(completionDate!) : null,
      'assignedTo': assignedTo,
      'totalCost': totalCost!.toDouble(),
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
    Duration? estimatedDuration,
    List<Note>? notes,
    String? customerSignature,
    DateTime? completionDate,
    String? assignedTo,
    double? totalCost,
  }) {
    return Job(
      id: id ?? this.id,
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
      totalCost: totalCost ?? this.totalCost,
    );
  }

  // Load service tasks from subcollection
  static Future<List<ServiceTask>> loadServiceTasks(String jobId) async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance
            .collection('jobs')
            .doc(jobId)
            .collection('service_tasks')
            .get();

    return snapshot.docs
        .map(
          (doc) =>
              ServiceTask.fromFirestoreData(doc.data() as Map<String, dynamic>),
        )
        .toList();
  }

  // Load parts from subcollection
  static Future<List<Part>> loadParts(String jobId) async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance
            .collection('jobs')
            .doc(jobId)
            .collection('parts')
            .get();

    return snapshot.docs
        .map((doc) => Part.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }
}
