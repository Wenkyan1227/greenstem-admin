import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_task_catalog.dart';

class ServiceTaskCatalogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<ServiceTaskCatalog>> getAllServiceTasks() {
    return _firestore.collection("service_tasks").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return ServiceTaskCatalog.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Future<void> addServiceTask(ServiceTaskCatalog task) async {
    try {
      await _firestore.collection("service_tasks").add(task.toMap());
      print("✅ Service task added successfully");
    } catch (e) {
      print("❌ Error adding service task: $e");
    }
  }

  Future<void> addNewServiceTask(ServiceTaskCatalog task) async {
    await _firestore.collection("serviceTasks").add(task.toMap());
  }

  Future<void> addDummyServiceTasks() async {
    List<Map<String, dynamic>> dummyTasks = [
      {
        "cost": 50,
        "description": "Change engine oil and oil filter",
        "estimatedDuration": "1h",
        "serviceName": "Oil Change",
      },
      {
        "cost": 120,
        "description": "Replace front brake pads and inspect rotors",
        "estimatedDuration": "2h",
        "serviceName": "Brake Pad Replacement",
      },
      {
        "cost": 80,
        "description": "Rotate tires and check for uneven wear",
        "estimatedDuration": "45m",
        "serviceName": "Tire Rotation",
      },
      {
        "cost": 150,
        "description": "Replace car battery and perform charging system test",
        "estimatedDuration": "1.5h",
        "serviceName": "Battery Replacement",
      },
      {
        "cost": 200,
        "description":
            "Perform engine diagnostics and troubleshoot error codes",
        "estimatedDuration": "2h",
        "serviceName": "Engine Diagnostics",
      },
      {
        "cost": 60,
        "description": "Replace windshield wipers and check washer fluid",
        "estimatedDuration": "30m",
        "serviceName": "Wiper Replacement",
      },
      {
        "cost": 90,
        "description": "Replace air filter and check intake system",
        "estimatedDuration": "1h",
        "serviceName": "Air Filter Replacement",
      },
      {
        "cost": 180,
        "description": "Flush and replace transmission fluid",
        "estimatedDuration": "2.5h",
        "serviceName": "Transmission Fluid Service",
      },
      {
        "cost": 220,
        "description": "Replace spark plugs and inspect ignition system",
        "estimatedDuration": "3h",
        "serviceName": "Spark Plug Replacement",
      },
      {
        "cost": 300,
        "description": "Replace timing belt and inspect water pump",
        "estimatedDuration": "5h",
        "serviceName": "Timing Belt Replacement",
      },
    ];

    try {
      for (var task in dummyTasks) {
        await _firestore.collection("service_tasks").add({
          ...task,
          "status": "Pending", // default
          "createdAt": FieldValue.serverTimestamp(),
        });
      }
      print("✅ Dummy service tasks added successfully");
    } catch (e) {
      print("❌ Error adding dummy tasks: $e");
    }
  }

}
