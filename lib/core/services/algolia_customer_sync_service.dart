import 'package:dio/dio.dart';
import '../../../domain/entities/customer.dart';
import 'logger_service.dart';
import 'algolia_config.dart';

/// Service for syncing customer data with Algolia search index
/// Uses REST API calls for reliable data synchronization
class AlgoliaCustomerSyncService {
  static final LoggerService _logger = LoggerService.to;
  static final Dio _dio = Dio();
  
  // Admin API key for write operations
  static const String _adminApiKey = 'a9f2dae0edfbe5795fbdd980179eddca';
  static const String _indexName = 'customers';
  
  /// Sync a single customer to Algolia
  static Future<void> syncCustomerToAlgolia(Customer customer) async {
    try {
      _logger.info('🔍 Syncing customer to Algolia: ${customer.name} (${customer.id})');
      
      // Build the record for Algolia
      final record = buildCustomerRecord(customer);
      
      // Send to Algolia using REST API
      final response = await _dio.put(
        'https://${AlgoliaConfig.appId.toLowerCase()}-dsn.algolia.net/1/indexes/$_indexName/${customer.id}',
        data: record,
        options: Options(
          headers: {
            'X-Algolia-API-Key': _adminApiKey,
            'X-Algolia-Application-Id': AlgoliaConfig.appId,
            'Content-Type': 'application/json',
          },
        ),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        _logger.info('✅ Customer synced to Algolia successfully: ${customer.id}');
      } else {
        _logger.error('❌ Failed to sync customer to Algolia: ${customer.id}, status: ${response.statusCode}');
      }
    } catch (error) {
      _logger.error('❌ Failed to sync customer to Algolia: ${customer.id}, error: $error');
      // Don't throw - we don't want Algolia sync failures to break customer operations
    }
  }
  
  /// Remove a customer from Algolia
  static Future<void> syncCustomerDeletionToAlgolia(String customerId) async {
    try {
      _logger.info('🗑️ Removing customer from Algolia: $customerId');
      
      final response = await _dio.delete(
        'https://${AlgoliaConfig.appId.toLowerCase()}-dsn.algolia.net/1/indexes/$_indexName/$customerId',
        options: Options(
          headers: {
            'X-Algolia-API-Key': _adminApiKey,
            'X-Algolia-Application-Id': AlgoliaConfig.appId,
          },
        ),
      );
      
      if (response.statusCode == 200) {
        _logger.info('✅ Customer removed from Algolia successfully: $customerId');
      } else {
        _logger.error('❌ Failed to remove customer from Algolia: $customerId, status: ${response.statusCode}');
      }
    } catch (error) {
      _logger.error('❌ Failed to remove customer from Algolia: $customerId, error: $error');
    }
  }
  
  /// Sync multiple customers to Algolia (for batch operations)
  static Future<void> syncMultipleCustomers(List<Customer> customers) async {
    try {
      _logger.info('🔄 Syncing ${customers.length} customers to Algolia...');
      
      if (customers.isEmpty) {
        _logger.warning('No customers to sync to Algolia');
        return;
      }
      
      // Build records for all customers
      final records = customers.map((customer) => buildCustomerRecord(customer)).toList();
      
      // Send batch request to Algolia
      final response = await _dio.post(
        'https://${AlgoliaConfig.appId.toLowerCase()}-dsn.algolia.net/1/indexes/$_indexName/batch',
        data: {
          'requests': records.map((record) => {
            'action': 'updateObject',
            'body': record,
          }).toList(),
        },
        options: Options(
          headers: {
            'X-Algolia-API-Key': _adminApiKey,
            'X-Algolia-Application-Id': AlgoliaConfig.appId,
            'Content-Type': 'application/json',
          },
        ),
      );
      
      if (response.statusCode == 200) {
        _logger.info('✅ Batch sync of ${customers.length} customers completed successfully');
      } else {
        _logger.error('❌ Batch sync failed, falling back to individual sync');
        // Fallback to individual sync
        for (final customer in customers) {
          await syncCustomerToAlgolia(customer);
          // Small delay to avoid overwhelming the API
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }
    } catch (error) {
      _logger.error('❌ Batch sync failed: $error, falling back to individual sync');
      // Fallback to individual sync
      for (final customer in customers) {
        await syncCustomerToAlgolia(customer);
        // Small delay to avoid overwhelming the API
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }
  }
  
  /// Build Algolia record for a customer
  /// Based on the guide: objectID, workspaceId, name, customId, emails, phones, companyNames, hashtags, assignees, updatedAt
  static Map<String, dynamic> buildCustomerRecord(Customer customer) {
    return {
      'objectID': customer.id,
      'workspaceId': customer.workspaceId,
      'name': customer.name,
      'customId': customer.customId,
      'prefix': customer.prefix,
      'nationalId': customer.nationalId,
      'address': customer.address,
      'age': customer.age,
      'gender': customer.gender,
      'customerType': customer.customerType,
      'source': customer.source,
      'emails': extractEmailValues(customer.emails),
      'phones': extractPhoneValues(customer.phones),
      'companyNames': extractCompanyNames(customer.companyNames),
      'hashtags': extractHashtagTexts(customer.hashtags),
      'assignees': customer.assignees,
      'updatedAt': customer.updatedAt.millisecondsSinceEpoch,
      'createdAt': customer.createdAt.millisecondsSinceEpoch,
      // Additional searchable fields
      'searchableKeywords': generateCustomerSearchKeywords(customer),
    };
  }
  
  /// Extract email values for search
  static List<String> extractEmailValues(List<Map<String, dynamic>> emails) {
    return emails.map((email) => email['value']?.toString() ?? '').where((value) => value.isNotEmpty).toList();
  }
  
  /// Extract phone values for search
  static List<String> extractPhoneValues(List<Map<String, dynamic>> phones) {
    return phones.map((phone) => phone['value']?.toString() ?? '').where((value) => value.isNotEmpty).toList();
  }
  
  /// Extract company names for search
  static List<String> extractCompanyNames(List<Map<String, dynamic>> companies) {
    return companies.map((company) => company['value']?.toString() ?? '').where((value) => value.isNotEmpty).toList();
  }
  
  /// Extract hashtag texts for search
  static List<String> extractHashtagTexts(List<Map<String, dynamic>> hashtags) {
    return hashtags.map((hashtag) => hashtag['text']?.toString() ?? hashtag['name']?.toString() ?? '').where((text) => text.isNotEmpty).toList();
  }
  
  /// Generate searchable keywords for better search
  static List<String> generateCustomerSearchKeywords(Customer customer) {
    final keywords = <String>[];
    
    // Add name variations
    if (customer.name.isNotEmpty) {
      keywords.add(customer.name);
      keywords.addAll(customer.name.split(' '));
    }
    
    // Add custom ID
    if (customer.customId.isNotEmpty) {
      keywords.add(customer.customId);
    }
    
    // Add prefix
    if (customer.prefix.isNotEmpty) {
      keywords.add(customer.prefix);
    }
    
    // Add company names
    keywords.addAll(extractCompanyNames(customer.companyNames));
    
    // Add hashtags
    keywords.addAll(extractHashtagTexts(customer.hashtags));
    
    // Remove duplicates and empty strings
    return keywords.toSet().where((keyword) => keyword.isNotEmpty).toList();
  }
}