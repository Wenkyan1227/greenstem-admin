import 'package:cloud_firestore/cloud_firestore.dart';

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