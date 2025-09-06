import 'package:flutter/material.dart';
import 'package:greenstem_admin/models/note.dart';
import 'package:greenstem_admin/models/service_task.dart';
import 'package:intl/intl.dart';
import '../models/job.dart';
import '../models/mechanic.dart';
import '../models/vehicle.dart';
import '../models/service_task_catalog.dart';
import '../models/part.dart';
import '../services/job_service.dart';
import '../services/mechanic_service.dart';
import '../services/vehicle_service.dart';
import '../services/service_task_catalog_service.dart';
import '../widgets/text_formatter.dart';
import '../widgets/job_parts_selector.dart';
import '../services/customer_service.dart';
import '../models/customer.dart';

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
  final CustomerService _customerService = CustomerService();

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _customerContactController = TextEditingController();
  final _vehiclePlateController = TextEditingController();
  final _notesController = TextEditingController();

  // Form variables
  String _selectedStatus = 'pending';
  String _selectedPriority = 'not set yet';
  String _selectedMechanic = '';
  String _selectedVehicleBrand = '';
  String _selectedVehicleModel = '';
  DateTime _scheduledDate = DateTime.now();
  TimeOfDay _scheduledTime = TimeOfDay.now();
  Duration _estimatedDuration = Duration.zero;
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

  // Recalculate job estimated duration from all service tasks
  void _recalculateJobEstimatedDuration() {
    Duration total = Duration.zero;
    for (final service in _services) {
      if (service.estimatedDuration != null) {
        total += service.estimatedDuration!;
      }
    }
    setState(() {
      _estimatedDuration = total;
    });
  }

  void _examineJobPriority() {
    // Combine _scheduledDate (DateTime) and _scheduledTime (TimeOfDay) into a single DateTime object
    DateTime scheduledDateTime = DateTime(
      _scheduledDate.year,
      _scheduledDate.month,
      _scheduledDate.day,
      _scheduledTime.hour,
      _scheduledTime.minute,
    );

    Duration remainingTime = scheduledDateTime.difference(DateTime.now());
    Duration remainingWithBuffer = remainingTime - _estimatedDuration;
    String _priority;

    if (remainingWithBuffer.inHours <= 2) {
      _priority = 'urgent';
    } else if (remainingWithBuffer.inHours <= 8) {
      _priority = 'high';
    } else if (remainingWithBuffer.inHours <= 24) {
      _priority = 'medium';
    } else {
      _priority = 'low';
    }

    // Update the priority
    setState(() {
      _selectedPriority = _priority;
    });
  }

  List<Part> _selectedParts = [];

  // Service tasks
  final List<ServiceTask> _services = [];

  // Store notes for each service task using the original service task ID
  final Map<String, String> _serviceTaskNotes = {};

  // Data lists
  List<Mechanic> _mechanics = [];
  List<VehicleBrand> _vehicleBrands = [];
  List<VehicleModel> _availableModels = [];
  List<Customer> _customers = [];
  String _selectedVehiclePlate = '';
  // List<String> _vehiclePlates = [];
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

  void _loadJobDataForEdit() async {
    final job = widget.jobData!;
    _descriptionController.text = job.description;
    _customerNameController.text = job.customerName;
    _customerContactController.text = job.customerContact;
    _vehiclePlateController.text = job.vehiclePlate;
    _selectedStatus = job.status;
    _selectedPriority = job.priority;
    _scheduledDate = job.scheduledDate;
    _scheduledTime = TimeOfDay.fromDateTime(job.scheduledDate);
    _estimatedDuration = job.estimatedDuration;

    // Load the job with full details including notes and service tasks
    Job? jobWithDetails = await _jobService.getJobWithDetails(job.id);

    if (jobWithDetails != null) {
      // Load general note
      final generalNote = jobWithDetails.notes.firstWhere(
        (note) => note.serviceTaskId == null,
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
      if (generalNote.id.isNotEmpty) {
        _notesController.text = generalNote.text;
      }

      // Load existing services
      if (jobWithDetails.services.isNotEmpty) {
        _services.clear();
        _services.addAll(jobWithDetails.services);

        // Load existing notes for each service task
        _serviceTaskNotes.clear();
        for (final service in jobWithDetails.services) {
          final existingNote = jobWithDetails.notes.firstWhere(
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

      // Load existing parts
      final parts = await Job.loadParts(job.id);
      setState(() {
        _selectedParts = parts;
      });
    }

    setState(() {});
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

    // Load customers
    _customerService.getCustomers().listen((customers) {
      setState(() {
        _customers = customers;
        if (_customers.isNotEmpty && _selectedVehiclePlate.isEmpty) {
          _selectedVehiclePlate = _customers.first.vehiclePlate;
          _updateVehicleAndCustomerInfo();
        }
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

  void _updateVehicleAndCustomerInfo() {
    setState(() {
      if (_selectedVehiclePlate == 'others') {
        // If 'Others' is selected, clear all fields
        _vehiclePlateController.clear();
        _selectedVehicleBrand = '';
        _selectedVehicleModel = '';
        _customerNameController.clear();
        _customerContactController.clear();
      } else {
        // If a specific vehicle plate is selected, find the corresponding data
        final customerData = _customers.firstWhere(
          (customer) => customer.vehiclePlate == _selectedVehiclePlate,
        );

        // Pre-fill the vehicle information
        _vehiclePlateController.text = customerData.vehiclePlate;
        _selectedVehicleBrand = customerData.vehicleBrand;
        _updateAvailableModels();
        _selectedVehicleModel = customerData.vehicleModel;

        // Pre-fill the customer information
        _customerNameController.text = customerData.customerName;
        _customerContactController.text = customerData.customerContact;
      }
    });
  }

  Future<void> _selectDate() async {
    // Show date picker
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      // Create the DateTime object combining picked date and current time
      DateTime proposedDateTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _scheduledTime.hour,
        _scheduledTime.minute,
      );

      // Check if there is enough time for the estimated job duration
      if (DateTime.now().add(_estimatedDuration).isBefore(proposedDateTime)) {
        // If there's enough time, update _scheduledDate and call _examineJobPriority
        setState(() {
          _scheduledDate = proposedDateTime;
        });
        _examineJobPriority();
      } else {
        // Show a message if there's not enough time
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Invalid Selection'),
                content: const Text(
                  'Not enough time for the estimated duration. Please choose a later date.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close the dialog
                      _selectDate(); // Let the user repick the date
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
    }
  }

  Future<void> _selectTime() async {
    // Show time picker
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _scheduledTime,
    );

    if (picked != null) {
      // Create the DateTime object combining current date and selected time
      DateTime proposedDateTime = DateTime(
        _scheduledDate.year,
        _scheduledDate.month,
        _scheduledDate.day,
        picked.hour,
        picked.minute,
      );

      // Check if there is enough time for the estimated job duration
      if (DateTime.now().add(_estimatedDuration).isBefore(proposedDateTime)) {
        // If there's enough time, update _scheduledTime and call _examineJobPriority
        setState(() {
          _scheduledTime = picked;
          _scheduledDate = proposedDateTime;
        });
        _examineJobPriority();
      } else {
        // Show a message if there's not enough time
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Invalid Selection'),
                content: const Text(
                  'Not enough time for the estimated duration. Please choose a later date.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close the dialog
                      _selectTime(); // Let the user repick the date
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
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
    Duration estimatedDuration = Duration.zero;
    String notes = '';
    final GlobalKey<FormState> _dialogFormKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Add Service Task'),
              content: SingleChildScrollView(
                child: Form(
                  key: _dialogFormKey,
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
                              estimatedDuration = Duration.zero;
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
                              Text('Cost: ${cost.toStringAsFixed(2)}'),
                              Text(
                                'Duration: ${_formatDuration(estimatedDuration)}',
                              ),
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
                          validator: (value) {
                            // Check if the input value is a valid integer
                            if (value == null || value.isEmpty) {
                              return 'Please enter the cost';
                            }
                            // Try to parse the value as an integer
                            final parsedValue = int.tryParse(value);
                            if (parsedValue == null) {
                              return 'Please enter a valid number'; // Error message for non-integer input
                            }
                            return null; // No error
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Estimated Duration (for "Others" only)
                      if (selectedServiceTaskId == 'others') ...[
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Estimated Duration (in minutes)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged:
                              (value) =>
                                  estimatedDuration = Duration(
                                    seconds: int.tryParse(value * 60) ?? 0,
                                  ),
                          validator: (value) {
                            // Check if the input value is a valid integer
                            if (value == null || value.isEmpty) {
                              return 'Please enter the duration';
                            }
                            // Try to parse the value as an integer
                            final parsedValue = int.tryParse(value);
                            if (parsedValue == null) {
                              return 'Please enter a valid number'; // Error message for non-integer input
                            }
                            return null; // No error
                          },
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
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_dialogFormKey.currentState?.validate() ?? false) {
                      if (selectedServiceTaskId.isNotEmpty &&
                          serviceName.isNotEmpty) {
                        // Create the service task (don't save to database yet)
                        // Use a temporary unique ID that will be replaced in JobService
                        final serviceTask = ServiceTask(
                          id: 'TEMP_${DateTime.now().millisecondsSinceEpoch}',
                          mechanicId: mechanic.id,
                          mechanicName: mechanic.name,
                          serviceName: serviceName,
                          description: description,
                          cost: cost,
                          estimatedDuration: estimatedDuration,
                        );

                        // Add to services list and store the note using the temporary ID
                        this.setState(() {
                          _services.add(serviceTask);
                          _serviceTaskNotes[serviceTask.id] = notes;
                        });

                        _recalculateJobEstimatedDuration();

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
    _recalculateJobEstimatedDuration();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Service task removed'),
        backgroundColor: Colors.red,
      ),
    );
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
    Duration estimatedDuration = service.estimatedDuration!;
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
                          Text('Cost: ${cost.toStringAsFixed(2)}'),
                          Text(
                            'Duration: ${_formatDuration(estimatedDuration)}',
                          ),
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

        final finalVehiclePlate =
            _selectedVehiclePlate == 'others'
                ? _vehiclePlateController.text
                : _selectedVehiclePlate;

        if (_selectedVehiclePlate == "others") {
          final newCustomer = Customer(
            id: '',
            customerName: _customerNameController.text,
            customerContact: _customerContactController.text,
            vehiclePlate: finalVehiclePlate,
            vehicleModel: _selectedVehicleModel,
            vehicleBrand: _selectedVehicleBrand,
            createdAt: DateTime.now(),
          );
          try {
            await _customerService.createCustomer(newCustomer);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error saving Customer to catalog: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
        }

        // Save new service tasks to database first (if they're new "Others" entries)
        for (final service in _services) {
          // Check if this is a new service task that should be added to catalog
          if (service.id.startsWith('TEMP_')) {
            // This is a new service task, save it to the catalog
            final newServiceTask = ServiceTaskCatalog(
              id: '',
              serviceName: service.serviceName,
              description: service.description,
              cost: service.cost,
              estimatedDuration: service.estimatedDuration!,
              createdAt: DateTime.now(),
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

        if (widget.jobData == null) {
          // Create new job
          final job = Job(
            id: '', // Firestore sets this
            description: _descriptionController.text,
            customerName: _customerNameController.text,
            customerContact: _customerContactController.text,
            vehicleModel: selectedModel.name,
            vehiclePlate: finalVehiclePlate,
            priority: _selectedPriority,
            status: _selectedStatus,
            scheduledDate: _scheduledDate,
            createdDate: DateTime.now(),
            imageUrl: selectedModel.imageUrl,
            estimatedDuration: _estimatedDuration,
            assignedTo: selectedMechanic.id,

            // Exclude notes & services from main doc - will be stored in subcollections
            notes: [],
            services: [],
          );

          // Use the improved createJob method
          await _jobService.createJob(
            job,
            generalNoteText: _notesController.text,
            services: _services,
            serviceTaskNotes: _serviceTaskNotes,
            parts: _selectedParts,
          );

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
          // Update existing job using the new subcollection method
          final updatedJob = widget.jobData!.copyWith(
            title: _titleController.text,
            description: _descriptionController.text,
            customerName: _customerNameController.text,
            customerContact: _customerContactController.text,
            vehicleModel: selectedModel.name,
            vehiclePlate: finalVehiclePlate,
            priority: _selectedPriority,
            status: _selectedStatus,
            scheduledDate: _scheduledDate,
            estimatedDuration: _estimatedDuration,
            assignedTo: selectedMechanic.id,
          );

          // Use updateJobWithSubcollections to handle notes, service tasks and parts
          await _jobService.updateJobWithSubcollections(
            updatedJob,
            generalNoteText: _notesController.text,
            services: _services,
            serviceTaskNotes: _serviceTaskNotes,
            parts: _selectedParts,
          );

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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.jobData == null ? 'Create New Job' : 'Edit Job'),
        backgroundColor: const Color(0xFF3C5C39),
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
              // Vehicle Information
              _buildSectionTitle('Vehicle Information'),
              DropdownButtonFormField<String>(
                value:
                    (() {
                      final plateList =
                          _customers.map((c) => c.vehiclePlate).toList();
                      plateList.add('others');
                      if (_selectedVehiclePlate.isNotEmpty &&
                          plateList.contains(_selectedVehiclePlate)) {
                        return _selectedVehiclePlate;
                      }
                      return null;
                    })(),
                decoration: const InputDecoration(
                  labelText: 'Vehicle Plate *',
                  border: OutlineInputBorder(),
                ),
                items: [
                  ..._customers.map((customer) {
                    return DropdownMenuItem(
                      value: customer.vehiclePlate,
                      child: Text(customer.vehiclePlate),
                    );
                  }).toList(),
                  const DropdownMenuItem(
                    value: 'others',
                    child: Text('Others'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedVehiclePlate = value ?? '';
                    _updateVehicleAndCustomerInfo();
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a vehicle plate';
                  }
                  return null;
                },
              ),
              // if 'Others' is selected.
              if (_selectedVehiclePlate == 'others') ...[
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
              ],

              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value:
                    (() {
                      final brandList =
                          _vehicleBrands.map((b) => b.id).toList();
                      if (_selectedVehicleBrand.isNotEmpty &&
                          brandList.contains(_selectedVehicleBrand)) {
                        return _selectedVehicleBrand;
                      }
                      return null;
                    })(),
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
                    (() {
                      final modelList =
                          _availableModels.map((m) => m.id).toList();
                      if (_selectedVehicleModel.isNotEmpty &&
                          modelList.contains(_selectedVehicleModel)) {
                        return _selectedVehicleModel;
                      }
                      return null;
                    })(),
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
              const SizedBox(height: 24),

              // Customer Information
              _buildSectionTitle('Customer Information'),
              const SizedBox(height: 16),
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

              // Basic Information
              _buildSectionTitle('Job Details'),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the job description';
                  }
                  return null;
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
                  Text(
                    'Default Status: ${_selectedStatus.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text(
                    'Job Priority: ',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    _selectedPriority.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text(
                    'Estimated Duration: ',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    _formatDuration(_estimatedDuration),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
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
                        backgroundColor: const Color(0xFF3C5C39),
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
                          Text('Cost: ${service.cost.toStringAsFixed(2)}'),
                          Text(
                            'Duration: ${_formatDuration(service.estimatedDuration!)}',
                          ),
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

              const SizedBox(height: 24),

              // Parts Section
              _buildSectionTitle('Parts'),
              JobPartsSelector(
                jobId:
                    widget.jobData?.id ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
                selectedParts: _selectedParts,
                onPartAdded: (part) {
                  setState(() {
                    _selectedParts.add(part);
                  });
                },
                onPartRemoved: (partId) {
                  setState(() {
                    _selectedParts.removeWhere((p) => p.id == partId);
                  });
                },
                onQuantityChanged: (partId, newQuantity) {
                  setState(() {
                    final index = _selectedParts.indexWhere(
                      (p) => p.id == partId,
                    );
                    if (index != -1) {
                      final part = _selectedParts[index];
                      _selectedParts[index] = Part(
                        id: part.id,
                        catalogId: part.catalogId,
                        name: part.name,
                        price: part.price,
                        quantity: newQuantity,
                        addedAt: part.addedAt,
                      );
                    }
                  });
                },
              ),

              const SizedBox(height: 24),

              // Notes
              _buildSectionTitle('Notes'),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'General Job Notes',
                  border: OutlineInputBorder(),
                  hintText: 'Add general notes about the job...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Scheduled Date & Time'),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (_estimatedDuration.inMinutes == 0) {
                          // If no estimated duration, show a message to ask the user to add a service task
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Please add a service task before setting the scheduled time.',
                              ),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        } else {
                          // Proceed with selecting the date if there's an estimated duration
                          _selectDate();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey, // Border color
                            width: 1.0, // Border width
                          ),
                          borderRadius: BorderRadius.circular(
                            8,
                          ), // Rounded corners
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Colors.black,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Scheduled Date',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  DateFormat(
                                    'MMM dd, yyyy',
                                  ).format(_scheduledDate),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (_estimatedDuration.inMinutes == 0) {
                          // If no estimated duration, show a message to ask the user to add a service task
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Please add a service task before setting the scheduled time.',
                              ),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        } else {
                          // Proceed with selecting the date if there's an estimated duration
                          _selectTime();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey, // Border color
                            width: 1.0, // Border width
                          ),
                          borderRadius: BorderRadius.circular(
                            8,
                          ), // Rounded corners
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, color: Colors.black),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Scheduled Time',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  _scheduledTime.format(context),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveJob,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3C5C39),
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
          color: Color(0xFF3C5C39),
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
