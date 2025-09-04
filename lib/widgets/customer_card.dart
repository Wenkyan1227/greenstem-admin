import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/customer.dart';
import '../services/vehicle_service.dart';
import '../models/vehicle.dart';

class CustomerCard extends StatefulWidget {
  final Customer customer;
  final String vehicleBrandId;
  final void Function(String) onTap;

  const CustomerCard({
    super.key,
    required this.customer,
    required this.vehicleBrandId,
    required this.onTap,
  });

  @override
  State<CustomerCard> createState() => _CustomerCardState();
}

class _CustomerCardState extends State<CustomerCard> {
  final VehicleService _vehicleService = VehicleService();
  late Future<VehicleBrand?> _vehicleBrand;

  @override
  void initState() {
    super.initState();
    _vehicleBrand = _vehicleService.getVehicleBrandById(widget.vehicleBrandId);  // Fetch the vehicle brand asynchronously
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Pass the vehicle brand name to the callback when tapped
          _vehicleBrand.then((brand) {
            widget.onTap(brand?.name ?? 'Unknown');
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with customer name
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.customer.customerName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Customer contact information
              Row(
                children: [
                  const Icon(Icons.phone, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.customer.customerContact,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Vehicle information
              Row(
                children: [
                  const Icon(
                    Icons.directions_car,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FutureBuilder<VehicleBrand?>(
                      future: _vehicleBrand,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }
                        if (snapshot.hasData) {
                          final vehicleBrandName = snapshot.data?.name ?? 'Unknown';
                          return Text(
                            '$vehicleBrandName | ${widget.customer.vehicleModel} | ${widget.customer.vehiclePlate}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          );
                        }
                        return const Text('No brand available');
                      },
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
                    'Created: ${DateFormat('MMM dd, yyyy').format(widget.customer.createdAt)}',
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
