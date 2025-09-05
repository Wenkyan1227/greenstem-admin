import 'package:flutter/material.dart';
import '../services/job_service.dart';
import '../services/admin_service.dart';
import '../widgets/dashboard_card.dart';
import 'create_job_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final JobService _jobService = JobService();
  final AdminService _adminService = AdminService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: const Color(0xFF3C5C39),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _adminService.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3C5C39), Color(0xFF20B2AA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome to GreenStem Admin',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage your jobs, mechanics, and vehicle services efficiently',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Statistics Section
            const Text(
              'Overview',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, int>>(
              future: _jobService.getJobStatistics(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final stats = snapshot.data ?? {};
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DashboardCard(
                            title: 'Total Jobs',
                            value: '${stats['total'] ?? 0}',
                            icon: Icons.work,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DashboardCard(
                            title: 'Pending',
                            value: '${stats['pending'] ?? 0}',
                            icon: Icons.pending,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DashboardCard(
                            title: 'In Progress',
                            value: '${stats['in_progress'] ?? 0}',
                            icon: Icons.engineering,
                            color: Colors.purple,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DashboardCard(
                            title: 'Completed',
                            value: '${stats['completed'] ?? 0}',
                            icon: Icons.check_circle,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateJobScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Create New Job'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3C5C39),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
