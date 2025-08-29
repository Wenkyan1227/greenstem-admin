import 'package:flutter/material.dart';
import '../models/working_schedule.dart';
import '../services/attendance_service.dart';

class WorkingScheduleWidget extends StatefulWidget {
  const WorkingScheduleWidget({super.key});

  @override
  State<WorkingScheduleWidget> createState() => _WorkingScheduleWidgetState();
}

class _WorkingScheduleWidgetState extends State<WorkingScheduleWidget> {
  final AttendanceService _adminService = AttendanceService();
  WorkingSchedule? _currentSchedule;
  List<int> _selectedDays = [];
  bool _loading = false;
  bool _editing = false;

  final List<String> _dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentSchedule();
  }

  Future<void> _loadCurrentSchedule() async {
    setState(() => _loading = true);
    try {
      _currentSchedule = await _adminService.getWorkingSchedule();
      _selectedDays = List.from(_currentSchedule!.workingDays);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading schedule: $e')));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveSchedule() async {
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one working day')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final newSchedule = WorkingSchedule(
        workingDays: _selectedDays,
        effectiveFrom: DateTime.now(),
      );

      await _adminService.saveWorkingSchedule(newSchedule);
      _currentSchedule = newSchedule;

      setState(() => _editing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Working schedule updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving schedule: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _currentSchedule == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      "Working Schedule",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (!_editing)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      setState(() {
                        _editing = true;
                        _selectedDays = List.from(
                          _currentSchedule!.workingDays,
                        );
                      });
                    },
                  ),
              ],
            ),

            const SizedBox(height: 16),

            if (_editing) ...[
              // Edit Mode
              const Text(
                "Select working days:",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),

              Column(
                children: List.generate(7, (index) {
                  final dayNumber = index + 1;
                  final isSelected = _selectedDays.contains(dayNumber);

                  return CheckboxListTile(
                    title: Text(_dayNames[index]),
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedDays.add(dayNumber);
                        } else {
                          _selectedDays.remove(dayNumber);
                        }
                        _selectedDays.sort();
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  );
                }),
              ),

              const SizedBox(height: 16),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _loading
                            ? null
                            : () {
                              setState(() {
                                _editing = false;
                                _selectedDays = List.from(
                                  _currentSchedule!.workingDays,
                                );
                              });
                            },
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _loading ? null : _saveSchedule,
                    child:
                        _loading
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Text('Save'),
                  ),
                ],
              ),
            ] else ...[
              // View Mode
              Text(
                "Current working days:",
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                runSpacing: 4,
                children:
                    _currentSchedule!.workingDays.map((dayNumber) {
                      return Chip(
                        label: Text(
                          _dayNames[dayNumber - 1],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        backgroundColor: Theme.of(context).primaryColor,
                      );
                    }).toList(),
              ),

              const SizedBox(height: 12),

              Text(
                "Effective from: ${_formatDate(_currentSchedule!.effectiveFrom)}",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return "${date.day} ${months[date.month - 1]}, ${date.year}";
  }
}
