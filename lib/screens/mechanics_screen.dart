import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/mechanic.dart';
import '../services/mechanic_service.dart';
import '../widgets/mechanic_card.dart';

class MechanicsScreen extends StatefulWidget {
  const MechanicsScreen({super.key});

  @override
  State<MechanicsScreen> createState() => _MechanicsScreenState();
}

class _MechanicsScreenState extends State<MechanicsScreen> {
  final MechanicService _mechanicService = MechanicService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mechanics'),
        backgroundColor: const Color(0xFF29A87A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Add Mechanic Button
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              _showAddMechanicDialog();
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
                hintText: 'Search mechanics...',
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

          // Mechanics List
          Expanded(
            child: StreamBuilder<List<Mechanic>>(
              stream: _mechanicService.getAllMechanics(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final mechanics = snapshot.data ?? [];
                final filteredMechanics =
                    mechanics.where((mechanic) {
                      if (_searchQuery.isEmpty) return true;
                      return mechanic.name.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ) ||
                          mechanic.email.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          );
                    }).toList();

                if (filteredMechanics.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.engineering,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No mechanics found',
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
                  itemCount: filteredMechanics.length,
                  itemBuilder: (context, index) {
                    final mechanic = filteredMechanics[index];
                    return MechanicCard(
                      mechanic: mechanic,
                      onTap: () {
                        _showMechanicDetails(mechanic);
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

  // Show mechanic details in a modal
  void _showMechanicDetails(Mechanic mechanic) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            builder:
                (context, scrollController) => Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            mechanic.name,
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
                              _buildDetailRow('Email', mechanic.email),
                              _buildDetailRow(
                                'Created Date',
                                DateFormat(
                                  'MMM dd, yyyy',
                                ).format(mechanic.createdAt),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _showEditMechanicDialog(mechanic);
                                  },
                                  child: const Text('Edit'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  // Helper method to build the detail row for mechanic info
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

  // Show dialog to edit mechanic details
  void _showEditMechanicDialog(Mechanic mechanic) {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController(text: mechanic.name);
    final _emailController = TextEditingController(text: mechanic.email);
    bool _loading = false;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Edit Mechanic'),
                content: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: _loading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed:
                        _loading
                            ? null
                            : () async {
                              if (_formKey.currentState!.validate()) {
                                setDialogState(() {
                                  _loading = true;
                                });

                                try {
                                  final updatedMechanic = mechanic.copyWith(
                                    name: _nameController.text.trim(),
                                    email: _emailController.text.trim(),
                                  );

                                  await _mechanicService.updateMechanic(
                                    updatedMechanic,
                                  );

                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Mechanic updated successfully!',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Error updating mechanic: $e',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setDialogState(() {
                                      _loading = false;
                                    });
                                  }
                                }
                              }
                            },
                    child:
                        _loading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Text('Update'),
                  ),
                ],
              );
            },
          ),
    );
  }

  // Show dialog to add a new mechanic (sign-up process)
  void _showAddMechanicDialog() {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    final _emailController = TextEditingController();
    bool _loading = false;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Add Mechanic'),
                content: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: _loading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed:
                        _loading
                            ? null
                            : () async {
                              if (_formKey.currentState!.validate()) {
                                setDialogState(() {
                                  _loading = true;
                                });

                                try {
                                  // Sign up the mechanic using Firebase Auth
                                  final credential = await FirebaseAuth.instance
                                      .createUserWithEmailAndPassword(
                                        email: _emailController.text.trim(),
                                        password: '12345678',
                                      );

                                  // Create the mechanic document in Firestore using the uid
                                  final newMechanic = Mechanic(
                                    id: credential.user!.uid,
                                    name: _nameController.text.trim(),
                                    email: _emailController.text.trim(),
                                    createdAt: DateTime.now(),
                                  );

                                  await _mechanicService.createMechanicWithAuth(
                                    newMechanic,
                                  );

                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Mechanic added successfully!',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Error adding mechanic: $e',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setDialogState(() {
                                      _loading = false;
                                    });
                                  }
                                }
                              }
                            },
                    child:
                        _loading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Text('Add'),
                  ),
                ],
              );
            },
          ),
    );
  }
}
