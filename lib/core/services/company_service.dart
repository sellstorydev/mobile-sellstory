import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/company_picker.dart';

class CompanyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Company>> getCompanies(String workspaceId) async {
    try {
      final querySnapshot = await _firestore
          .collection('workspaces')
          .doc(workspaceId)
          .collection('companies')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Add document ID to the data
        return Company.fromMap(data);
      }).toList();
    } catch (e) {
      print('Error fetching companies: $e');
      return [];
    }
  }

  Future<Company?> getCompany(String workspaceId, String companyId) async {
    try {
      final docSnapshot = await _firestore
          .collection('workspaces')
          .doc(workspaceId)
          .collection('companies')
          .doc(companyId)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        data['id'] = docSnapshot.id;
        return Company.fromMap(data);
      }
      return null;
    } catch (e) {
      print('Error fetching company: $e');
      return null;
    }
  }

  Future<void> addCompany(String workspaceId, Company company) async {
    try {
      await _firestore
          .collection('workspaces')
          .doc(workspaceId)
          .collection('companies')
          .add(company.toMap());
    } catch (e) {
      print('Error adding company: $e');
      rethrow;
    }
  }

  Future<void> updateCompany(String workspaceId, Company company) async {
    try {
      await _firestore
          .collection('workspaces')
          .doc(workspaceId)
          .collection('companies')
          .doc(company.id)
          .update(company.toMap());
    } catch (e) {
      print('Error updating company: $e');
      rethrow;
    }
  }

  Future<void> deleteCompany(String workspaceId, String companyId) async {
    try {
      await _firestore
          .collection('workspaces')
          .doc(workspaceId)
          .collection('companies')
          .doc(companyId)
          .delete();
    } catch (e) {
      print('Error deleting company: $e');
      rethrow;
    }
  }

  Future<List<Company>> searchCompanies(String workspaceId, String searchQuery) async {
    try {
      final querySnapshot = await _firestore
          .collection('workspaces')
          .doc(workspaceId)
          .collection('companies')
          .where('name', isGreaterThanOrEqualTo: searchQuery)
          .where('name', isLessThan: searchQuery + '\uf8ff')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Company.fromMap(data);
      }).toList();
    } catch (e) {
      print('Error searching companies: $e');
      return [];
    }
  }
}

