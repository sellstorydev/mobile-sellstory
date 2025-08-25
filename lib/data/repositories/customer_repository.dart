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
      
      final List<Customer> customers = [];
      
      for (final doc in querySnapshot.docs) {
        try {
          final customer = Customer.fromMap(doc.data(), doc.id);
          customers.add(customer);
        } catch (e) {
          // Log detailed information about the parsing error
          print('=== Customer Parsing Error ===');
          print('Customer ID: ${doc.id}');
          print('Error Type: ${e.runtimeType}');
          print('Error Message: $e');
          print('Raw Data: ${doc.data()}');
          print('Data Keys: ${doc.data().keys.toList()}');
          
          // Try to extract basic information even if parsing fails
          try {
            final data = doc.data();
            final basicCustomer = Customer(
              id: doc.id,
              name: data['name']?.toString() ?? 'Unknown Customer',
              prefix: data['prefix']?.toString() ?? '',
              gender: data['gender']?.toString() ?? '',
              age: data['age']?.toString() ?? '',
              customerType: data['customerType']?.toString() ?? 'Customer',
              emails: Customer.parseEmailsFromMap(data['emails']),
              phones: Customer.parsePhonesFromMap(data['phones']),
              companyNames: data['companyNames']?.toString() ?? '',
              nationalId: data['nationalId']?.toString() ?? '',
              address: data['address']?.toString() ?? '',
              source: data['source']?.toString() ?? '',
              hashtags: [], // Empty hashtags to avoid parsing issues
              assignees: data['assignees']?.toString() ?? '',
              customId: data['customId']?.toString() ?? doc.id,
              workspaceId: data['workspaceId']?.toString() ?? workspaceId,
              createdAt: DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? DateTime.now(),
              updatedAt: DateTime.tryParse(data['updatedAt']?.toString() ?? '') ?? DateTime.now(),
              createdBy: data['createdBy']?.toString() ?? '',
              updatedBy: data['updatedBy']?.toString() ?? '',
            );
            customers.add(basicCustomer);
            print('✅ Created basic customer from raw data');
          } catch (fallbackError) {
            print('❌ Failed to create basic customer: $fallbackError');
            // Skip this customer entirely
          }
          print('=== End Customer Parsing Error ===');
        }
      }
      
      return customers;
    } catch (e) {
      throw Exception('Failed to fetch customers: $e');
    }
  }

  // Get customers stream for real-time updates
  Stream<List<Customer>> getCustomersStream(String workspaceId) {
    try {
      final customersCollection = _firestoreService.getWorkspaceCustomersCollection(workspaceId);
      return customersCollection.snapshots().map((snapshot) {
        final List<Customer> customers = [];
        
        for (final doc in snapshot.docs) {
          try {
            final customer = Customer.fromMap(doc.data(), doc.id);
            customers.add(customer);
          } catch (e) {
            // Log detailed information about the parsing error
            print('=== Customer Parsing Error (Stream) ===');
            print('Customer ID: ${doc.id}');
            print('Error Type: ${e.runtimeType}');
            print('Error Message: $e');
            print('Raw Data: ${doc.data()}');
            print('Data Keys: ${doc.data().keys.toList()}');
            
            // Try to extract basic information even if parsing fails
            try {
              final data = doc.data();
              final basicCustomer = Customer(
                id: doc.id,
                name: data['name']?.toString() ?? 'Unknown Customer',
                prefix: data['prefix']?.toString() ?? '',
                gender: data['gender']?.toString() ?? '',
                age: data['age']?.toString() ?? '',
                customerType: data['customerType']?.toString() ?? 'Customer',
                emails: Customer.parseEmailsFromMap(data['emails']),
                phones: Customer.parsePhonesFromMap(data['phones']),
                companyNames: data['companyNames']?.toString() ?? '',
                nationalId: data['nationalId']?.toString() ?? '',
                address: data['address']?.toString() ?? '',
                source: data['source']?.toString() ?? '',
                hashtags: [], // Empty hashtags to avoid parsing issues
                assignees: data['assignees']?.toString() ?? '',
                customId: data['customId']?.toString() ?? doc.id,
                workspaceId: data['workspaceId']?.toString() ?? workspaceId,
                createdAt: DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? DateTime.now(),
                updatedAt: DateTime.tryParse(data['updatedAt']?.toString() ?? '') ?? DateTime.now(),
                createdBy: data['createdBy']?.toString() ?? '',
                updatedBy: data['updatedBy']?.toString() ?? '',
              );
              customers.add(basicCustomer);
              print('✅ Created basic customer from raw data (Stream)');
            } catch (fallbackError) {
              print('❌ Failed to create basic customer (Stream): $fallbackError');
              // Skip this customer entirely
            }
            print('=== End Customer Parsing Error (Stream) ===');
          }
        }
        
        return customers;
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
      
      final List<Customer> customers = [];
      
      for (final doc in querySnapshot.docs) {
        try {
          final customer = Customer.fromMap(doc.data(), doc.id);
          customers.add(customer);
        } catch (e) {
          // Log detailed information about the parsing error
          print('=== Customer Search Parsing Error ===');
          print('Customer ID: ${doc.id}');
          print('Error Type: ${e.runtimeType}');
          print('Error Message: $e');
          print('Raw Data: ${doc.data()}');
          print('Data Keys: ${doc.data().keys.toList()}');
          
          // Try to extract basic information even if parsing fails
          try {
            final data = doc.data();
            final basicCustomer = Customer(
              id: doc.id,
              name: data['name']?.toString() ?? 'Unknown Customer',
              prefix: data['prefix']?.toString() ?? '',
              gender: data['gender']?.toString() ?? '',
              age: data['age']?.toString() ?? '',
              customerType: data['customerType']?.toString() ?? 'Customer',
              emails: Customer.parseEmailsFromMap(data['emails']),
              phones: Customer.parsePhonesFromMap(data['phones']),
              companyNames: data['companyNames']?.toString() ?? '',
              nationalId: data['nationalId']?.toString() ?? '',
              address: data['address']?.toString() ?? '',
              source: data['source']?.toString() ?? '',
              hashtags: [], // Empty hashtags to avoid parsing issues
              assignees: data['assignees']?.toString() ?? '',
              customId: data['customId']?.toString() ?? doc.id,
              workspaceId: data['workspaceId']?.toString() ?? workspaceId,
              createdAt: DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? DateTime.now(),
              updatedAt: DateTime.tryParse(data['updatedAt']?.toString() ?? '') ?? DateTime.now(),
              createdBy: data['createdBy']?.toString() ?? '',
              updatedBy: data['updatedBy']?.toString() ?? '',
            );
            customers.add(basicCustomer);
            print('✅ Created basic customer from search raw data');
          } catch (fallbackError) {
            print('❌ Failed to create basic customer from search: $fallbackError');
            // Skip this customer entirely
          }
          print('=== End Customer Search Parsing Error ===');
        }
      }
      
      return customers;
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


