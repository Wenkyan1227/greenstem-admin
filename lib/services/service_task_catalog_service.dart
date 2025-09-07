import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_task_catalog.dart';

class ServiceTaskCatalogService {
  final CollectionReference _serviceTaskCollection = FirebaseFirestore.instance
      .collection('service_tasks');

  // Generate next service task ID with format J000X
  Future<String> _generateServiceTaskId() async {
    QuerySnapshot snapshot =
        await _serviceTaskCollection
            .orderBy(FieldPath.documentId, descending: true)
            .limit(1)
            .get();

    int nextNumber = 1;
    if (snapshot.docs.isNotEmpty) {
      String lastId = snapshot.docs.first.id;
      if (lastId.startsWith('ST')) {
        String numberPart = lastId.substring(2);
        nextNumber = (int.tryParse(numberPart) ?? 0) + 1;
      }
    }

    return 'ST${nextNumber.toString().padLeft(4, '0')}';
  }

  // Fetch all service tasks
  Stream<List<ServiceTaskCatalog>> getAllServiceTasks() {
    return _serviceTaskCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return ServiceTaskCatalog.fromFirestoreData(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }).toList();
    });
  }

  // Add a new service task to Firestore
  Future<String> addServiceTask(ServiceTaskCatalog task) async {
    try {
      // Generate a custom service task ID
      String serviceTaskId = await _generateServiceTaskId();

      // Create the job document with the custom ID
      DocumentReference docRef = _serviceTaskCollection.doc(serviceTaskId);

      // Set the data to Firestore using the service task ID
      await docRef.set(task.copyWith(id: serviceTaskId).toFirestore());

      print("✅ Service task added successfully");
      return serviceTaskId;
    } catch (e) {
      print("❌ Error adding service task: $e");
      return 'null';
    }
  }

  Future<void> updateServiceTask(ServiceTaskCatalog task) async {
    try {
      await _serviceTaskCollection.doc(task.id).update(task.toFirestore());
      print("✅ Service task updated successfully");
    } catch (e) {
      print("❌ Error updating service task: $e");
    }
  }

  Future<void> deleteServiceTask(String id) async {
    try {
      await _serviceTaskCollection.doc(id).delete();
      print("✅ Service task deleted successfully");
    } catch (e) {
      print("❌ Error deleting service task: $e");
    }
  }

  Future<void> addDummyServiceTasks() async {
    List<Map<String, dynamic>> dummyTasks = [
      {
        "serviceFee": 50.0,
        "description": "Change engine oil and oil filter",
        "estimatedDuration": Duration(seconds: 3600),
        "serviceName": "Oil Change",
      },
      {
        "serviceFee": 120.0,
        "description": "Replace front brake pads and inspect rotors",
        "estimatedDuration": Duration(seconds: 7200),
        "serviceName": "Brake Pad Replacement",
      },
      {
        "serviceFee": 80.0,
        "description": "Rotate tires and check for uneven wear",
        "estimatedDuration": Duration(seconds: 2700),
        "serviceName": "Tire Rotation",
      },
      {
        "serviceFee": 150.0,
        "description": "Replace car battery and perform charging system test",
        "estimatedDuration": Duration(seconds: 5400),
        "serviceName": "Battery Replacement",
      },
      {
        "serviceFee": 200.0,
        "description":
            "Perform engine diagnostics and troubleshoot error codes",
        "estimatedDuration": Duration(seconds: 7200),
        "serviceName": "Engine Diagnostics",
      },
      {
        "serviceFee": 60.0,
        "description": "Replace windshield wipers and check washer fluid",
        "estimatedDuration": Duration(seconds: 1800),
        "serviceName": "Wiper Replacement",
      },
      {
        "serviceFee": 90.0,
        "description": "Replace air filter and check intake system",
        "estimatedDuration": Duration(seconds: 600),
        "serviceName": "Air Filter Replacement",
      },
      {
        "serviceFee": 180.0,
        "description": "Flush and replace transmission fluid",
        "estimatedDuration": Duration(seconds: 9000),
        "serviceName": "Transmission Fluid Service",
      },
      {
        "serviceFee": 220.0,
        "description": "Replace spark plugs and inspect ignition system",
        "estimatedDuration": Duration(seconds: 10800),
        "serviceName": "Spark Plug Replacement",
      },
      {
        "serviceFee": 300.0,
        "description": "Replace timing belt and inspect water pump",
        "estimatedDuration": Duration(seconds: 18000),
        "serviceName": "Timing Belt Replacement",
      },
    ];

    for (var taskData in dummyTasks) {
      String id = await _generateServiceTaskId();
      final task = ServiceTaskCatalog(
        id: id,
        serviceName: taskData['serviceName'],
        serviceFee: taskData['serviceFee'],
        description: taskData['description'],
        estimatedDuration: taskData['estimatedDuration'],
        createdAt: DateTime.now(),
      );
      await addServiceTask(task);
    }
  }
}
