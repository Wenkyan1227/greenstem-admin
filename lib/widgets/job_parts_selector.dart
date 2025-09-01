import 'package:flutter/material.dart';
import '../models/part.dart';
import '../models/part_catalog.dart';
import '../services/part_catalog_service.dart';

class JobPartsSelector extends StatefulWidget {
  final String jobId;
  final List<Part> selectedParts;
  final Function(Part) onPartAdded;
  final Function(String) onPartRemoved;
  final Function(String, int) onQuantityChanged;

  const JobPartsSelector({
    Key? key,
    required this.jobId,
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
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showPartSelector(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Part'),
                ),
                const SizedBox(height: 16),
                _buildPartsList(),
              ],
            ),
          ),
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
      itemCount: widget.selectedParts.length,
      itemBuilder: (context, index) {
        final part = widget.selectedParts[index];
        return Card(
          child: ListTile(
            title: Text(part.name),
            subtitle: Text(
              'Price: \$${part.price.toStringAsFixed(2)} x ${part.quantity} = \$${(part.price * part.quantity).toStringAsFixed(2)}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
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
      builder: (context) => AlertDialog(
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
