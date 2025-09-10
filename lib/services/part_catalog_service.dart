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
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => PartCatalog.fromSnapshot(doc))
                  .toList(),
        );
  }

  // Add a new part to the catalog
  Future<void> addCatalogPart(PartCatalog part) async {
    await _firestore.collection('parts_catalog').doc(part.id).set(part.toMap());
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
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Part.fromSnapshot(doc)).toList(),
        );
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
  Future<void> updatePartQuantity(
    String jobId,
    String partId,
    int newQuantity,
  ) async {
    await _firestore
        .collection('jobs')
        .doc(jobId)
        .collection('parts')
        .doc(partId)
        .update({'quantity': newQuantity});
  }

  Future<void> addDummyParts() async {
    List<Map<String, dynamic>> dummyParts = [
      {
        "id": DateTime.now().millisecondsSinceEpoch.toString(),
        "name": "Engine",
        "basePrice": 5000.0,
        "stockQuantity": 50,
      },
      {
        "id": DateTime.now().add(const Duration(seconds: 1)).millisecondsSinceEpoch.toString(),
        "name": "Brake Pads",
        "basePrice": 200.0,
        "stockQuantity": 150,
      },
      {
        "id": DateTime.now().add(const Duration(seconds: 2)).millisecondsSinceEpoch.toString(),
        "name": "Clutch",
        "basePrice": 1200.0,
        "stockQuantity": 60,
      },
      {
        "id": DateTime.now().add(const Duration(seconds: 3)).millisecondsSinceEpoch.toString(),
        "name": "Alternator",
        "basePrice": 800.0,
        "stockQuantity": 40,
      },
      {
        "id": DateTime.now().add(const Duration(seconds: 4)).millisecondsSinceEpoch.toString(),
        "name": "Battery",
        "basePrice": 400.0,
        "stockQuantity": 75,
      },
      {
        "id": DateTime.now().add(const Duration(seconds: 5)).millisecondsSinceEpoch.toString(),
        "name": "Radiator",
        "basePrice": 900.0,
        "stockQuantity": 30,
      },
      {
        "id": DateTime.now().add(const Duration(seconds: 6)).millisecondsSinceEpoch.toString(),
        "name": "Fuel Pump",
        "basePrice": 350.0,
        "stockQuantity": 55,
      },
      {
        "id": DateTime.now().add(const Duration(seconds: 7)).millisecondsSinceEpoch.toString(),
        "name": "Shock Absorber",
        "basePrice": 600.0,
        "stockQuantity": 100,
      },
      {
        "id": DateTime.now().add(const Duration(seconds: 8)).millisecondsSinceEpoch.toString(),
        "name": "Air Filter",
        "basePrice": 100.0,
        "stockQuantity": 200,
      },
      {
        "id": DateTime.now().add(const Duration(seconds: 9)).millisecondsSinceEpoch.toString(),
        "name": "Spark Plug",
        "basePrice": 50.0,
        "stockQuantity": 500,
      },
      {
        "id": DateTime.now().add(const Duration(seconds: 10)).millisecondsSinceEpoch.toString(),
        "name": "Oil Filter",
        "basePrice": 80.0,
        "stockQuantity": 300,
      },
      {
        "id": DateTime.now().add(const Duration(seconds: 11)).millisecondsSinceEpoch.toString(),
        "name": "Timing Belt",
        "basePrice": 250.0,
        "stockQuantity": 70,
      },
    ];

    for (var partData in dummyParts) {
      final task = PartCatalog(
        id: partData['id'],
        name: partData['name'],
        basePrice: partData['basePrice'],
        stockQuantity: partData['stockQuantity'],
      );
      await addCatalogPart(task);
    }
  }
}
