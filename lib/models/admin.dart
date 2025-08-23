import 'package:cloud_firestore/cloud_firestore.dart';

class Admin {
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;
  final String role;

  Admin({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    required this.role,
  });

  factory Admin.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Admin(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      role: data['role'] ?? 'admin',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'createdAt': Timestamp.fromDate(createdAt),
      'role': role,
    };
  }

  Admin copyWith({
    String? id,
    String? name,
    String? email,
    DateTime? createdAt,
    String? role,
  }) {
    return Admin(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      role: role ?? this.role,
    );
  }
}
