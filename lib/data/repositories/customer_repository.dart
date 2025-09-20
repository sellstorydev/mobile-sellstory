import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/customer.dart';
import '../services/firestore_service.dart';
import '../services/mobile_permissions_service.dart';
import '../../core/services/algolia_customer_sync_service.dart';

// Paged result for customers pagination
class PagedCustomersResult {
  final List<Customer> customers;
  final QueryDocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;
  PagedCustomersResult({
    required this.customers,
    required this.lastDoc,
    required this.hasMore,
  });
}

class CustomerRepository {
  final FirestoreService _firestoreService;

  CustomerRepository(this._firestoreService);

  // Get customers for a specific workspace
  Future<List<Customer>> getCustomers(String workspaceId) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final perms = MobilePermissionsService.to;
      final bool isOwner = perms.isOwner;
      final bool canViewAll = perms.can('customer:view:all');
      final bool canViewAssigned = perms.can('customer:view:assigned');

      final customersCollection = _firestoreService.getWorkspaceCustomersCollection(workspaceId);

      Query<Map<String, dynamic>> query = customersCollection;
      if (!(isOwner || canViewAll) && canViewAssigned && uid.isNotEmpty) {
        // Reduce data by server-side filtering when only assigned
        query = query.where('assignees', arrayContains: uid);
      }

      final querySnapshot = await query.get();

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
              age: data['age'] ?? 0,
              customerType: data['customerType']?.toString() ?? 'Customer',
              emails: Customer.parseEmailsFromMap(data['emails']),
              phones: Customer.parsePhonesFromMap(data['phones']),
              companyNames: Customer.parseCompanyNamesFromMap(data['companyNames']),
              nationalId: data['nationalId']?.toString() ?? '',
              address: data['address']?.toString() ?? '',
              source: data['source']?.toString() ?? '',
              hashtags: [], // Empty hashtags to avoid parsing issues
              assignees: Customer.parseAssigneesFromMap(data['assignees']),
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
      
      // If still need to enforce assigned-only in-memory (in case the server query couldn't be applied), do it here
      if (!(isOwner || canViewAll)) {
        if (canViewAssigned && uid.isNotEmpty) {
          return customers.where((c) => c.assignees.contains(uid)).toList();
        }
        return <Customer>[];
      }

      return customers;
    } catch (e) {
      throw Exception('Failed to fetch customers: $e');
    }
  }

  // Get customers stream for real-time updates
  Stream<List<Customer>> getCustomersStream(String workspaceId) {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final perms = MobilePermissionsService.to;
      final bool isOwner = perms.isOwner;
      final bool canViewAll = perms.can('customer:view:all');
      final bool canViewAssigned = perms.can('customer:view:assigned');

      final customersCollection = _firestoreService.getWorkspaceCustomersCollection(workspaceId);

      Query<Map<String, dynamic>> base = customersCollection;
      if (!(isOwner || canViewAll) && canViewAssigned && uid.isNotEmpty) {
        base = base.where('assignees', arrayContains: uid);
      }

      return base.snapshots().map((QuerySnapshot<Map<String, dynamic>> snapshot) {
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
                age: data['age'] ?? 0,
                customerType: data['customerType']?.toString() ?? 'Customer',
                emails: Customer.parseEmailsFromMap(data['emails']),
                phones: Customer.parsePhonesFromMap(data['phones']),
                companyNames: Customer.parseCompanyNamesFromMap(data['companyNames']),
                nationalId: data['nationalId']?.toString() ?? '',
                address: data['address']?.toString() ?? '',
                source: data['source']?.toString() ?? '',
                hashtags: [], // Empty hashtags to avoid parsing issues
                assignees: Customer.parseAssigneesFromMap(data['assignees']),
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
        
        if (!(isOwner || canViewAll)) {
          if (canViewAssigned && uid.isNotEmpty) {
            return customers.where((c) => c.assignees.contains(uid)).toList();
          }
          return <Customer>[];
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
      
      // Sync to Algolia after successful Firestore operation
      final customerWithId = customer.copyWith(id: docRef.id);
      await AlgoliaCustomerSyncService.syncCustomerToAlgolia(customerWithId);
      
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
      
      // Sync to Algolia after successful Firestore operation
      await AlgoliaCustomerSyncService.syncCustomerToAlgolia(customer);
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
      
      // Remove from Algolia after successful Firestore operation
      await AlgoliaCustomerSyncService.syncCustomerDeletionToAlgolia(customerId);
    } catch (e) {
      throw Exception('Failed to delete customer: $e');
    }
  }


  // Search customers by name
  Future<List<Customer>> searchCustomers(String workspaceId, String searchTerm) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final perms = MobilePermissionsService.to;
      final bool isOwner = perms.isOwner;
      final bool canViewAll = perms.can('customer:view:all');
      final bool canViewAssigned = perms.can('customer:view:assigned');

      final customersCollection = _firestoreService.getWorkspaceCustomersCollection(workspaceId);

      Query<Map<String, dynamic>> query = customersCollection
          .where('name', isGreaterThanOrEqualTo: searchTerm)
          .where('name', isLessThan: searchTerm + '\uf8ff');

      if (!(isOwner || canViewAll) && canViewAssigned && uid.isNotEmpty) {
        // Firestore cannot combine range and array-contains on different fields without index; try post-filter if needed
        // So we won't add arrayContains here to avoid index complexity; we'll filter in-memory later
      }

      final querySnapshot = await query.get();

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
              age: data['age'] ?? '',
              customerType: data['customerType']?.toString() ?? 'Customer',
              emails: Customer.parseEmailsFromMap(data['emails']),
              phones: Customer.parsePhonesFromMap(data['phones']),
              companyNames: Customer.parseCompanyNamesFromMap(data['companyNames']),
              nationalId: data['nationalId']?.toString() ?? '',
              address: data['address']?.toString() ?? '',
              source: data['source']?.toString() ?? '',
              hashtags: [], // Empty hashtags to avoid parsing issues
              assignees: Customer.parseAssigneesFromMap(data['assignees']),
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
      
      if (!(isOwner || canViewAll)) {
        if (canViewAssigned && uid.isNotEmpty) {
          return customers.where((c) => c.assignees.contains(uid)).toList();
        }
        return <Customer>[];
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

  // Cursor-based pagination using createdAt (descending)
  Future<PagedCustomersResult> getCustomersPage(
    String workspaceId, {
    int limit = 25,
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final perms = MobilePermissionsService.to;
      final bool isOwner = perms.isOwner;
      final bool canViewAll = perms.can('customer:view:all');
      final bool canViewAssigned = perms.can('customer:view:assigned');

      final customersCollection = _firestoreService.getWorkspaceCustomersCollection(workspaceId);

      Query<Map<String, dynamic>> query = customersCollection
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (!(isOwner || canViewAll) && canViewAssigned && uid.isNotEmpty) {
        query = customersCollection
            .where('assignees', arrayContains: uid)
            .orderBy('createdAt', descending: true)
            .limit(limit);
      }

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final qs = await query.get();

      final List<Customer> items = [];
      for (final doc in qs.docs) {
        try {
          items.add(Customer.fromMap(doc.data(), doc.id));
        } catch (e) {
          // Fallback minimal mapping if parsing fails
          try {
            final data = doc.data();
            items.add(Customer(
              id: doc.id,
              name: data['name']?.toString() ?? 'Unknown Customer',
              prefix: data['prefix']?.toString() ?? '',
              gender: data['gender']?.toString() ?? '',
              age: (data['age'] is int)
                  ? (data['age'] as int)
                  : (data['age'] is String)
                      ? int.tryParse((data['age'] as String)) ?? 0
                      : (data['age'] is double)
                          ? (data['age'] as double).toInt()
                          : 0,
              customerType: data['customerType']?.toString() ?? 'Customer',
              emails: Customer.parseEmailsFromMap(data['emails']),
              phones: Customer.parsePhonesFromMap(data['phones']),
              companyNames: Customer.parseCompanyNamesFromMap(data['companyNames']),
              nationalId: data['nationalId']?.toString() ?? '',
              address: data['address']?.toString() ?? '',
              source: data['source']?.toString() ?? '',
              hashtags: const [],
              assignees: Customer.parseAssigneesFromMap(data['assignees']),
              customId: data['customId']?.toString() ?? doc.id,
              workspaceId: data['workspaceId']?.toString() ?? workspaceId,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              createdBy: data['createdBy']?.toString() ?? '',
              updatedBy: data['updatedBy']?.toString() ?? '',
            ));
          } catch (_) {
            // skip if cannot parse at all
          }
        }
      }

      final last = qs.docs.isNotEmpty ? qs.docs.last : null;
      final hasMore = qs.docs.length == limit;

      // For assigned-only fallback filter (in case server couldn't apply)
      if (!(isOwner || canViewAll)) {
        if (canViewAssigned && uid.isNotEmpty) {
          final filtered = items.where((c) => c.assignees.contains(uid)).toList();
          return PagedCustomersResult(customers: filtered, lastDoc: last, hasMore: hasMore);
        }
        return PagedCustomersResult(customers: const [], lastDoc: last, hasMore: false);
      }

      return PagedCustomersResult(customers: items, lastDoc: last, hasMore: hasMore);
    } catch (e) {
      throw Exception('Failed to fetch customers page: $e');
    }
  }

  // Aggregate count of customers for a workspace (respecting permissions)
  Future<int> getCustomersCount(String workspaceId) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final perms = MobilePermissionsService.to;
      final bool isOwner = perms.isOwner;
      final bool canViewAll = perms.can('customer:view:all');
      final bool canViewAssigned = perms.can('customer:view:assigned');

      final customersCollection = _firestoreService.getWorkspaceCustomersCollection(workspaceId);

      Query<Map<String, dynamic>> query = customersCollection;
      if (!(isOwner || canViewAll) && canViewAssigned && uid.isNotEmpty) {
        query = query.where('assignees', arrayContains: uid);
      }

      final agg = await query.count().get();
      return agg.count!;
    } catch (e) {
      throw Exception('Failed to fetch customers count: $e');
    }
  }
}
