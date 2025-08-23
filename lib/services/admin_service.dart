import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/admin.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check if current user is an admin
  Future<bool> isCurrentUserAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final adminDoc = await _firestore.collection('admins').doc(user.uid).get();

    return adminDoc.exists;
  }

  // Get current admin data
  Future<Admin?> getCurrentAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final adminDoc = await _firestore.collection('admins').doc(user.uid).get();

    if (!adminDoc.exists) return null;
    return Admin.fromFirestore(adminDoc);
  }

  // Create new admin
  Future<void> createAdmin({
    required String name,
    required String email,
    required String password,
  }) async {
    // Create user with Firebase Auth
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Store admin data in Firestore
    await _firestore.collection('admins').doc(userCredential.user!.uid).set({
      'name': name,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'role': 'admin',
    });
  }

  // Sign in admin
  Future<Admin?> signInAdmin({
    required String email,
    required String password,
  }) async {
    // Check if the email is "admin@gmail.com"


    // Sign in with Firebase Auth
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if user exists in admin collection
      final adminDoc =
          await _firestore
              .collection('admins')
              .doc(userCredential.user!.uid)
              .get();

      if (!adminDoc.exists) {
        // User is not an admin, sign out
        await _auth.signOut();
        return null;
      }

      return Admin.fromFirestore(adminDoc);
    } catch (e) {
      // Handle error if sign-in fails
      print("Error signing in admin: $e");
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get all admins (for admin management)
  Stream<List<Admin>> getAllAdmins() {
    return _firestore
        .collection('admins')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Admin.fromFirestore(doc)).toList(),
        );
  }

  // Update admin data
  Future<void> updateAdmin({
    required String adminId,
    required String name,
    required String email,
  }) async {
    await _firestore.collection('admins').doc(adminId).update({
      'name': name,
      'email': email,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete admin
  Future<void> deleteAdmin(String adminId) async {
    await _firestore.collection('admins').doc(adminId).delete();
  }
}
