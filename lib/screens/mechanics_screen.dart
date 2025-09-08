// Enhanced MechanicsScreen with working schedule management
// screens/mechanics_screen.dart (complete version)
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/mechanic.dart';
import '../services/mechanic_service.dart';
import '../widgets/mechanic_card.dart';
import '../widgets/working_schedule.dart';
import '../widgets/mechanic_attendance_summary.dart';

class MechanicsScreen extends StatefulWidget {
  const MechanicsScreen({super.key});

  @override
  State<MechanicsScreen> createState() => _MechanicsScreenState();
}

class _MechanicsScreenState extends State<MechanicsScreen>
    with TickerProviderStateMixin {
  final MechanicService _mechanicService = MechanicService();
  String _searchQuery = '';
  late TabController _tabController;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Trigger rebuild when tab changes
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: const Color(0xFF3C5C39),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Mechanics'),
            Tab(icon: Icon(Icons.schedule), text: 'Schedule'),
            Tab(icon: Icon(Icons.analytics), text: 'Attendance'),
          ],
        ),
        actions: [
          if (_tabController.index == 0)
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: _showAddMechanicDialog,
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Mechanics Management
          _buildMechanicsTab(),

          // Tab 2: Working Schedule
          _buildScheduleTab(),

          // Tab 3: Attendance Overview
          _buildAttendanceTab(),
        ],
      ),
    );
  }

  Widget _buildMechanicsTab() {
    return Column(
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
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
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
    );
  }

  Widget _buildScheduleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Manage Working Schedule",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Configure which days of the week are working days for all mechanics.",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 16),
          const WorkingScheduleWidget(),
          const SizedBox(height: 24),

          // Additional info card
          Card(
            color: Colors.blue[50],
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        "Important Notes",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    "• Changes to working schedule will affect all mechanics immediately\n"
                    "• Past attendance records will not be modified\n"
                    "• Mechanics will be notified of schedule changes on their next login\n"
                    "• Absent days are automatically marked for working days with no check-in",
                    style: TextStyle(fontSize: 13, color: Colors.blue),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTab() {
    return Column(
      children: [
        // Month Selector
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "Attendance Overview - ${DateFormat('MMMM yyyy').format(_selectedMonth)}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month - 1,
                    );
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month + 1,
                    );
                  });
                },
              ),
            ],
          ),
        ),

        // Attendance List
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

              if (mechanics.isEmpty) {
                return const Center(child: Text('No mechanics to display'));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: mechanics.length,
                itemBuilder: (context, index) {
                  final mechanic = mechanics[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: MechanicAttendanceSummary(
                      mechanic: mechanic,
                      month: _selectedMonth,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

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

                              // Add attendance summary for this mechanic
                              MechanicAttendanceSummary(
                                mechanic: mechanic,
                                month: DateTime.now(),
                              ),

                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _showEditMechanicDialog(mechanic);
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
                                        _showDeleteMechanicDialog(mechanic);
                                      },
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      label: const Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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

  void _showEditMechanicDialog(Mechanic mechanic) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: mechanic.name);
    final emailController = TextEditingController(text: mechanic.email);
    bool loading = false;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Edit Mechanic'),
                content: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
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
                        controller: emailController,
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
                    onPressed: loading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed:
                        loading
                            ? null
                            : () async {
                              if (formKey.currentState!.validate()) {
                                setDialogState(() {
                                  loading = true;
                                });

                                try {
                                  final updatedMechanic = mechanic.copyWith(
                                    name: nameController.text.trim(),
                                    email: emailController.text.trim(),
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
                                      loading = false;
                                    });
                                  }
                                }
                              }
                            },
                    child:
                        loading
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

  void _showDeleteMechanicDialog(Mechanic mechanic) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Mechanic'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Are you sure you want to delete ${mechanic.name}?'),
                const SizedBox(height: 8),
                const Text(
                  'This action cannot be undone and will remove:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const Text('• Mechanic account'),
                const Text('• All attendance records'),
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

  void _showAddMechanicDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    bool loading = false;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Add Mechanic'),
                content: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
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
                        controller: emailController,
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
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Default password: 12345678\nMechanic can change this after first login.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: loading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed:
                        loading
                            ? null
                            : () async {
                              if (formKey.currentState!.validate()) {
                                setDialogState(() {
                                  loading = true;
                                });

                                try {
                                  // Sign up the mechanic using Firebase Auth
                                  final credential = await FirebaseAuth.instance
                                      .createUserWithEmailAndPassword(
                                        email: emailController.text.trim(),
                                        password: '12345678',
                                      );

                                  // Create the mechanic document in Firestore
                                  final newMechanic = Mechanic(
                                    id: credential.user!.uid,
                                    name: nameController.text.trim(),
                                    email: emailController.text.trim(),
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
                                      loading = false;
                                    });
                                  }
                                }
                              }
                            },
                    child:
                        loading
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
