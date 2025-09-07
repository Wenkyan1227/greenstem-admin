import 'package:flutter/material.dart';
import '../models/part.dart';
import '../models/part_catalog.dart';
import '../services/part_catalog_service.dart';

class JobPartsSelector extends StatefulWidget {
  final String jobId;
  final String taskId;
  final List<Part> selectedParts;
  final Function(Part) onPartAdded;
  final Function(String) onPartRemoved;
  final Function(String, int) onQuantityChanged;

  const JobPartsSelector({
    Key? key,
    required this.jobId,
    required this.taskId,
    required this.selectedParts,
    required this.onPartAdded,
    required this.onPartRemoved,
    required this.onQuantityChanged,
  }) : super(key: key);

  @override
  _JobPartsSelectorState createState() => _JobPartsSelectorState();
}

class _JobPartsSelectorState extends State<JobPartsSelector> {
  final PartCatalogService _partService = PartCatalogService();
  late List<Part> currentSelectedParts;

  @override
  void initState() {
    super.initState();
    if(widget.taskId == 'null') {
      currentSelectedParts = [];
    } else {
      currentSelectedParts = widget.selectedParts
          .where((part) => part.taskId == widget.taskId)
          .toList();
    }
    // currentSelectedParts = List.from(widget.selectedParts);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Parts',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [const SizedBox(height: 16), _buildPartsList()],
            ),
            ElevatedButton.icon(
              onPressed: () {
                if (widget.taskId != 'null') {
                  _showPartSelector(context);
                } else {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('No Service Selected'),
                          content: const Text('Please add a service first.'),
                          actions: [
                            TextButton(
                              onPressed:
                                  () => Navigator.pop(
                                    context,
                                  ), // Close the dialog
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                  );
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Part'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 36),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ],
    );
  }

  Widget _buildPartsList() {
    if (widget.selectedParts.isEmpty) {
      return const Text('No parts added yet');
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: currentSelectedParts.length,
      itemBuilder: (context, index) {
        final part = currentSelectedParts[index];
        return Card(
          child: ListTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Part name
                Expanded(
                  child: Text(
                    part.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                // Price x Quantity = Total
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Price: \$${part.price.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      'Quantity: x ${part.quantity}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      'Total = \$${(part.price * part.quantity).toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            subtitle: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Quantity controls
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        if (part.quantity > 1) {
                          widget.onQuantityChanged(part.id, part.quantity - 1);
                        }
                      },
                    ),
                    Text('${part.quantity}'),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        widget.onQuantityChanged(part.id, part.quantity + 1);
                      },
                    ),
                  ],
                ),
                // Delete button
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => widget.onPartRemoved(part.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPartSelector(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Select Parts'),
            content: SizedBox(
              width: double.maxFinite,
              child: StreamBuilder<List<PartCatalog>>(
                stream: _partService.getCatalogParts(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final parts = snapshot.data!;

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: parts.length,
                    itemBuilder: (context, index) {
                      final part = parts[index];
                      return ListTile(
                        title: Text(part.name),
                        subtitle: Text(
                          'Price: \$${part.basePrice.toStringAsFixed(2)} | Stock: ${part.stockQuantity}',
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            final newPart = Part.fromCatalog(part, quantity: 1);
                            currentSelectedParts.add(newPart);
                            widget.onPartAdded(newPart);
                            Navigator.pop(context);
                          },
                          child: const Text('Add'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }
}
