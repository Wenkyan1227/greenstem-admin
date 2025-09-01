import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/part_catalog.dart';
import '../models/part.dart';

class PartCatalogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all parts in the catalog
  Stream<List<PartCatalog>> getCatalogParts() {
    return _firestore
        .collection('parts_catalog')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PartCatalog.fromSnapshot(doc))
            .toList());
  }

  // Add a new part to the catalog
  Future<void> addCatalogPart(PartCatalog part) async {
    await _firestore
        .collection('parts_catalog')
        .doc(part.id)
        .set(part.toMap());
  }

  // Update a part in the catalog
  Future<void> updateCatalogPart(PartCatalog part) async {
    await _firestore
        .collection('parts_catalog')
        .doc(part.id)
        .update(part.toMap());
  }

  // Delete a part from the catalog
  Future<void> deleteCatalogPart(String partId) async {
    await _firestore.collection('parts_catalog').doc(partId).delete();
  }

  // Add a part to a job
  Future<void> addPartToJob(String jobId, Part part) async {
    await _firestore
        .collection('jobs')
        .doc(jobId)
        .collection('parts')
        .doc(part.id)
        .set(part.toMap());
  }

  // Get all parts for a specific job
  Stream<List<Part>> getJobParts(String jobId) {
    return _firestore
        .collection('jobs')
        .doc(jobId)
        .collection('parts')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Part.fromSnapshot(doc)).toList());
  }

  // Remove a part from a job
  Future<void> removePartFromJob(String jobId, String partId) async {
    await _firestore
        .collection('jobs')
        .doc(jobId)
        .collection('parts')
        .doc(partId)
        .delete();
  }

  // Update part quantity in a job
  Future<void> updatePartQuantity(String jobId, String partId, int newQuantity) async {
    await _firestore
        .collection('jobs')
        .doc(jobId)
        .collection('parts')
        .doc(partId)
        .update({'quantity': newQuantity});
  }
}
