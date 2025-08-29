import 'package:flutter/material.dart';
import '../models/mechanic.dart';
import '../services/attendance_service.dart';

class MechanicAttendanceSummary extends StatefulWidget {
  final Mechanic mechanic;
  final DateTime month;

  const MechanicAttendanceSummary({
    super.key,
    required this.mechanic,
    required this.month,
  });

  @override
  State<MechanicAttendanceSummary> createState() =>
      _MechanicAttendanceSummaryState();
}

class _MechanicAttendanceSummaryState extends State<MechanicAttendanceSummary> {
  final AttendanceService _adminService = AttendanceService();
  Map<String, dynamic>? _summaryData;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() => _loading = true);
    try {
      _summaryData = await _adminService.getMechanicAttendanceSummary(
        widget.mechanic.id,
        widget.month,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading summary: $e')));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_summaryData == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No attendance data available'),
        ),
      );
    }

    final presentDays = _summaryData!['presentDays'] ?? 0;
    final absentDays = _summaryData!['absentDays'] ?? 0;
    final totalWorkingDays = _summaryData!['totalWorkingDays'] ?? 0;
    final attendanceRate = _summaryData!['attendanceRate'] ?? 0;
    final totalHours = _summaryData!['totalHours'] ?? 0.0;
    final avgHours = _summaryData!['averageHoursPerDay'] ?? 0.0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with mechanic name
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).primaryColor.withOpacity(0.1),
                  child: Text(
                    widget.mechanic.name[0].toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.mechanic.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        widget.mechanic.email,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Attendance rate badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getAttendanceRateColor(attendanceRate),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${attendanceRate}%",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Statistics Grid
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    "Present",
                    "$presentDays/$totalWorkingDays",
                    Colors.green,
                    Icons.check_circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    "Absent",
                    "$absentDays",
                    Colors.red,
                    Icons.cancel,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    "Total Hours",
                    "${totalHours.toStringAsFixed(1)}h",
                    Colors.blue,
                    Icons.schedule,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    "Avg Hours/Day",
                    "${avgHours.toStringAsFixed(1)}h",
                    Colors.orange,
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getAttendanceRateColor(int rate) {
    if (rate >= 90) return Colors.green;
    if (rate >= 75) return Colors.orange;
    if (rate >= 50) return Colors.amber;
    return Colors.red;
  }
}
