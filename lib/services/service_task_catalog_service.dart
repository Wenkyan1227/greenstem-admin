import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_task_catalog.dart';

class ServiceTaskCatalogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<ServiceTaskCatalog>> getAllServiceTasks() {
    return _firestore.collection("service_tasks").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return ServiceTaskCatalog.fromFirestoreData(doc.id, doc.data());
      }).toList();
    });
  }

  Future<void> addServiceTask(ServiceTaskCatalog task) async {
    try {
      await _firestore.collection("service_tasks").add(task.toFirestore());
      print("✅ Service task added successfully");
    } catch (e) {
      print("❌ Error adding service task: $e");
    }
  }
}
