import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/working_schedule.dart';

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Save working schedule to Firestore
  Future<void> saveWorkingSchedule(WorkingSchedule schedule) async {
    await _firestore
        .collection('settings')
        .doc('workingSchedule')
        .set(schedule.toMap());
  }

  /// Get current working schedule
  Future<WorkingSchedule> getWorkingSchedule() async {
    try {
      final doc =
          await _firestore.collection('settings').doc('workingSchedule').get();

      if (doc.exists && doc.data() != null) {
        return WorkingSchedule.fromMap(doc.data()!);
      }
      return WorkingSchedule.defaultSchedule;
    } catch (e) {
      return WorkingSchedule.defaultSchedule;
    }
  }

  /// Get mechanic attendance summary for admin dashboard
  Future<Map<String, dynamic>> getMechanicAttendanceSummary(
    String mechanicId,
    DateTime month,
  ) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0);

    final snapshot =
        await _firestore
            .collection('attendance')
            .doc(mechanicId)
            .collection('days')
            .where('date', isGreaterThanOrEqualTo: start)
            .where('date', isLessThanOrEqualTo: end)
            .where('isWorkingDay', isEqualTo: true)
            .get();

    final records = snapshot.docs.map((doc) => doc.data()).toList();

    int presentDays = 0;
    int absentDays = 0;
    double totalHours = 0.0;

    for (var record in records) {
      final hours = (record['totalHours'] ?? 0.0).toDouble();
      totalHours += hours;

      if (hours > 0) {
        presentDays++;
      } else {
        absentDays++;
      }
    }

    final workingSchedule = await getWorkingSchedule();
    final totalWorkingDays = _countWorkingDaysInMonth(month, workingSchedule);

    return {
      'presentDays': presentDays,
      'absentDays': absentDays,
      'totalWorkingDays': totalWorkingDays,
      'totalHours': totalHours,
      'attendanceRate':
          totalWorkingDays > 0
              ? ((presentDays / totalWorkingDays) * 100).round()
              : 0,
      'averageHoursPerDay': presentDays > 0 ? totalHours / presentDays : 0.0,
    };
  }

  int _countWorkingDaysInMonth(DateTime month, WorkingSchedule schedule) {
    int count = 0;
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);

    DateTime current = firstDay;
    while (!current.isAfter(lastDay)) {
      if (schedule.isWorkingDay(current)) {
        count++;
      }
      current = current.add(const Duration(days: 1));
    }

    return count;
  }
}
