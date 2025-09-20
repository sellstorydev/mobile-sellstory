import 'package:dio/dio.dart';
import 'logger_service.dart';
import 'algolia_config.dart';

/// Service for syncing document data with Algolia search index
/// Handles quotations, invoices, and receipts
/// Uses REST API calls for reliable data synchronization
class AlgoliaDocumentSyncService {
  static final LoggerService _logger = LoggerService.to;
  static final Dio _dio = Dio();
  
  // Admin API key for write operations
  static const String _adminApiKey = 'a9f2dae0edfbe5795fbdd980179eddca';
  
  // Index names for different document types
  static const String _quotationsIndex = 'quotations';
  static const String _invoicesIndex = 'invoices';
  static const String _receiptsIndex = 'receipts';
  
  /// Sync a document to the appropriate Algolia index based on type
  static Future<void> syncDocumentToAlgolia(Map<String, dynamic> document) async {
    try {
      final indexName = _getIndexNameForDocumentType(document['type'] ?? 'QT');
      _logger.info('🔍 Syncing ${document['type']} to Algolia: ${document['docNo']} (${document['id']})');
      
      // Build the record for Algolia
      final record = buildDocumentRecord(document);
      
      // Send to Algolia using REST API
      final response = await _dio.put(
        'https://${AlgoliaConfig.appId.toLowerCase()}-dsn.algolia.net/1/indexes/$indexName/${document['id']}',
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
        _logger.info('✅ ${document['type']} synced to Algolia successfully: ${document['id']}');
      } else {
        _logger.error('❌ Failed to sync ${document['type']} to Algolia: ${document['id']}, status: ${response.statusCode}');
      }
    } catch (error) {
      _logger.error('❌ Failed to sync ${document['type']} to Algolia: ${document['id']}, error: $error');
      // Don't throw - we don't want Algolia sync failures to break document operations
    }
  }
  
  /// Remove a document from Algolia
  static Future<void> syncDocumentDeletionToAlgolia(String documentId, String documentType) async {
    try {
      final indexName = _getIndexNameForDocumentType(documentType);
      _logger.info('🗑️ Removing $documentType from Algolia: $documentId');
      
      final response = await _dio.delete(
        'https://${AlgoliaConfig.appId.toLowerCase()}-dsn.algolia.net/1/indexes/$indexName/$documentId',
        options: Options(
          headers: {
            'X-Algolia-API-Key': _adminApiKey,
            'X-Algolia-Application-Id': AlgoliaConfig.appId,
          },
        ),
      );
      
      if (response.statusCode == 200) {
        _logger.info('✅ $documentType removed from Algolia successfully: $documentId');
      } else {
        _logger.error('❌ Failed to remove $documentType from Algolia: $documentId, status: ${response.statusCode}');
      }
    } catch (error) {
      _logger.error('❌ Failed to remove $documentType from Algolia: $documentId, error: $error');
    }
  }
  
  /// Sync multiple documents to Algolia (for batch operations)
  static Future<void> syncMultipleDocuments(List<Map<String, dynamic>> documents) async {
    try {
      _logger.info('🔄 Syncing ${documents.length} documents to Algolia...');
      
      if (documents.isEmpty) {
        _logger.warning('No documents to sync to Algolia');
        return;
      }
      
      // Group documents by type for batch operations
      final documentsByType = <String, List<Map<String, dynamic>>>{};
      for (final doc in documents) {
        final docType = doc['type']?.toString() ?? 'QT';
        documentsByType.putIfAbsent(docType, () => []).add(doc);
      }
      
      // Process each type separately
      for (final entry in documentsByType.entries) {
        await _syncDocumentsBatch(entry.value, entry.key);
      }
    } catch (error) {
      _logger.error('❌ Batch sync failed: $error, falling back to individual sync');
      // Fallback to individual sync
      for (final document in documents) {
        await syncDocumentToAlgolia(document);
        // Small delay to avoid overwhelming the API
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }
  }
  
  /// Internal method to sync a batch of documents of the same type
  static Future<void> _syncDocumentsBatch(List<Map<String, dynamic>> documents, String documentType) async {
    try {
      final indexName = _getIndexNameForDocumentType(documentType);
      final records = documents.map((doc) => buildDocumentRecord(doc)).toList();
      
      // Send batch request to Algolia
      final response = await _dio.post(
        'https://${AlgoliaConfig.appId.toLowerCase()}-dsn.algolia.net/1/indexes/$indexName/batch',
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
        _logger.info('✅ Batch sync of ${documents.length} $documentType documents completed successfully');
      } else {
        _logger.error('❌ Batch sync failed for $documentType, falling back to individual sync');
        // Fallback to individual sync
        for (final document in documents) {
          await syncDocumentToAlgolia(document);
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }
    } catch (error) {
      _logger.error('❌ Batch sync failed for $documentType: $error');
      // Fallback to individual sync
      for (final document in documents) {
        await syncDocumentToAlgolia(document);
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }
  }
  
  /// Get the appropriate index name for a document type
  static String _getIndexNameForDocumentType(String documentType) {
    switch (documentType.toUpperCase()) {
      case 'QT':
        return _quotationsIndex;
      case 'INV':
        return _invoicesIndex;
      case 'RT':
        return _receiptsIndex;
      default:
        _logger.warning('Unknown document type: $documentType, using quotations index as fallback');
        return _quotationsIndex;
    }
  }
  
  /// Build Algolia record for a document
  /// Based on the guide: objectID, workspaceId, docNo, jobName, jobCardId, customerName, sellerName, status, updatedAt
  static Map<String, dynamic> buildDocumentRecord(Map<String, dynamic> document) {
    return {
      'objectID': document['id'],
      'workspaceId': document['workspaceId'],
      'docNo': document['docNo'],
      'docNoTokens': generateDocNoTokens(document['docNo']?.toString() ?? ''),
      'type': document['type'],
      'status': document['status'],
      'jobName': extractJobName(document),
      'jobCardId': document['jobCardId'],
      'jobCardTokens': generateJobCardTokens(document['jobCardId']?.toString()),
      'customerName': extractCustomerName(document['customer']),
      'sellerName': extractSellerName(document['seller']),
      'subtotal': document['subtotal'],
      'discount': document['discount'],
      'vatAmount': document['vatAmount'],
      'grandTotal': document['grandTotal'],
      'notes': document['notes'],
      'paymentMethod': document['paymentMethod'],
      'updatedAt': document['updatedAt'],
      'createdAt': document['createdAt'],
      // Additional searchable fields based on document type
      ...buildTypeSpecificFields(document),
    };
  }
  
  /// Generate document number tokens for better search
  static List<String> generateDocNoTokens(String docNo) {
    if (docNo.isEmpty) return [];
    
    final tokens = <String>{};
    tokens.add(docNo); // Full docNo
    
    // Split by non-alphanumeric characters
    final parts = docNo.split(RegExp(r'[^A-Za-z0-9]+'));
    for (final part in parts) {
      if (part.isNotEmpty) {
        tokens.add(part);
        
        // Extract digits and create variants
        final digits = part.replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.isNotEmpty) {
          tokens.add(digits);
          // Remove leading zeros
          final withoutLeadingZeros = digits.replaceFirst(RegExp(r'^0+'), '');
          if (withoutLeadingZeros.isNotEmpty) {
            tokens.add(withoutLeadingZeros);
          }
          
          // Add suffixes of digits for partial matching
          for (int i = 1; i <= digits.length; i++) {
            tokens.add(digits.substring(digits.length - i));
          }
        }
      }
    }
    
    return tokens.toList();
  }
  
  /// Generate job card tokens for better search
  static List<String> generateJobCardTokens(String? jobCardId) {
    if (jobCardId == null || jobCardId.isEmpty) return [];
    return generateDocNoTokens(jobCardId); // Use same logic as docNo
  }
  
  /// Extract customer name for search
  static String extractCustomerName(dynamic customer) {
    if (customer == null) return '';
    if (customer is Map<String, dynamic>) {
      return customer['name']?.toString() ?? customer['displayName']?.toString() ?? '';
    }
    return customer.toString();
  }
  
  /// Extract seller name for search
  static String extractSellerName(dynamic seller) {
    if (seller == null) return '';
    if (seller is Map<String, dynamic>) {
      return seller['displayName']?.toString() ?? seller['name']?.toString() ?? seller['email']?.toString() ?? '';
    }
    return seller.toString();
  }
  
  /// Extract job name from document
  static String extractJobName(Map<String, dynamic> document) {
    return document['jobName']?.toString() ?? '';
  }
  
  /// Build type-specific fields for different document types
  static Map<String, dynamic> buildTypeSpecificFields(Map<String, dynamic> document) {
    final fields = <String, dynamic>{};
    
    final docType = document['type']?.toString().toUpperCase() ?? 'QT';
    switch (docType) {
      case 'QT': // Quotation
        fields['validUntil'] = document['validUntil'];
        fields['approvers'] = document['approvers'];
        fields['depositInfo'] = document['depositInfo'];
        fields['invoicingPlan'] = document['invoicingPlan'];
        fields['approval'] = document['approval'];
        break;
        
      case 'INV': // Invoice
        fields['invoiceType'] = document['invoiceType'];
        fields['relatedQuotationId'] = document['relatedQuotationId'];
        fields['dueDate'] = document['dueDate'];
        fields['paymentStatus'] = document['paymentStatus'];
        fields['installmentNumber'] = document['installmentNumber'];
        fields['totalInstallments'] = document['totalInstallments'];
        fields['deductedDeposit'] = document['deductedDeposit'];
        break;
        
      case 'RT': // Receipt
        fields['relatedInvoiceId'] = document['relatedInvoiceId'];
        fields['paymentDate'] = document['paymentDate'];
        fields['receiptFor'] = document['receiptFor'];
        break;
    }
    
    return fields;
  }
}