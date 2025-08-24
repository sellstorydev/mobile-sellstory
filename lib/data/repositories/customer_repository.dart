import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/customer.dart';
import '../services/firestore_service.dart';

class CustomerRepository {
  final FirestoreService _firestoreService;

  CustomerRepository(this._firestoreService);

  // Get customers for a specific workspace
  Future<List<Customer>> getCustomers(String workspaceId) async {
    try {
      final customersCollection = _firestoreService.getWorkspaceCustomersCollection(workspaceId);
      final querySnapshot = await customersCollection.get();
      
      return querySnapshot.docs.map((doc) {
        return Customer.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch customers: $e');
    }
  }

  // Get customers stream for real-time updates
  Stream<List<Customer>> getCustomersStream(String workspaceId) {
    try {
      final customersCollection = _firestoreService.getWorkspaceCustomersCollection(workspaceId);
      return customersCollection.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          return Customer.fromMap(doc.data(), doc.id);
        }).toList();
      });
    } catch (e) {
      throw Exception('Failed to fetch customers stream: $e');
    }
  }

  // Get customer by ID
  Future<Customer?> getCustomer(String workspaceId, String customerId) async {
    try {
      final customerDoc = await _firestoreService
          .getWorkspaceCustomersCollection(workspaceId)
          .doc(customerId)
          .get();
      
      if (customerDoc.exists) {
        return Customer.fromMap(customerDoc.data()!, customerDoc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch customer: $e');
    }
  }

  // Add new customer
  Future<String> addCustomer(String workspaceId, Customer customer) async {
    try {
      final docRef = await _firestoreService
          .getWorkspaceCustomersCollection(workspaceId)
          .add(customer.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add customer: $e');
    }
  }

  // Update customer
  Future<void> updateCustomer(String workspaceId, Customer customer) async {
    try {
      await _firestoreService
          .getWorkspaceCustomersCollection(workspaceId)
          .doc(customer.id)
          .update(customer.toMap());
    } catch (e) {
      throw Exception('Failed to update customer: $e');
    }
  }

  // Delete customer
  Future<void> deleteCustomer(String workspaceId, String customerId) async {
    try {
      await _firestoreService
          .getWorkspaceCustomersCollection(workspaceId)
          .doc(customerId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete customer: $e');
    }
  }

  // Search customers by name
  Future<List<Customer>> searchCustomers(String workspaceId, String searchTerm) async {
    try {
      final customersCollection = _firestoreService.getWorkspaceCustomersCollection(workspaceId);
      final querySnapshot = await customersCollection
          .where('name', isGreaterThanOrEqualTo: searchTerm)
          .where('name', isLessThan: searchTerm + '\uf8ff')
          .get();
      
      return querySnapshot.docs.map((doc) {
        return Customer.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search customers: $e');
    }
  }

  // Get customer sources from workspace
  Future<List<String>> getCustomerSources(String workspaceId) async {
    try {
      final workspaceDoc = await _firestoreService.workspacesCollection.doc(workspaceId).get();
      if (workspaceDoc.exists) {
        final workspaceData = workspaceDoc.data()!;
        final companyProfile = workspaceData['companyProfile'] as Map<String, dynamic>?;
        if (companyProfile != null) {
          final customerSources = companyProfile['customerSources'] as List<dynamic>? ?? [];
          return customerSources.cast<String>();
        }
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch customer sources: $e');
    }
  }
}


