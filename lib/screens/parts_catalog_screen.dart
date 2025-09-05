import 'package:flutter/material.dart';
import '../models/part_catalog.dart';
import '../services/part_catalog_service.dart';

class PartsCatalogScreen extends StatefulWidget {
  const PartsCatalogScreen({Key? key}) : super(key: key);

  @override
  _PartsCatalogScreenState createState() => _PartsCatalogScreenState();
}

class _PartsCatalogScreenState extends State<PartsCatalogScreen> {
  final PartCatalogService _partService = PartCatalogService();
  final _formKey = GlobalKey<FormState>();
  
  String _name = '';
  double _basePrice = 0.0;
  String _description = '';
  String _category = '';
  int _stockQuantity = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parts Catalog'),
        backgroundColor: const Color(0xFF3C5C39),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddPartDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<List<PartCatalog>>(
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
            itemCount: parts.length,
            itemBuilder: (context, index) {
              final part = parts[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(part.name),
                  subtitle: Text(
                    'Price: \$${part.basePrice.toStringAsFixed(2)} | Stock: ${part.stockQuantity}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditPartDialog(context, part),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _confirmDelete(context, part),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddPartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Part'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Name is required' : null,
                  onSaved: (value) => _name = value ?? '',
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Base Price'),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Price is required' : null,
                  onSaved: (value) => _basePrice = double.parse(value ?? '0'),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Description is required' : null,
                  onSaved: (value) => _description = value ?? '',
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Category'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Category is required' : null,
                  onSaved: (value) => _category = value ?? '',
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Stock Quantity'),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Stock quantity is required' : null,
                  onSaved: (value) => _stockQuantity = int.parse(value ?? '0'),
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
            onPressed: () => _savePart(context),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditPartDialog(BuildContext context, PartCatalog part) {
    _name = part.name;
    _basePrice = part.basePrice;
    _stockQuantity = part.stockQuantity;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Part'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: part.name,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Name is required' : null,
                  onSaved: (value) => _name = value ?? '',
                ),
                TextFormField(
                  initialValue: part.basePrice.toString(),
                  decoration: const InputDecoration(labelText: 'Base Price'),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Price is required' : null,
                  onSaved: (value) => _basePrice = double.parse(value ?? '0'),
                ),
                TextFormField(
                  initialValue: part.stockQuantity.toString(),
                  decoration: const InputDecoration(labelText: 'Stock Quantity'),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Stock quantity is required' : null,
                  onSaved: (value) => _stockQuantity = int.parse(value ?? '0'),
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
            onPressed: () => _updatePart(context, part.id),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _savePart(BuildContext context) {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      
      final part = PartCatalog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _name,
        basePrice: _basePrice,
        stockQuantity: _stockQuantity,
      );

      _partService.addCatalogPart(part).then((_) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Part added successfully')),
        );
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding part: $error')),
        );
      });
    }
  }

  void _updatePart(BuildContext context, String partId) {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      
      final part = PartCatalog(
        id: partId,
        name: _name,
        basePrice: _basePrice,
        stockQuantity: _stockQuantity,
      );

      _partService.updateCatalogPart(part).then((_) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Part updated successfully')),
        );
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating part: $error')),
        );
      });
    }
  }

  void _confirmDelete(BuildContext context, PartCatalog part) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Part'),
        content: Text('Are you sure you want to delete ${part.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              _partService.deleteCatalogPart(part.id).then((_) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Part deleted successfully')),
                );
              }).catchError((error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting part: $error')),
                );
              });
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
