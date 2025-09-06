import 'package:flutter/material.dart';
import 'package:greenstem_admin/screens/create_job_screen.dart';
import 'package:intl/intl.dart';
import '../models/job.dart';
import '../services/job_service.dart';
import '../services/mechanic_service.dart';
import '../widgets/job_card.dart';
import '../models/part_catalog.dart';
import '../services/part_catalog_service.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> with TickerProviderStateMixin {
  final JobService _jobService = JobService();
  final MechanicService _mechanicService = MechanicService();
  String _selectedStatus = 'all';
  String _searchQuery = '';
  Map<String, String> _mechanicNames = {}; // Cache for mechanic names
  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    List<String> parts = [];
    if (h > 0) parts.add('${h}h');
    if (m > 0) parts.add('${m}m');
    if (s > 0) parts.add('${s}s');
    if (parts.isEmpty) return '0s';
    return parts.join(' ');
  }

  late TabController _tabController;

  final PartCatalogService _partService = PartCatalogService();
  final _formKey = GlobalKey<FormState>();

  String _name = '';
  double _basePrice = 0.0;
  String _description = '';
  String _category = '';
  int _stockQuantity = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Trigger rebuild when tab changes
    });
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
        backgroundColor: const Color(0xFF3C5C39),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.work), text: 'Jobs'),
            Tab(icon: Icon(Icons.inventory), text: 'Parts'),
          ],
        ),
        actions: [
          if (_tabController.index == 0) ...[
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                _showFilterDialog();
              },
            ),
          ],
          if (_tabController.index == 1) ...[
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddPartDialog(context),
            ),
          ],
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Jobs Management
          _buildJobsTab(),

          // Tab 2: Part Catalog
          _buildPartsTab(),
        ],
      ),
      floatingActionButton:
          _tabController.index == 0
              ? FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateJobScreen(),
                    ),
                  );
                },
                backgroundColor: Colors.green[600],
                child: const Icon(Icons.add, color: Colors.white),
              )
              : null,
    );
  }

  Widget _buildPartsTab() {
    return StreamBuilder<List<PartCatalog>>(
      stream: _partService.getCatalogParts(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final parts = snapshot.data!;

        return ListView.builder(
          itemCount: parts.length,
          itemBuilder: (context, index) {
            final part = parts[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(part.name),
                subtitle: Text(
                  'Price: RM ${part.basePrice.toStringAsFixed(2)} | Stock: ${part.stockQuantity}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showEditPartDialog(context, part),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _confirmDelete(context, part),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddPartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add New Part'),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator:
                          (value) =>
                              value?.isEmpty ?? true
                                  ? 'Name is required'
                                  : null,
                      onSaved: (value) => _name = value ?? '',
                    ),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Base Price',
                      ),
                      keyboardType: TextInputType.number,
                      validator:
                          (value) =>
                              value?.isEmpty ?? true
                                  ? 'Price is required'
                                  : null,
                      onSaved:
                          (value) => _basePrice = double.parse(value ?? '0'),
                    ),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                      validator:
                          (value) =>
                              value?.isEmpty ?? true
                                  ? 'Description is required'
                                  : null,
                      onSaved: (value) => _description = value ?? '',
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Category'),
                      validator:
                          (value) =>
                              value?.isEmpty ?? true
                                  ? 'Category is required'
                                  : null,
                      onSaved: (value) => _category = value ?? '',
                    ),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Stock Quantity',
                      ),
                      keyboardType: TextInputType.number,
                      validator:
                          (value) =>
                              value?.isEmpty ?? true
                                  ? 'Stock quantity is required'
                                  : null,
                      onSaved:
                          (value) => _stockQuantity = int.parse(value ?? '0'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => _savePart(context),
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _showEditPartDialog(BuildContext context, PartCatalog part) {
    _name = part.name;
    _basePrice = part.basePrice;
    _stockQuantity = part.stockQuantity;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Part'),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      initialValue: part.name,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator:
                          (value) =>
                              value?.isEmpty ?? true
                                  ? 'Name is required'
                                  : null,
                      onSaved: (value) => _name = value ?? '',
                    ),
                    TextFormField(
                      initialValue: part.basePrice.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Base Price',
                      ),
                      keyboardType: TextInputType.number,
                      validator:
                          (value) =>
                              value?.isEmpty ?? true
                                  ? 'Price is required'
                                  : null,
                      onSaved:
                          (value) => _basePrice = double.parse(value ?? '0'),
                    ),
                    TextFormField(
                      initialValue: part.stockQuantity.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Stock Quantity',
                      ),
                      keyboardType: TextInputType.number,
                      validator:
                          (value) =>
                              value?.isEmpty ?? true
                                  ? 'Stock quantity is required'
                                  : null,
                      onSaved:
                          (value) => _stockQuantity = int.parse(value ?? '0'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => _updatePart(context, part.id),
                child: const Text('Update'),
              ),
            ],
          ),
    );
  }

  void _savePart(BuildContext context) {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      final part = PartCatalog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _name,
        basePrice: _basePrice,
        stockQuantity: _stockQuantity,
      );

      _partService
          .addCatalogPart(part)
          .then((_) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Part added successfully')),
            );
          })
          .catchError((error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error adding part: $error')),
            );
          });
    }
  }

  void _updatePart(BuildContext context, String partId) {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      final part = PartCatalog(
        id: partId,
        name: _name,
        basePrice: _basePrice,
        stockQuantity: _stockQuantity,
      );

      _partService
          .updateCatalogPart(part)
          .then((_) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Part updated successfully')),
            );
          })
          .catchError((error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error updating part: $error')),
            );
          });
    }
  }

  void _confirmDelete(BuildContext context, PartCatalog part) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Part'),
            content: Text('Are you sure you want to delete ${part.name}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  _partService
                      .deleteCatalogPart(part.id)
                      .then((_) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Part deleted successfully'),
                          ),
                        );
                      })
                      .catchError((error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error deleting part: $error'),
                          ),
                        );
                      });
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  Widget _buildJobsTab() {
    return Column(
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
                debugPrint('🔥 Jobs stream error: ${snapshot.error}');
                debugPrintStack(stackTrace: snapshot.stackTrace);
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.hasData) {
                debugPrint('✅ Jobs snapshot received: ${snapshot.data}');
              }

              final jobs = snapshot.data ?? [];
              final filteredJobs =
                  jobs.where((job) {
                    if (_searchQuery.isEmpty) return true;
                    return job.customerName.toLowerCase().contains(
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
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
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
      selectedColor: const Color(0xFF3C5C39).withOpacity(0.2),
      checkmarkColor: const Color(0xFF3C5C39),
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
                          '${displayJob.vehicleModel} - ${displayJob.vehiclePlate}',
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
                              _formatDuration(displayJob.estimatedDuration),
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
                              ...(() {
                                final nonEmptyNotes =
                                    displayJob.notes
                                        .where(
                                          (note) => note.text.trim().isNotEmpty,
                                        )
                                        .toList();
                                if (nonEmptyNotes.isEmpty) {
                                  return [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 16,
                                        bottom: 4,
                                      ),
                                      child: Text(
                                        'No notes available.',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ];
                                }
                                return nonEmptyNotes
                                    .map(
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
                                    )
                                    .toList();
                              })(),
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
                                        color: const Color(0xFF3C5C39),
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          CreateJobScreen(jobData: displayJob),
                                ),
                              );
                            },
                            child: const Text('Edit Job'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _showStatusUpdateDialog(job);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Update Status'),
                          ),
                        ),
                      ],
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
            backgroundColor: const Color(0xFF3C5C39),
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
