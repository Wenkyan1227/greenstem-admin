import 'package:cloud_firestore/cloud_firestore.dart';

class WorkingSchedule {
  final List<int> workingDays; // 1=Monday, 2=Tuesday, ..., 7=Sunday
  final DateTime effectiveFrom;

  const WorkingSchedule({
    required this.workingDays,
    required this.effectiveFrom,
  });

  // For now, hardcode Monday-Thursday (1-4) as working days
  // Later this can be fetched from admin settings
  static final WorkingSchedule defaultSchedule = WorkingSchedule(
    workingDays: const [1, 2, 3, 4], // Monday to Thursday
    effectiveFrom: WorkingSchedule._defaultDate,
  );

  static final DateTime _defaultDate = DateTime(2024, 1, 1);

  bool isWorkingDay(DateTime date) {
    return workingDays.contains(date.weekday);
  }

  factory WorkingSchedule.fromMap(Map<String, dynamic> map) {
    return WorkingSchedule(
      workingDays: List<int>.from(map['workingDays'] ?? [1, 2, 3, 4, 5]),
      effectiveFrom:
          (map['effectiveFrom'] as Timestamp?)?.toDate() ??
          DateTime(2024, 1, 1),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'workingDays': workingDays,
      'effectiveFrom': Timestamp.fromDate(effectiveFrom),
    };
  }
}
