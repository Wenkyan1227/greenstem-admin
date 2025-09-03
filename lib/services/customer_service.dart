import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer.dart';

class CustomerService {
  final CollectionReference _customersCollection = FirebaseFirestore.instance
      .collection('customers');

  Future<String> _generateCustomerId() async {
    QuerySnapshot snapshot =
        await _customersCollection
            .orderBy(FieldPath.documentId, descending: true)
            .limit(1)
            .get();

    int nextNumber = 1;
    if (snapshot.docs.isNotEmpty) {
      String lastId = snapshot.docs.first.id;
      if (lastId.startsWith('C')) {
        String numberPart = lastId.substring(1);
        nextNumber = (int.tryParse(numberPart) ?? 0) + 1;
      }
    }

    return 'C${nextNumber.toString().padLeft(4, '0')}';
  }

  // Get all vehicle brands
  Stream<List<Customer>> getCustomers() {
    return _customersCollection.orderBy('customerName').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Customer.fromFirestore(doc)).toList();
    });
  }

  // Get vehicle brand by ID
  Future<Customer?> getCustomerById(String customerId) async {
    DocumentSnapshot doc = await _customersCollection.doc(customerId).get();
    if (doc.exists) {
      return Customer.fromFirestore(doc);
    }
    return null;
  }

  // Create a new vehicle brand
  Future<void> createCustomer(Customer customer) async {
    String customerId = await _generateCustomerId();
    customer = customer.copyWith(id: customerId);
    await _customersCollection.doc(customerId).set(customer.toFirestore());
  }

  // Update a vehicle brand
  Future<void> updateCustomer(Customer customer) async {
    await _customersCollection.doc(customer.id).update(customer.toFirestore());
  }

  // Delete a vehicle brand
  Future<void> deleteCustomer(String customerId) async {
    await _customersCollection.doc(customerId).delete();
  }
}
