import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/mechanic.dart';

class MechanicService {
  final CollectionReference _mechanicsCollection =
      FirebaseFirestore.instance.collection('mechanics');

  // Get all mechanics
  Stream<List<Mechanic>> getMechanics() {
    return _mechanicsCollection
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Mechanic.fromFirestore(doc)).toList();
    });
  }

    // Get all mechanics (simplified - no availability filter)
  Stream<List<Mechanic>> getAllMechanics() {
    return _mechanicsCollection
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Mechanic.fromFirestore(doc)).toList();
    });
  }

  // Create a new mechanic (with FirebaseAuth sign-up)
  Future<void> signUpMechanic(String name, String email, String password) async {
    try {
      // Sign up the mechanic using Firebase Authentication
      final UserCredential credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: email.trim(), password: password.trim());

      // Add mechanic data to Firestore
      await _mechanicsCollection.doc(credential.user!.uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception("Failed to sign up mechanic: $e");
    }
  }

    // Create a new mechanic
  Future<void> createMechanicWithAuth(Mechanic mechanic) async {
    await _mechanicsCollection.doc(mechanic.id).set({
      'name': mechanic.name,
      'email': mechanic.email,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Create a new mechanic (without FirebaseAuth, using Firestore only)
  Future<void> createMechanic(Mechanic mechanic) async {
    await _mechanicsCollection.add(mechanic.toFirestore());
  }

  // Update a mechanic
  Future<void> updateMechanic(Mechanic mechanic) async {
    await _mechanicsCollection.doc(mechanic.id).update(mechanic.toFirestore());
  }

  // Delete a mechanic
  Future<void> deleteMechanic(String mechanicId) async {
    await _mechanicsCollection.doc(mechanicId).delete();
  }

  // Get mechanic by ID
  Future<Mechanic?> getMechanicById(String mechanicId) async {
    DocumentSnapshot doc = await _mechanicsCollection.doc(mechanicId).get();
    if (doc.exists) {
      return Mechanic.fromFirestore(doc);
    }
    return null;
  }

  // Get mechanic statistics
  Future<Map<String, dynamic>> getMechanicStatistics() async {
    QuerySnapshot snapshot = await _mechanicsCollection.get();
    Map<String, dynamic> stats = {
      'total': 0,
    };

    stats['total'] = snapshot.docs.length;

    return stats;
  }
}
