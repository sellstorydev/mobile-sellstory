import 'package:get/get.dart';
import '../../domain/entities/company.dart';
import '../../core/services/logger_service.dart';
import 'algolia_config.dart';
import 'package:dio/dio.dart';

/// Service for handling company sync with Algolia
/// This implementation performs actual sync operations to Algolia database
class AlgoliaCompanySyncService {
  static final LoggerService _logger = Get.find<LoggerService>();
  
  // Admin API key for write operations (for development/testing purposes)
  // In production, this should be handled server-side for security
  static const String _adminApiKey = "a9f2dae0edfbe5795fbdd980179eddca";
  
  // Dio instance for HTTP requests
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://${AlgoliaConfig.appId}-dsn.algolia.net',
    headers: {
      'X-Algolia-API-Key': _adminApiKey,
      'X-Algolia-Application-Id': AlgoliaConfig.appId,
      'Content-Type': 'application/json',
    },
  ));

  /// Sync company data to Algolia index
  /// Performs actual saveObject operation via REST API
  static Future<void> syncCompanyToAlgolia(Company company) async {
    try {
      // Validate company ID before syncing
      if (company.id.isEmpty) {
        _logger.warning('⚠️ Cannot sync company to Algolia: Company ID is empty for ${company.name}');
        return;
      }
      
      _logger.info('🔍 Syncing company to Algolia: ${company.name} (${company.id})');
      
      // Build Algolia record based on the guide specifications
      final record = buildCompanyRecord(company);
      
      // Save the object to Algolia via REST API
      final response = await _dio.put(
        '/1/indexes/${AlgoliaConfig.companiesIndex}/${company.id}',
        data: record,
      );
      
      _logger.info('📤 Company synced to Algolia successfully: ${company.id}');
      _logger.debug('Algolia response: ${response.data}');
      _logger.info('✅ Company sync completed: ${company.id}');
      
    } catch (e) {
      _logger.error('❌ Failed to sync company to Algolia: ${company.id}, error: $e');
      // Don't throw - we want company operations to succeed even if Algolia fails
    }
  }

  /// Remove company from Algolia index
  /// Performs actual deleteObject operation via REST API
  static Future<void> syncCompanyDeletionToAlgolia(String companyId, String workspaceId) async {
    try {
      // Validate company ID before deleting
      if (companyId.isEmpty) {
        _logger.warning('⚠️ Cannot delete company from Algolia: Company ID is empty');
        return;
      }
      
      _logger.info('🗑️ Deleting company from Algolia: $companyId');
      
      // Delete the object from Algolia via REST API
      final response = await _dio.delete(
        '/1/indexes/${AlgoliaConfig.companiesIndex}/$companyId',
      );
      
      _logger.info('📤 Company deleted from Algolia successfully: $companyId');
      _logger.debug('Algolia response: ${response.data}');
      _logger.info('✅ Company deletion completed: $companyId');
      
    } catch (e) {
      _logger.error('❌ Failed to delete company from Algolia: $companyId, error: $e');
      // Don't throw - we want company operations to succeed even if Algolia fails
    }
  }

  /// Sync multiple companies to Algolia (for initial population)
  /// Uses batch API for better performance
  static Future<void> syncMultipleCompanies(List<Company> companies) async {
    try {
      _logger.info('🔄 Syncing ${companies.length} companies to Algolia...');
      
      if (companies.isEmpty) {
        _logger.warning('No companies to sync to Algolia');
        return;
      }
      
      // Build records for all companies
      final records = companies.map((company) => buildCompanyRecord(company)).toList();
      
      // Use batch API for better performance
      final response = await _dio.post(
        '/1/indexes/${AlgoliaConfig.companiesIndex}/batch',
        data: {
          'requests': records.map((record) => {
            'action': 'addObject',
            'body': record,
          }).toList(),
        },
      );
      
      _logger.info('📤 Batch sync to Algolia completed');
      _logger.debug('Algolia batch response: ${response.data}');
      _logger.info('✅ Successfully synced ${companies.length} companies to Algolia');
      
    } catch (e) {
      _logger.error('❌ Failed to sync multiple companies to Algolia: $e');
      // Fallback to individual sync
      _logger.info('📝 Falling back to individual sync...');
      for (final company in companies) {
        await syncCompanyToAlgolia(company);
        // Small delay to avoid overwhelming the API
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }
  }

  /// Build Algolia record for a company
  /// Based on the guide: objectID, workspaceId, name, customId, branch, emails[], phones[], taxId, website, customers[], updatedAt
  static Map<String, dynamic> buildCompanyRecord(Company company) {
    return {
      'objectID': company.id,
      'workspaceId': company.workspaceId,
      'name': company.name,
      'customId': company.customId,
      'branch': company.branch,
      'taxId': company.taxId,
      'website': company.website,
      'emails': extractContactValues(company.emails),
      'phones': extractContactValues(company.phones),
      'customers': company.associatedCustomerIds, // array of customer references
      'addressLine1': company.addressLine1,
      'province': company.province,
      'district': company.district,
      'subdistrict': company.subdistrict,
      'postalCode': company.postalCode,
      'country': company.country,
      'updatedAt': company.updatedAt.millisecondsSinceEpoch,
      'createdAt': company.createdAt.millisecondsSinceEpoch,
      // Generate searchable tokens for better search
      'nameTokens': generateNameTokens(company.name),
      'branchTokens': generateNameTokens(company.branch),
      'taxIdTokens': generateTaxIdTokens(company.taxId),
    };
  }

  /// Extract contact values (emails or phones) for flattened search
  /// Based on the guide: flatten emails[] and phones[] arrays
  static List<String> extractContactValues(List<Map<String, dynamic>> contacts) {
    return contacts.map((contact) {
      return contact['value'] as String? ?? '';
    }).where((value) => value.isNotEmpty).toList();
  }

  /// Generate name tokens for better search
  /// Split by spaces and common separators
  static List<String> generateNameTokens(String name) {
    if (name.isEmpty) return [];
    
    final tokens = <String>{};
    
    // Add original name
    tokens.add(name);
    
    // Split by spaces and common separators
    final parts = name.split(RegExp(r'[\s\-_.,()]+'));
    
    for (final part in parts) {
      if (part.trim().isNotEmpty) {
        tokens.add(part.trim());
      }
    }
    
    return tokens.toList();
  }

  /// Generate tax ID tokens for better search
  /// Create variants for partial matching
  static List<String> generateTaxIdTokens(String taxId) {
    if (taxId.isEmpty) return [];
    
    final tokens = <String>{};
    
    // Add original tax ID
    tokens.add(taxId);
    
    // Remove non-digits for pure number search
    final digits = taxId.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isNotEmpty && digits != taxId) {
      tokens.add(digits);
      
      // Create suffix variants for partial matching (last 4, 6, 8 digits)
      if (digits.length >= 4) {
        tokens.add(digits.substring(digits.length - 4));
      }
      if (digits.length >= 6) {
        tokens.add(digits.substring(digits.length - 6));
      }
      if (digits.length >= 8) {
        tokens.add(digits.substring(digits.length - 8));
      }
    }
    
    return tokens.toList();
  }
}