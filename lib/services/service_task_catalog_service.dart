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
      if (lastId.startsWith('J')) {
        String numberPart = lastId.substring(1);
        nextNumber = (int.tryParse(numberPart) ?? 0) + 1;
      }
    }

    return 'J${nextNumber.toString().padLeft(4, '0')}';
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
  Future<void> addServiceTask(ServiceTaskCatalog task) async {
    try {
      // Generate a custom service task ID
      String serviceTaskId = await _generateServiceTaskId();

      // Create the job document with the custom ID
      DocumentReference docRef = _serviceTaskCollection.doc(serviceTaskId);

      // Set the data to Firestore using the service task ID
      await docRef.set(task.copyWith(id: serviceTaskId).toFirestore());

      print("✅ Service task added successfully");
    } catch (e) {
      print("❌ Error adding service task: $e");
    }
  }

  Future<void> addDummyServiceTasks() async {
    List<Map<String, dynamic>> dummyTasks = [
      {
        "cost": 50,
        "description": "Change engine oil and oil filter",
        "estimatedDuration": 3600,
        "serviceName": "Oil Change",
      },
      {
        "cost": 120,
        "description": "Replace front brake pads and inspect rotors",
        "estimatedDuration": 7200,
        "serviceName": "Brake Pad Replacement",
      },
      {
        "cost": 80,
        "description": "Rotate tires and check for uneven wear",
        "estimatedDuration": 2700,
        "serviceName": "Tire Rotation",
      },
      {
        "cost": 150,
        "description": "Replace car battery and perform charging system test",
        "estimatedDuration": 5400,
        "serviceName": "Battery Replacement",
      },
      {
        "cost": 200,
        "description":
            "Perform engine diagnostics and troubleshoot error codes",
        "estimatedDuration": 7200,
        "serviceName": "Engine Diagnostics",
      },
      {
        "cost": 60,
        "description": "Replace windshield wipers and check washer fluid",
        "estimatedDuration": 1800,
        "serviceName": "Wiper Replacement",
      },
      {
        "cost": 90,
        "description": "Replace air filter and check intake system",
        "estimatedDuration": 3600,
        "serviceName": "Air Filter Replacement",
      },
      {
        "cost": 180,
        "description": "Flush and replace transmission fluid",
        "estimatedDuration": 9000,
        "serviceName": "Transmission Fluid Service",
      },
      {
        "cost": 220,
        "description": "Replace spark plugs and inspect ignition system",
        "estimatedDuration": 10800,
        "serviceName": "Spark Plug Replacement",
      },
      {
        "cost": 300,
        "description": "Replace timing belt and inspect water pump",
        "estimatedDuration": 18000,
        "serviceName": "Timing Belt Replacement",
      },
    ];
  }
}
