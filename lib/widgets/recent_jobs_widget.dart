import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/job.dart';
import '../services/job_service.dart';

class RecentJobsWidget extends StatelessWidget {
  const RecentJobsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final JobService jobService = JobService();

    return StreamBuilder<List<Job>>(
      stream: jobService.getJobs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final jobs = snapshot.data ?? [];
        final recentJobs = jobs.take(5).toList();

        if (recentJobs.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.work_outline,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No jobs yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Jobs',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigate to jobs screen
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentJobs.length,
                itemBuilder: (context, index) {
                  final job = recentJobs[index];
                  return _buildJobItem(context, job);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildJobItem(BuildContext context, Job job) {
    Color statusColor;
    IconData statusIcon;

    switch (job.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'in_progress':
        statusColor = Colors.blue;
        statusIcon = Icons.engineering;
        break;
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: statusColor.withOpacity(0.1),
        child: Icon(
          statusIcon,
          color: statusColor,
        ),
      ),
      title: Text(
        job.title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(job.customerName),
          Text(
            '${job.vehicleModel} - ${job.vehiclePlate}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              job.status.replaceAll('_', ' ').toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('MMM dd').format(job.scheduledDate),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      onTap: () {
        // Navigate to job details
      },
    );
  }
} 