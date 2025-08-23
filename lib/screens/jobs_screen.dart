import 'package:flutter/material.dart';
import 'package:greenstem_admin/screens/create_job_screen.dart';
import 'package:intl/intl.dart';
import '../models/job.dart';
import '../models/mechanic.dart';
import '../services/job_service.dart';
import '../services/mechanic_service.dart';
import '../widgets/job_card.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  final JobService _jobService = JobService();
  final MechanicService _mechanicService = MechanicService();
  String _selectedStatus = 'all';
  String _searchQuery = '';
  Map<String, String> _mechanicNames = {}; // Cache for mechanic names

  @override
  void initState() {
    super.initState();
    _loadMechanicNames();
  }

  Future<void> _loadMechanicNames() async {
    try {
      final mechanics = await _mechanicService.getMechanics().first;
      final mechanicMap = <String, String>{};
      for (final mechanic in mechanics) {
        mechanicMap[mechanic.id] = mechanic.name;
      }
      setState(() {
        _mechanicNames = mechanicMap;
      });
    } catch (e) {
      print('Error loading mechanic names: $e');
    }
  }

  String _getMechanicName(String? mechanicId) {
    if (mechanicId == null || mechanicId.isEmpty) return 'Unassigned';
    return _mechanicNames[mechanicId] ?? 'Unknown Mechanic';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jobs'),
        backgroundColor: const Color(0xFF29A87A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search jobs...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Status Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('all', 'All'),
                const SizedBox(width: 8),
                _buildFilterChip('pending', 'Pending'),
                const SizedBox(width: 8),
                _buildFilterChip('in_progress', 'In Progress'),
                const SizedBox(width: 8),
                _buildFilterChip('completed', 'Completed'),
                const SizedBox(width: 8),
                _buildFilterChip('cancelled', 'Cancelled'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Jobs List
          Expanded(
            child: StreamBuilder<List<Job>>(
              stream:
                  _selectedStatus == 'all'
                      ? _jobService.getJobs()
                      : _jobService.getJobsByStatus(_selectedStatus),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final jobs = snapshot.data ?? [];
                final filteredJobs =
                    jobs.where((job) {
                      if (_searchQuery.isEmpty) return true;
                      return job.title.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ) ||
                          job.customerName.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ) ||
                          job.vehicleModel.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ) ||
                          job.vehiclePlate.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          );
                    }).toList();

                if (filteredJobs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.work_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No jobs found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredJobs.length,
                  itemBuilder: (context, index) {
                    final job = filteredJobs[index];
                    return JobCard(
                      job: job,
                      onTap: () {
                        _showJobDetails(job);
                      },
                      onStatusChanged: (newStatus) {
                        _updateJobStatus(job.id, newStatus);
                      },
                      getMechanicName: _getMechanicName,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateJobScreen()),
          );
        },
        backgroundColor: Colors.green[600],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterChip(String status, String label) {
    final isSelected = _selectedStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = status;
        });
      },
      selectedColor: Colors.green[100],
      checkmarkColor: Colors.green[700],
    );
  }

  void _showFilterDialog() {
    final statusOptions = [
      {'label': 'All Jobs', 'value': 'all'},
      {'label': 'Pending', 'value': 'pending'},
      {'label': 'In Progress', 'value': 'in_progress'},
      {'label': 'Completed', 'value': 'completed'},
      {'label': 'Cancelled', 'value': 'cancelled'},
    ];

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Filter Jobs'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  statusOptions.map((status) {
                    return ListTile(
                      title: Text(status['label']!),
                      leading: Radio<String>(
                        value: status['value']!,
                        groupValue: _selectedStatus,
                        onChanged: (value) {
                          try {
                            setState(() {
                              _selectedStatus = value!;
                            });
                            Navigator.pop(context);
                          } catch (e) {
                            // Print error in terminal
                            print(
                              'Error selecting filter for "${status['label']}": $e',
                            );
                          }
                        },
                      ),
                    );
                  }).toList(),
            ),
          ),
    );
  }

  void _showJobDetails(Job job) async {
    final detailedJob = await _jobService.getJobWithDetails(job.id);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              final displayJob = detailedJob ?? job; // fallback to basic job
              return Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ Use displayJob instead of job
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          displayJob.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow(
                              'Customer',
                              displayJob.customerName,
                            ),
                            _buildDetailRow(
                              'Contact',
                              displayJob.customerContact,
                            ),
                            _buildDetailRow(
                              'Vehicle',
                              '${displayJob.vehicleModel} - ${displayJob.vehiclePlate}',
                            ),
                            if (displayJob.assignedTo != null)
                              _buildDetailRow(
                                'Assigned To',
                                _getMechanicName(displayJob.assignedTo),
                              ),
                            _buildDetailRow(
                              'Status',
                              displayJob.status
                                  .replaceAll('_', ' ')
                                  .toUpperCase(),
                            ),
                            _buildDetailRow(
                              'Priority',
                              displayJob.priority.toUpperCase(),
                            ),
                            _buildDetailRow(
                              'Scheduled Date',
                              DateFormat(
                                'MMM dd, yyyy HH:mm',
                              ).format(displayJob.scheduledDate),
                            ),
                            _buildDetailRow(
                              'Estimated Duration',
                              '${displayJob.estimatedDuration} minutes',
                            ),
                            if (displayJob.completionDate != null)
                              _buildDetailRow(
                                'Completion Date',
                                DateFormat(
                                  'MMM dd, yyyy HH:mm',
                                ).format(displayJob.completionDate!),
                              ),
                            _buildDetailRow(
                              'Description',
                              displayJob.description,
                            ),

                            // ✅ Now notes & services will load
                            if (displayJob.notes.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Text(
                                'Notes:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...displayJob.notes.map(
                                (note) => Padding(
                                  padding: const EdgeInsets.only(
                                    left: 16,
                                    bottom: 4,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        note.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(note.text),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Created at: ${DateFormat('MMM dd, yyyy').format(note.createdAt)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],

                            if (displayJob.services.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Text(
                                'Services:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...displayJob.services.map(
                                (service) => Padding(
                                  padding: const EdgeInsets.only(
                                    left: 16,
                                    bottom: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        size: 16,
                                        color: Colors.green,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              service.serviceName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            if (service.mechanicName.isNotEmpty)
                                              Text(
                                                'Mechanic: ${service.mechanicName}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showStatusUpdateDialog(Job job) {
    String newStatus = job.status;
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Update Job Status'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: const Text('Pending'),
                      leading: Radio<String>(
                        value: 'pending',
                        groupValue: newStatus,
                        onChanged:
                            (value) => setDialogState(() => newStatus = value!),
                      ),
                      onTap: () => setDialogState(() => newStatus = 'pending'),
                    ),
                    ListTile(
                      title: const Text('In Progress'),
                      leading: Radio<String>(
                        value: 'in_progress',
                        groupValue: newStatus,
                        onChanged:
                            (value) =>
                                setDialogState(() => newStatus = 'in_progress'),
                      ),
                      onTap:
                          () => setDialogState(() => newStatus = 'in_progress'),
                    ),
                    ListTile(
                      title: const Text('Completed'),
                      leading: Radio<String>(
                        value: 'completed',
                        groupValue: newStatus,
                        onChanged:
                            (value) =>
                                setDialogState(() => newStatus = 'completed'),
                      ),
                      onTap:
                          () => setDialogState(() => newStatus = 'completed'),
                    ),
                    ListTile(
                      title: const Text('Cancelled'),
                      leading: Radio<String>(
                        value: 'cancelled',
                        groupValue: newStatus,
                        onChanged:
                            (value) =>
                                setDialogState(() => newStatus = 'cancelled'),
                      ),
                      onTap:
                          () => setDialogState(() => newStatus = 'cancelled'),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _updateJobStatus(job.id, newStatus);
                    },
                    child: const Text('Update'),
                  ),
                ],
              );
            },
          ),
    );
  }

  Future<void> _updateJobStatus(String jobId, String newStatus) async {
    try {
      await _jobService.updateJobStatus(jobId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Job status updated to ${newStatus.replaceAll('_', ' ')}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating job status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
