import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/job.dart';

class JobService {
  final CollectionReference _jobsCollection = FirebaseFirestore.instance
      .collection('jobs');

  // Get all jobs
  Stream<List<Job>> getJobs() {
    return _jobsCollection
        .orderBy('createdDate', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Job.fromFirestore(doc)).toList();
        });
  }

  // Get jobs by status
  Stream<List<Job>> getJobsByStatus(String status) {
    return _jobsCollection
        .where('status', isEqualTo: status)
        .orderBy('createdDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Job.fromFirestore(doc)).toList();
        });
  }

  // Get jobs assigned to a specific mechanic
  Stream<List<Job>> getJobsByMechanic(String mechanicId) {
    return _jobsCollection
        .where('assignedTo', isEqualTo: mechanicId)
        .orderBy('createdDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Job.fromFirestore(doc)).toList();
        });
  }

  // Create a new job
  Future<void> createJob(Job job) async {
    await _jobsCollection.add(job.toFirestore());
  }

  // Update a job
  Future<void> updateJob(Job job) async {
    await _jobsCollection.doc(job.id).update(job.toFirestore());
  }

  // Delete a job
  Future<void> deleteJob(String jobId) async {
    await _jobsCollection.doc(jobId).delete();
  }

  // Get job by ID
  Future<Job?> getJobById(String jobId) async {
    DocumentSnapshot doc = await _jobsCollection.doc(jobId).get();
    if (doc.exists) {
      return Job.fromFirestore(doc);
    }
    return null;
  }

  // Update job status
  Future<void> updateJobStatus(String jobId, String status) async {
    await _jobsCollection.doc(jobId).update({
      'status': status,
      if (status == 'completed') 'completionDate': Timestamp.now(),
    });
  }

  // Assign job to mechanic
  Future<void> assignJobToMechanic(String jobId, String mechanicId) async {
    await _jobsCollection.doc(jobId).update({'assignedTo': mechanicId});
  }

  // Get job statistics
  Future<Map<String, int>> getJobStatistics() async {
    QuerySnapshot snapshot = await _jobsCollection.get();
    Map<String, int> stats = {
      'total': 0,
      'pending': 0,
      'in_progress': 0,
      'completed': 0,
      'cancelled': 0,
    };

    for (var doc in snapshot.docs) {
      Job job = Job.fromFirestore(doc);
      stats['total'] = (stats['total'] ?? 0) + 1;
      stats[job.status] = (stats[job.status] ?? 0) + 1;
    }

    return stats;
  }
}
