import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';
import '../widgets/customer_card.dart';
import '../services/vehicle_service.dart';
import '../models/vehicle.dart';

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({Key? key}) : super(key: key);

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  final CustomerService _customerService = CustomerService();
  final VehicleService _vehicleService = VehicleService();

  final _formKey = GlobalKey<FormState>();
  String _searchQuery = '';
  String _selectedVehicleBrand = '';
  String _selectedVehicleModel = '';
  List<VehicleBrand> _vehicleBrands = [];
  List<VehicleModel> _availableModels = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _vehicleService.getVehicleBrands().listen((brands) {
      setState(() {
        _vehicleBrands = brands;
        if (_vehicleBrands.isNotEmpty && _selectedVehicleBrand.isEmpty) {
          _selectedVehicleBrand = _vehicleBrands.first.id;
          _updateAvailableModels();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Management'),
        backgroundColor: const Color(0xFF3C5C39),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _showAddCustomerDialog,
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
                hintText: 'Search customers...',
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

          // Customers List
          Expanded(
            child: StreamBuilder<List<Customer>>(
              stream: _customerService.getCustomers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final customers = snapshot.data ?? [];
                final filteredCustomers =
                    customers.where((customer) {
                      if (_searchQuery.isEmpty) return true;
                      return customer.customerName.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      );
                    }).toList();

                if (filteredCustomers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No customers found',
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
                  itemCount: filteredCustomers.length,
                  itemBuilder: (context, index) {
                    final customer = filteredCustomers[index];
                    return CustomerCard(
                      customer: customer,
                      vehicleBrandId: customer.vehicleBrand,
                      onTap: (vehicleBrand) {
                        _showCustomerDetails(customer, vehicleBrand);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCustomerDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final contactController = TextEditingController();
    final vehiclePlateController = TextEditingController();
    final vehicleModelController = TextEditingController();
    final vehicleBrandController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add New Customer'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                      validator:
                          (value) =>
                              value?.isEmpty ?? true
                                  ? 'Name is required'
                                  : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: contactController,
                      decoration: const InputDecoration(
                        labelText: 'Contact',
                        border: OutlineInputBorder(),
                      ),
                      validator:
                          (value) =>
                              value?.isEmpty ?? true
                                  ? 'Contact is required'
                                  : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: vehiclePlateController,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle Plate',
                        border: OutlineInputBorder(),
                      ),
                      validator:
                          (value) =>
                              value?.isEmpty ?? true
                                  ? 'Vehicle Plate is required'
                                  : null,
                    ),
                    const SizedBox(height: 16),
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
                onPressed: () {
                  _saveCustomer(
                    nameController,
                    contactController,
                    vehiclePlateController,
                    vehicleModelController,
                    vehicleBrandController,
                  );
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _saveCustomer(
    TextEditingController nameController,
    TextEditingController contactController,
    TextEditingController vehiclePlateController,
    TextEditingController vehicleModelController,
    TextEditingController vehicleBrandController,
  ) {
    if (_formKey.currentState?.validate() ?? false) {
      final newCustomer = Customer(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        customerName: nameController.text,
        customerContact: contactController.text,
        vehiclePlate: vehiclePlateController.text,
        vehicleModel: vehicleModelController.text,
        vehicleBrand: vehicleBrandController.text,
        createdAt: DateTime.now(),
      );

      _customerService
          .createCustomer(newCustomer)
          .then((_) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Customer added successfully')),
            );
          })
          .catchError((error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error adding customer: $error')),
            );
          });
    }
  }

  void _showCustomerDetails(Customer customer, String vehicleBrand) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          customer.customerName,
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
                              'Contact',
                              customer.customerContact,
                            ),
                            _buildDetailRow(
                              'Vehicle Plate',
                              customer.vehiclePlate,
                            ),
                            _buildDetailRow('Vehicle Brand', vehicleBrand),
                            _buildDetailRow(
                              'Vehicle Model',
                              customer.vehicleModel,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showEditCustomerDialog(customer);
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showDeleteCustomerDialog(customer);
                            },
                            icon: const Icon(Icons.delete, color: Colors.red),
                            label: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                            ),
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

  void _showEditCustomerDialog(Customer customer) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: customer.customerName);
    final contactController = TextEditingController(
      text: customer.customerContact,
    );
    final vehiclePlateController = TextEditingController(
      text: customer.vehiclePlate,
    );

    // Initialize the selected values based on the current customer data
    _selectedVehicleBrand = customer.vehicleBrand;
    /// Make sure to load the models for the selected brand
    _updateAvailableModels();
    _selectedVehicleModel = customer.vehicleModel;


    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Customer'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Customer Name
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator:
                          (value) =>
                              value?.isEmpty ?? true
                                  ? 'Name is required'
                                  : null,
                    ),
                    const SizedBox(height: 16),

                    // Contact
                    TextFormField(
                      controller: contactController,
                      decoration: const InputDecoration(labelText: 'Contact'),
                      validator:
                          (value) =>
                              value?.isEmpty ?? true
                                  ? 'Contact is required'
                                  : null,
                    ),
                    const SizedBox(height: 16),

                    // Vehicle Plate
                    TextFormField(
                      controller: vehiclePlateController,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle Plate',
                      ),
                      validator:
                          (value) =>
                              value?.isEmpty ?? true
                                  ? 'Vehicle Plate is required'
                                  : null,
                    ),
                    const SizedBox(height: 16),

                    // Vehicle Brand Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedVehicleBrand,
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
                          _selectedVehicleBrand = value!;
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

                    // Vehicle Model Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedVehicleModel,
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
                          _selectedVehicleModel = value!;
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
                onPressed: () {
                  // Validate the form
                  if (formKey.currentState?.validate() ?? false) {
                    // Save the edited values
                    _updateCustomer(
                      context,
                      customer.id,
                      nameController.text,
                      contactController.text,
                      vehiclePlateController.text,
                      _selectedVehicleModel,
                      _selectedVehicleBrand,
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Update'),
              ),
            ],
          ),
    );
  }

  void _updateCustomer(
    BuildContext context,
    String customerId,
    String customerName,
    String customerContact,
    String vehiclePlate,
    String vehicleModel,
    String vehicleBrand,
  ) {
    final updatedCustomer = Customer(
      id: customerId,
      customerName: customerName,
      customerContact: customerContact,
      vehiclePlate: vehiclePlate,
      vehicleModel: vehicleModel,
      vehicleBrand: vehicleBrand,
      createdAt: DateTime.now(),
    );

    _customerService
        .updateCustomer(updatedCustomer)
        .then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Customer updated successfully')),
          );
        })
        .catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating customer: $error')),
          );
        });
  }

  void _showDeleteCustomerDialog(Customer customer) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Customer'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to delete ${customer.customerName}?',
                ),
                const SizedBox(height: 8),
                const Text(
                  'This action cannot be undone and will remove:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const Text('• Customer account'),
                const Text('• All associated data'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    // Note: Add actual delete method to MechanicService
                    // await _mechanicService.deleteMechanic(mechanic.id);

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Mechanic deleted successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error deleting mechanic: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}
