import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/job.dart';
import '../models/mechanic.dart';
import '../models/vehicle.dart';
import '../models/service_task_catalog.dart';
import '../services/job_service.dart';
import '../services/mechanic_service.dart';
import '../services/vehicle_service.dart';
import '../services/service_task_catalog_service.dart';
import '../widgets/text_formatter.dart';

class CreateJobScreen extends StatefulWidget {
  final Job? jobData; // Pass job data here for edit
  const CreateJobScreen({Key? key, this.jobData}) : super(key: key);

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final JobService _jobService = JobService();
  final MechanicService _mechanicService = MechanicService();
  final VehicleService _vehicleService = VehicleService();
  final ServiceTaskCatalogService _serviceTaskService =
      ServiceTaskCatalogService();

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _customerContactController = TextEditingController();
  final _vehiclePlateController = TextEditingController();
  final _notesController = TextEditingController();

  // Form variables
  String _selectedStatus = 'pending';
  String _selectedPriority = 'medium';
  String _selectedMechanic = '';
  String _selectedVehicleBrand = '';
  String _selectedVehicleModel = '';
  DateTime _scheduledDate = DateTime.now();
  TimeOfDay _scheduledTime = TimeOfDay.now();
  int _estimatedDuration = 60; // minutes

  // Service tasks
  final List<ServiceTask> _services = [];

  // Store notes for each service task
  final Map<String, String> _serviceTaskNotes = {};

  // Data lists
  List<Mechanic> _mechanics = [];
  List<VehicleBrand> _vehicleBrands = [];
  List<VehicleModel> _availableModels = [];

  // Service Task Catalog
  List<ServiceTaskCatalog> _serviceTaskCatalog = [];

  @override
  void initState() {
    super.initState();
    _loadData();

    if (widget.jobData != null) {
      // Wait for data to load before setting job data
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadJobDataForEdit();
      });
    }
  }

  void _loadJobDataForEdit() {
    final job = widget.jobData!;
    _titleController.text = job.title;
    _descriptionController.text = job.description;
    _customerNameController.text = job.customerName;
    _customerContactController.text = job.customerContact;
    _vehiclePlateController.text = job.vehiclePlate;
    _selectedStatus = job.status;
    _selectedPriority = job.priority;
    _scheduledDate = job.scheduledDate;
    _scheduledTime = TimeOfDay.fromDateTime(job.scheduledDate);
    _estimatedDuration = int.tryParse(job.estimatedDuration) ?? 60;

    // Load existing services - don't clear, just add them
    if (job.services.isNotEmpty) {
      _services.clear(); // Clear first to avoid duplicates
      _services.addAll(job.services);

      // Load existing notes for each service task
      _serviceTaskNotes.clear();
      for (final service in job.services) {
        final existingNote = job.notes.firstWhere(
          (note) => note.serviceTaskId == service.id,
          orElse:
              () => Note(
                id: '',
                title: '',
                text: '',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                photoUrls: [],
              ),
        );
        if (existingNote.id.isNotEmpty) {
          _serviceTaskNotes[service.id] = existingNote.text;
        }
      }
    }
  }

  void _loadVehicleDataForEdit() {
    final job = widget.jobData!;

    // Try to find the vehicle brand and model
    if (_vehicleBrands.isNotEmpty) {
      // Find the brand that contains the vehicle model
      for (final brand in _vehicleBrands) {
        final model = brand.models.firstWhere(
          (m) => m.name == job.vehicleModel,
          orElse: () => VehicleModel(id: '', name: '', imageUrl: ''),
        );
        if (model.id.isNotEmpty) {
          _selectedVehicleBrand = brand.id;
          _updateAvailableModels();
          _selectedVehicleModel = model.id;
          break;
        }
      }
    }
  }

  Future<void> _loadData() async {
    // Load mechanics
    _mechanicService.getAllMechanics().listen((mechanics) {
      setState(() {
        _mechanics = mechanics;

        // If we're editing a job, try to find and select the assigned mechanic
        if (widget.jobData != null && _mechanics.isNotEmpty) {
          final job = widget.jobData!;
          if (job.assignedTo != null) {
            final assignedMechanic = _mechanics.firstWhere(
              (m) => m.id == job.assignedTo,
              orElse: () => _mechanics.first,
            );
            _selectedMechanic = assignedMechanic.id;
          } else {
            _selectedMechanic = _mechanics.first.id;
          }
          // Load job data after mechanics are loaded
          _loadJobDataForEdit();
        } else if (_mechanics.isNotEmpty && _selectedMechanic.isEmpty) {
          _selectedMechanic = _mechanics.first.id;
        }
      });
    });

    // Load vehicle brands
    _vehicleService.getVehicleBrands().listen((brands) {
      setState(() {
        _vehicleBrands = brands;
        if (_vehicleBrands.isNotEmpty && _selectedVehicleBrand.isEmpty) {
          _selectedVehicleBrand = _vehicleBrands.first.id;
          _updateAvailableModels();
        }

        // If we're editing a job, load vehicle data after brands are loaded
        if (widget.jobData != null && _vehicleBrands.isNotEmpty) {
          _loadVehicleDataForEdit();
        }
      });
    });

    // Load service task catalog
    _serviceTaskService.getAllServiceTasks().listen((tasks) {
      setState(() {
        _serviceTaskCatalog = tasks;
      });
    });
  }

  void _updateAvailableModels() {
    if (_selectedVehicleBrand.isNotEmpty) {
      final selectedBrand = _vehicleBrands.firstWhere(
        (brand) => brand.id == _selectedVehicleBrand,
      );
      setState(() {
        _availableModels = selectedBrand.models;
        if (_availableModels.isNotEmpty) {
          _selectedVehicleModel = _availableModels.first.id;
        }
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _scheduledDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _scheduledTime.hour,
          _scheduledTime.minute,
        );
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _scheduledTime,
    );
    if (picked != null) {
      setState(() {
        _scheduledTime = picked;
        _scheduledDate = DateTime(
          _scheduledDate.year,
          _scheduledDate.month,
          _scheduledDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _showAddServiceTaskDialog() async {
    if (_selectedMechanic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a mechanic first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final mechanic = _mechanics.firstWhere((m) => m.id == _selectedMechanic);

    String selectedServiceTaskId = '';
    String serviceName = '';
    String description = '';
    double cost = 0.0;
    String estimatedDuration = '';
    String notes = '';

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Add Service Task'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Service Task Selection
                    DropdownButtonFormField<String>(
                      value:
                          selectedServiceTaskId.isNotEmpty
                              ? selectedServiceTaskId
                              : null,
                      decoration: const InputDecoration(
                        labelText: 'Select Service Task *',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        ..._serviceTaskCatalog.map((task) {
                          return DropdownMenuItem(
                            value: task.id,
                            child: Text(task.serviceName),
                          );
                        }).toList(),
                        const DropdownMenuItem(
                          value: 'others',
                          child: Text('Others'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedServiceTaskId = value ?? '';
                          if (value != null && value != 'others') {
                            final task = _serviceTaskCatalog.firstWhere(
                              (t) => t.id == value,
                            );
                            serviceName = task.serviceName;
                            description = task.description;
                            cost = task.cost;
                            estimatedDuration = task.estimatedDuration;
                          } else if (value == 'others') {
                            serviceName = '';
                            description = '';
                            cost = 0.0;
                            estimatedDuration = '';
                          }
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a service task';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Show details for existing service tasks
                    if (selectedServiceTaskId.isNotEmpty &&
                        selectedServiceTaskId != 'others') ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Service Details:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Name: $serviceName'),
                            if (description.isNotEmpty)
                              Text('Description: $description'),
                            Text('Cost: \$${cost.toStringAsFixed(2)}'),
                            Text('Duration: $estimatedDuration'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Service Name (for "Others" only)
                    if (selectedServiceTaskId == 'others') ...[
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Service Name *',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => serviceName = value,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter service name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Description (for "Others" only)
                    if (selectedServiceTaskId == 'others') ...[
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                        onChanged: (value) => description = value,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Cost (for "Others" only)
                    if (selectedServiceTaskId == 'others') ...[
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Cost',
                          border: OutlineInputBorder(),
                          prefixText: '\$',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged:
                            (value) => cost = double.tryParse(value) ?? 0.0,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Estimated Duration (for "Others" only)
                    if (selectedServiceTaskId == 'others') ...[
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Estimated Duration (e.g., 1h 30m)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => estimatedDuration = value,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Notes for this service task
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Notes for this service task',
                        border: OutlineInputBorder(),
                        hintText: 'Add specific notes for this service...',
                      ),
                      maxLines: 3,
                      onChanged: (value) => notes = value,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedServiceTaskId.isNotEmpty &&
                        serviceName.isNotEmpty) {
                      // Create the service task (don't save to database yet)
                      final serviceTask = ServiceTask(
                        id: 'ST${DateTime.now().millisecondsSinceEpoch}',
                        mechanicId: mechanic.id,
                        mechanicName: mechanic.name,
                        serviceName: serviceName,
                        description: description,
                        cost: cost,
                        estimatedDuration: estimatedDuration,
                      );

                      // Add to services list
                      this.setState(() {
                        _services.add(serviceTask);
                        _serviceTaskNotes[serviceTask.id] = notes;
                      });

                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Service task added successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill in all required fields'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _removeServiceTask(int index) {
    final serviceToRemove = _services[index];
    setState(() {
      _services.removeAt(index);
      _serviceTaskNotes.remove(serviceToRemove.id);
    });
  }

  void _editServiceTask(int index) {
    final service = _services[index];

    // Show the same dialog but pre-filled with existing data
    _showEditServiceTaskDialog(index, service);
  }

  Future<void> _showEditServiceTaskDialog(
    int index,
    ServiceTask service,
  ) async {
    String serviceName = service.serviceName;
    String description = service.description;
    double cost = service.cost;
    String estimatedDuration = service.estimatedDuration;
    String notes = _serviceTaskNotes[service.id] ?? '';

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Edit Service Task'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Show current service details
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Service Details:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Name: $serviceName'),
                          if (description.isNotEmpty)
                            Text('Description: $description'),
                          Text('Cost: \$${cost.toStringAsFixed(2)}'),
                          Text('Duration: $estimatedDuration'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Notes for this service task
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Notes for this service task',
                        border: OutlineInputBorder(),
                        hintText: 'Add specific notes for this service...',
                      ),
                      maxLines: 3,
                      controller: TextEditingController(text: notes),
                      onChanged: (value) => notes = value,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Update the notes only
                    this.setState(() {
                      _serviceTaskNotes[service.id] = notes;
                    });

                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Service task notes updated successfully!',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text('Update Notes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveJob() async {
    if (_formKey.currentState!.validate()) {
      try {
        final selectedMechanic = _mechanics.firstWhere(
          (mechanic) => mechanic.id == _selectedMechanic,
        );

        final selectedModel = _availableModels.firstWhere(
          (model) => model.id == _selectedVehicleModel,
        );

        // Save new service tasks to database first
        for (final service in _services) {
          // Check if this is a new service task (starts with 'ST' and has timestamp)
          if (service.id.startsWith('ST') && service.id.length > 20) {
            // This is a new service task, save it to the catalog
            final newServiceTask = ServiceTaskCatalog(
              id: '',
              serviceName: service.serviceName,
              description: service.description,
              cost: service.cost,
              estimatedDuration: service.estimatedDuration,
            );

            try {
              await _serviceTaskService.addServiceTask(newServiceTask);
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error saving service task to catalog: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return;
            }
          }
        }

        // Creating the notes list
        List<Note> notes = [];

        // Add general job notes if provided
        if (_notesController.text.isNotEmpty) {
          notes.add(
            Note(
              id: 'N0001_${DateTime.now().millisecondsSinceEpoch}',
              title: 'General Job Notes',
              text: _notesController.text,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              photoUrls: [],
            ),
          );
        }

        // Add notes for each service task
        for (final service in _services) {
          if (_serviceTaskNotes[service.id]?.isNotEmpty == true) {
            notes.add(
              Note(
                id: 'N${DateTime.now().millisecondsSinceEpoch}',
                title: 'Service Task Notes',
                text: _serviceTaskNotes[service.id]!,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                photoUrls: [],
                serviceTaskId: service.id,
              ),
            );
          }
        }

        if (widget.jobData == null) {
          // Create new job
          final job = Job(
            id: '', // Will be set by Firestore
            title: _titleController.text,
            description: _descriptionController.text,
            customerName: _customerNameController.text,
            customerContact: _customerContactController.text,
            vehicleModel: selectedModel.name,
            vehiclePlate: _vehiclePlateController.text,
            priority: _selectedPriority,
            status: _selectedStatus,
            services: List.from(_services),
            scheduledDate: _scheduledDate,
            createdDate: DateTime.now(),
            imageUrl: selectedModel.imageUrl,
            estimatedDuration: _estimatedDuration.toString(),
            notes: notes,
            assignedTo: selectedMechanic.id,
          );

          await _jobService.createJob(job);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Job created successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          }
        } else {
          // Update existing job
          final updatedJob = widget.jobData!.copyWith(
            title: _titleController.text,
            description: _descriptionController.text,
            customerName: _customerNameController.text,
            customerContact: _customerContactController.text,
            vehicleModel: selectedModel.name,
            vehiclePlate: _vehiclePlateController.text,
            priority: _selectedPriority,
            status: _selectedStatus,
            services: List.from(_services),
            scheduledDate: _scheduledDate,
            estimatedDuration: _estimatedDuration.toString(),
            notes: notes,
            assignedTo: selectedMechanic.id,
          );

          await _jobService.updateJob(updatedJob);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Job updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving job: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.jobData == null ? 'Create New Job' : 'Edit Job'),
        backgroundColor: const Color(0xFF29A87A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information
              _buildSectionTitle('Basic Information'),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Job Title *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a job title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Customer Information
              _buildSectionTitle('Customer Information'),
              TextFormField(
                controller: _customerNameController,
                decoration: const InputDecoration(
                  labelText: 'Customer Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter customer name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _customerContactController,
                decoration: const InputDecoration(
                  labelText: 'Customer Contact *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter customer contact';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Vehicle Information
              _buildSectionTitle('Vehicle Information'),
              DropdownButtonFormField<String>(
                value:
                    _selectedVehicleBrand.isNotEmpty
                        ? _selectedVehicleBrand
                        : null,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Brand *',
                  border: OutlineInputBorder(),
                ),
                items:
                    _vehicleBrands.map((brand) {
                      return DropdownMenuItem(
                        value: brand.id,
                        child: Text(brand.name),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedVehicleBrand = value ?? '';
                    _updateAvailableModels();
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a vehicle brand';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value:
                    _selectedVehicleModel.isNotEmpty
                        ? _selectedVehicleModel
                        : null,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Model *',
                  border: OutlineInputBorder(),
                ),
                items:
                    _availableModels.map((model) {
                      return DropdownMenuItem(
                        value: model.id,
                        child: Text(model.name),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedVehicleModel = value ?? '';
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a vehicle model';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _vehiclePlateController,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [UpperCaseTextFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Vehicle Plate *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter vehicle plate';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Job Details
              _buildSectionTitle('Job Details'),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(
                    value: 'in_progress',
                    child: Text('In Progress'),
                  ),
                  DropdownMenuItem(
                    value: 'completed',
                    child: Text('Completed'),
                  ),
                  DropdownMenuItem(
                    value: 'cancelled',
                    child: Text('Cancelled'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value ?? 'pending';
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Low')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'high', child: Text('High')),
                  DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedPriority = value ?? 'medium';
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedMechanic.isNotEmpty ? _selectedMechanic : null,
                decoration: const InputDecoration(
                  labelText: 'Assign To *',
                  border: OutlineInputBorder(),
                ),
                items:
                    _mechanics.map((mechanic) {
                      return DropdownMenuItem(
                        value: mechanic.id,
                        child: Text(mechanic.name),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMechanic = value ?? '';
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a mechanic';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Scheduled Date'),
                      subtitle: Text(
                        DateFormat('MMM dd, yyyy').format(_scheduledDate),
                      ),
                      onTap: _selectDate,
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('Scheduled Time'),
                      subtitle: Text(_scheduledTime.format(context)),
                      onTap: _selectTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Estimated Duration: '),
                  Expanded(
                    child: Slider(
                      value: _estimatedDuration.toDouble(),
                      min: 15,
                      max: 480,
                      divisions: 31,
                      label: '${_estimatedDuration} minutes',
                      onChanged: (value) {
                        setState(() {
                          _estimatedDuration = value.round();
                        });
                      },
                    ),
                  ),
                  Text('${_estimatedDuration} min'),
                ],
              ),
              const SizedBox(height: 24),

              // Service Tasks
              _buildSectionTitle('Service Tasks'),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showAddServiceTaskDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Service Task'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF29A87A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              if (_services.isNotEmpty) ...[
                const Text(
                  'Added Services:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...(_services.asMap().entries.map((entry) {
                  final index = entry.key;
                  final service = entry.value;
                  final serviceNotes = _serviceTaskNotes[service.id] ?? '';
                  return Card(
                    child: ListTile(
                      title: Text(service.serviceName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (service.description.isNotEmpty)
                            Text('Description: ${service.description}'),
                          Text('Cost: \$${service.cost.toStringAsFixed(2)}'),
                          Text('Duration: ${service.estimatedDuration}'),
                          if (serviceNotes.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Notes:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  Text(
                                    serviceNotes,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editServiceTask(index),
                            tooltip: 'Edit Service',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeServiceTask(index),
                            tooltip: 'Remove Service',
                          ),
                        ],
                      ),
                    ),
                  );
                })),
              ],

              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'General Job Notes',
                  border: OutlineInputBorder(),
                  hintText: 'Add general notes about the job...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveJob,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF29A87A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    widget.jobData == null ? 'Create Job' : 'Update Job',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF29A87A),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _customerNameController.dispose();
    _customerContactController.dispose();
    _vehiclePlateController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
