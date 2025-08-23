import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/job.dart';

class JobCard extends StatelessWidget {
  final Job job;
  final VoidCallback? onTap;
  final Function(String)? onStatusChanged;
  final String Function(String?)? getMechanicName; // Function to resolve mechanic ID to name

  const JobCard({
    super.key,
    required this.job,
    this.onTap,
    this.onStatusChanged,
    this.getMechanicName,
  });

  String _getMechanicDisplayName() {
    if (getMechanicName != null) {
      return getMechanicName!(job.assignedTo);
    }
    // Fallback to showing the ID if no resolver function is provided
    return job.assignedTo ?? 'Unassigned';
  }

  @override
  Widget build(BuildContext context) {
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

    Color priorityColor;
    switch (job.priority) {
      case 'low':
        priorityColor = Colors.green;
        break;
      case 'medium':
        priorityColor = Colors.orange;
        break;
      case 'high':
        priorityColor = Colors.red;
        break;
      case 'urgent':
        priorityColor = Colors.purple;
        break;
      default:
        priorityColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status and priority
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      job.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          job.priority.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: priorityColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
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
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Customer and vehicle info
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      job.customerName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.phone, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    job.customerContact,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.directions_car,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${job.vehicleModel} - ${job.vehiclePlate}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Assigned mechanic and schedule
              Row(
                children: [
                  const Icon(Icons.engineering, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Assigned to: ${_getMechanicDisplayName()}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Scheduled: ${DateFormat('MMM dd, yyyy HH:mm').format(job.scheduledDate)}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.timer, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Duration: ${job.estimatedDuration} minutes',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Service tasks preview
              if (job.services.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.build, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Services (${job.services.length}):',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ...job.services
                    .take(2)
                    .map(
                      (service) => Padding(
                        padding: const EdgeInsets.only(left: 24, bottom: 2),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 12,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${service.serviceName} - ${service.mechanicName}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                if (job.services.length > 2)
                  Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: Text(
                      '... and ${job.services.length - 2} more',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
              ],

              // Created date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Created: ${DateFormat('MMM dd, yyyy').format(job.createdDate)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  if (onStatusChanged != null)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: onStatusChanged,
                      itemBuilder:
                          (context) => [
                            const PopupMenuItem(
                              value: 'pending',
                              child: Text('Mark as Pending'),
                            ),
                            const PopupMenuItem(
                              value: 'in_progress',
                              child: Text('Mark as In Progress'),
                            ),
                            const PopupMenuItem(
                              value: 'completed',
                              child: Text('Mark as Completed'),
                            ),
                            const PopupMenuItem(
                              value: 'cancelled',
                              child: Text('Mark as Cancelled'),
                            ),
                          ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
