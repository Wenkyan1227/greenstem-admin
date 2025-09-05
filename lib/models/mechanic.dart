import 'package:cloud_firestore/cloud_firestore.dart';

class Mechanic {
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;

  Mechanic({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
  });

  factory Mechanic.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Mechanic(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      createdAt:
          data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(), // Provide a default value
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'name': name, 'email': email, 'createdAt': createdAt};
  }

  Mechanic copyWith({
    String? id,
    String? name,
    String? email,
    DateTime? createdAt,
  }) {
    return Mechanic(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
