import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:greenstem_admin/models/note.dart';
import 'package:greenstem_admin/models/service_task.dart';
import '../models/job.dart';
import '../models/part.dart';

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

  // Generate next job ID with format J000X
  Future<String> _generateJobId() async {
    QuerySnapshot snapshot =
        await _jobsCollection
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

  // Create a new job with subcollections
  Future<void> createJob(
    Job job, {
    String generalNoteText = '',
    List<ServiceTask> services = const [],
    Map<String, String> serviceTaskNotes = const {},
    List<Part> parts = const [],
  }) async {
    // Generate custom job ID
    String jobId = await _generateJobId();

    // Create the job document with custom ID
    DocumentReference docRef = _jobsCollection.doc(jobId);

    await docRef.set(job.copyWith(id: jobId).toFirestore());
    print(job.estimatedDuration);

    final batch = FirebaseFirestore.instance.batch();

    // Always create a general note (even if empty)
    String generalNoteId = 'N${jobId}_GEN';
    Note generalNote = Note(
      id: generalNoteId,
      title: 'General Job Notes',
      text: generalNoteText,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      photoUrls: [],
      serviceTaskId: null,
    );
    batch.set(
      docRef.collection("notes").doc(generalNoteId),
      generalNote.toFirestore(),
    );

    // Add service tasks to subcollection with proper ID format ST000X_0X
    for (int i = 0; i < services.length; i++) {
      String taskId = 'ST${jobId}_${(i + 1).toString().padLeft(2, '0')}';

      final taskWithId = ServiceTask(
        id: taskId,
        mechanicId: services[i].mechanicId,
        mechanicName: services[i].mechanicName,
        serviceName: services[i].serviceName,
        mechanicPart: services[i].mechanicPart,
        description: services[i].description,
        serviceFee: services[i].serviceFee,
        estimatedDuration: services[i].estimatedDuration,
        actualDuration: services[i].actualDuration,
        startTime: services[i].startTime,
        endTime: services[i].endTime,
        status: services[i].status,
      );

      batch.set(
        docRef.collection("service_tasks").doc(taskId),
        taskWithId.toFirestore(),
      );

      // Create note for this service task (get text from serviceTaskNotes map)
      String serviceNoteId = 'N${jobId}_$taskId';
      String serviceNoteText = serviceTaskNotes[services[i].id] ?? '';

      Note serviceNote = Note(
        id: serviceNoteId,
        title: 'Service Task Notes - ${services[i].serviceName}',
        text: serviceNoteText,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        photoUrls: [],
        serviceTaskId: taskId,
      );

      batch.set(
        docRef.collection("notes").doc(serviceNoteId),
        serviceNote.toFirestore(),
      );
    }

    // Add parts to subcollection with proper ID format P000X_0X
    for (int i = 0; i < parts.length; i++) {
      String partId = 'P${jobId}_${(i + 1).toString().padLeft(2, '0')}';
      final matchingService = services.firstWhere(
        (s) => s.id == parts[i].taskId,
        orElse: () => services.first,
      );
      final partWithId = parts[i].copyWith(
        id: partId,
        taskId: matchingService.id, // set the correct service task ID
      );
      // final partWithId = parts[i].copyWith(id: partId);
      batch.set(docRef.collection("parts").doc(partId), partWithId.toMap());
    }

    await batch.commit();
  }

  // Update a job (main document only)
  Future<void> updateJob(Job job) async {
    // Only update the main job document, not subcollections
    Map<String, dynamic> jobData = job.toFirestore();
    // Remove subcollection data from main document
    jobData.remove('notes');
    jobData.remove('serviceTasks');

    await _jobsCollection.doc(job.id).update(jobData);
  }

  // Update job priority based on scheduled date and estimated duration
  Future<void> updateJobPriorities() async {
    try {
      final snapshot = await _jobsCollection.get();

      for (final doc in snapshot.docs) {
        final job = Job.fromFirestore(doc);

        // Skip completed or cancelled jobs
        if (job.status == 'completed' || job.status == 'cancelled') {
          continue;
        }

        final now = DateTime.now();
        final scheduledDateTime = job.scheduledDate;

        // Calculate remaining time
        final remainingTime = scheduledDateTime.difference(now);
        final remainingTimeWithBuffer = remainingTime - job.estimatedDuration;

        String newPriority;
        if (remainingTimeWithBuffer.inHours <= 2) {
          newPriority = 'urgent';
        } else if (remainingTimeWithBuffer.inHours <= 8) {
          newPriority = 'high';
        } else if (remainingTimeWithBuffer.inHours <= 24) {
          newPriority = 'medium';
        } else {
          newPriority = 'low';
        }

        // Only update if priority has changed
        if (job.priority != newPriority) {
          await _jobsCollection.doc(job.id).update({'priority': newPriority});
        }
      }
    } catch (e) {
      print('Error updating job priorities: $e');
      rethrow;
    }
  }

  // Update priority for a single job based on scheduled date
  String calculateJobPriority(
    DateTime scheduledDate,
    Duration estimatedDuration,
  ) {
    final now = DateTime.now();
    final remainingTime = scheduledDate.difference(now);
    final remainingTimeWithBuffer = remainingTime - estimatedDuration;

    if (remainingTimeWithBuffer.inHours <= 2) {
      return 'urgent';
    } else if (remainingTimeWithBuffer.inHours <= 8) {
      return 'high';
    } else if (remainingTimeWithBuffer.inHours <= 24) {
      return 'medium';
    } else {
      return 'low';
    }
  }

  // Update job with subcollections
  Future<void> updateJobWithSubcollections(
    Job job, {
    String? generalNoteText,
    List<ServiceTask>? services,
    Map<String, String>? serviceTaskNotes,
    List<Part>? parts,
  }) async {
    final batch = FirebaseFirestore.instance.batch();
    final jobRef = _jobsCollection.doc(job.id);

    // Update main job document
    Map<String, dynamic> jobData = job.toFirestore();
    jobData.remove('notes');
    jobData.remove('serviceTasks');
    batch.update(jobRef, jobData);

    // Update general note
    if (generalNoteText != null) {
      String generalNoteId = 'N${job.id}_GEN';

      Note generalNote = Note(
        id: generalNoteId,
        title: 'General Job Notes',
        text: generalNoteText,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        photoUrls: [],
        serviceTaskId: null,
      );
      batch.set(
        jobRef.collection('notes').doc(generalNoteId),
        generalNote.toFirestore(),
      );
    }

    // Update service tasks if provided
    if (services != null) {
      // First, delete existing service tasks and their notes
      final existingTasks = await jobRef.collection('service_tasks').get();
      for (final doc in existingTasks.docs) {
        batch.delete(doc.reference);
        // Delete corresponding note
        String noteId = 'N${job.id}_${doc.id}';
        batch.delete(jobRef.collection('notes').doc(noteId));
      }

      // Add new service tasks with proper ID format
      for (int i = 0; i < services.length; i++) {
        String taskId = 'ST${job.id}_${(i + 1).toString().padLeft(2, '0')}';
        final taskWithId = services[i].copyWith(id: taskId);
        batch.set(
          jobRef.collection('service_tasks').doc(taskId),
          taskWithId.toFirestore(),
        );

        // Create note for each service task
        String serviceNoteId = 'N${job.id}_$taskId';
        String serviceNoteText = '';

        // Find corresponding note text if provided
        if (serviceTaskNotes != null) {
          serviceNoteText = serviceTaskNotes[services[i].id] ?? '';
        }

        Note serviceNote = Note(
          id: serviceNoteId,
          title: 'Service Task Notes - ${services[i].serviceName}',
          text: serviceNoteText,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          photoUrls: [],
          serviceTaskId: taskId,
        );
        batch.set(
          jobRef.collection('notes').doc(serviceNoteId),
          serviceNote.toFirestore(),
        );
      }
    }

    // Update parts if provided
    if (parts != null) {
      // First, delete existing parts
      final existingParts = await jobRef.collection('parts').get();
      for (final doc in existingParts.docs) {
        batch.delete(doc.reference);
      }

      // Add new parts with proper ID format P000X_0X
      for (int i = 0; i < parts.length; i++) {
        String partId = 'P${job.id}_${(i + 1).toString().padLeft(2, '0')}';
        final partWithId = parts[i].copyWith(id: partId);
        batch.set(jobRef.collection('parts').doc(partId), partWithId.toMap());
      }
    }

    await batch.commit();
  }

  // Delete a job and its subcollections
  Future<void> deleteJob(String jobId) async {
    final batch = FirebaseFirestore.instance.batch();
    final jobRef = _jobsCollection.doc(jobId);

    // Delete notes subcollection
    final notes = await jobRef.collection('notes').get();
    for (final doc in notes.docs) {
      batch.delete(doc.reference);
    }

    // Delete service_tasks subcollection
    final tasks = await jobRef.collection('service_tasks').get();
    for (final doc in tasks.docs) {
      batch.delete(doc.reference);
    }

    // Delete parts subcollection
    final parts = await jobRef.collection('parts').get();
    for (final doc in parts.docs) {
      batch.delete(doc.reference);
    }

    // Delete main job document
    batch.delete(jobRef);

    await batch.commit();
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

  // Get job with subcollection details
  Future<Job?> getJobWithDetails(String jobId) async {
    DocumentSnapshot jobDoc = await _jobsCollection.doc(jobId).get();

    if (!jobDoc.exists) return null;

    // Fetch subcollections
    QuerySnapshot notesSnapshot =
        await jobDoc.reference.collection("notes").orderBy('createdAt').get();
    QuerySnapshot tasksSnapshot =
        await jobDoc.reference.collection("service_tasks").orderBy('id').get();

    // Convert into models
    List<Note> notes =
        notesSnapshot.docs
            .map(
              (d) => Note.fromFirestoreData(d.data() as Map<String, dynamic>),
            )
            .toList();

    List<ServiceTask> tasks =
        tasksSnapshot.docs
            .map(
              (d) => ServiceTask.fromFirestoreData(
                d.data() as Map<String, dynamic>,
              ),
            )
            .toList();

    // Return job with details
    return Job.fromFirestore(jobDoc).copyWith(notes: notes, services: tasks);
  }

  // Add individual note to job
  Future<void> addNoteToJob(
    String jobId,
    Note note, {
    String? serviceTaskId,
  }) async {
    String noteId =
        serviceTaskId != null ? 'N${jobId}_$serviceTaskId' : 'N${jobId}_GEN';

    final noteWithId = note.copyWith(id: noteId, serviceTaskId: serviceTaskId);

    await _jobsCollection
        .doc(jobId)
        .collection("notes")
        .doc(noteId)
        .set(noteWithId.toFirestore());
  }

  // Add individual service task to job
  Future<void> addServiceTaskToJob(
    String jobId,
    ServiceTask task, {
    String noteText = '',
  }) async {
    // Get current service tasks count to generate proper ID with format ST000X_0X
    final existingTasks =
        await _jobsCollection.doc(jobId).collection('service_tasks').get();

    int taskNumber = existingTasks.docs.length + 1;
    String taskId = 'ST${jobId}_${taskNumber.toString().padLeft(2, '0')}';

    final taskWithId = task.copyWith(id: taskId);

    final batch = FirebaseFirestore.instance.batch();

    // Add the service task
    batch.set(
      _jobsCollection.doc(jobId).collection("service_tasks").doc(taskId),
      taskWithId.toFirestore(),
    );

    // Always create a note for this service task with format N000X_ST000X_0X
    String noteId = 'N${jobId}_$taskId';
    final serviceNote = Note(
      id: noteId,
      title: 'Service Task Notes - ${task.serviceName}',
      text: noteText,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      photoUrls: [],
      serviceTaskId: taskId,
    );

    batch.set(
      _jobsCollection.doc(jobId).collection("notes").doc(noteId),
      serviceNote.toFirestore(),
    );

    await batch.commit();
  }

  // Update individual note
  Future<void> updateNote(String jobId, Note note) async {
    await _jobsCollection
        .doc(jobId)
        .collection("notes")
        .doc(note.id)
        .update(note.toFirestore());
  }

  // Update individual service task
  Future<void> updateServiceTask(String jobId, ServiceTask task) async {
    await _jobsCollection
        .doc(jobId)
        .collection("service_tasks")
        .doc(task.id)
        .update(task.toFirestore());
  }

  // Update service task with note
  Future<void> updateServiceTaskWithNote(
    String jobId,
    ServiceTask task,
    String noteText,
  ) async {
    final batch = FirebaseFirestore.instance.batch();

    // Update service task
    batch.update(
      _jobsCollection.doc(jobId).collection("service_tasks").doc(task.id),
      task.toFirestore(),
    );

    // Update corresponding note
    String noteId = 'N${jobId}_${task.id}';
    batch.update(_jobsCollection.doc(jobId).collection("notes").doc(noteId), {
      'text': noteText,
      'updatedAt': Timestamp.now(),
    });

    await batch.commit();
  }

  // Delete individual note
  Future<void> deleteNote(String jobId, String noteId) async {
    await _jobsCollection.doc(jobId).collection("notes").doc(noteId).delete();
  }

  // Delete individual service task and its note
  Future<void> deleteServiceTask(String jobId, String taskId) async {
    final batch = FirebaseFirestore.instance.batch();

    // Delete service task
    batch.delete(
      _jobsCollection.doc(jobId).collection("service_tasks").doc(taskId),
    );

    // Delete corresponding note
    String noteId = 'N${jobId}_$taskId';
    batch.delete(_jobsCollection.doc(jobId).collection("notes").doc(noteId));

    await batch.commit();
  }

  // Get notes for a job
  Stream<List<Note>> getJobNotes(String jobId) {
    return _jobsCollection
        .doc(jobId)
        .collection('notes')
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snap) =>
              snap.docs
                  .map((doc) => Note.fromFirestoreData(doc.data()))
                  .toList(),
        );
  }

  // Get service tasks for a job
  Stream<List<ServiceTask>> getJobServiceTasks(String jobId) {
    return _jobsCollection
        .doc(jobId)
        .collection('service_tasks')
        .orderBy('id')
        .snapshots()
        .map(
          (snap) =>
              snap.docs
                  .map((doc) => ServiceTask.fromFirestoreData(doc.data()))
                  .toList(),
        );
  }

  // Get general note for a job
  Future<Note?> getGeneralNote(String jobId) async {
    String noteId = 'N${jobId}_GEN';
    DocumentSnapshot doc =
        await _jobsCollection.doc(jobId).collection('notes').doc(noteId).get();

    if (doc.exists) {
      return Note.fromFirestoreData(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  // Get note for a specific service task
  Future<Note?> getServiceTaskNote(String jobId, String serviceTaskId) async {
    String noteId = 'N${jobId}_$serviceTaskId';
    DocumentSnapshot doc =
        await _jobsCollection.doc(jobId).collection('notes').doc(noteId).get();

    if (doc.exists) {
      return Note.fromFirestoreData(doc.data() as Map<String, dynamic>);
    }
    return null;
  }
}
