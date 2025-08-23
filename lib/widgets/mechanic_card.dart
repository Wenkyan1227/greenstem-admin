import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/mechanic.dart';

class MechanicCard extends StatelessWidget {
  final Mechanic mechanic;
  final VoidCallback? onTap;

  const MechanicCard({super.key, required this.mechanic, this.onTap});

  @override
  Widget build(BuildContext context) {
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
              // Header with name
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      mechanic.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Contact information
              Row(
                children: [
                  const Icon(Icons.email, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      mechanic.email,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Created date
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Created: ${DateFormat('MMM dd, yyyy').format(mechanic.createdAt)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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
