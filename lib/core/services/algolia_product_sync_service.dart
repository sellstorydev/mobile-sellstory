import 'package:get/get.dart';
import '../../domain/entities/product.dart';
import '../../core/services/logger_service.dart';
import 'algolia_config.dart';
import 'package:dio/dio.dart';

/// Service for handling product sync with Algolia
/// This implementation performs actual sync operations to Algolia database
class AlgoliaProductSyncService {
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

  /// Sync product data to Algolia index
  /// Performs actual saveObject operation via REST API
  static Future<void> syncProductToAlgolia(Product product) async {
    try {
      _logger.info('🔍 Syncing product to Algolia: ${product.name} (${product.id})');
      
      // Build Algolia record based on the guide specifications
      final record = buildProductRecord(product);
      
      // Save the object to Algolia via REST API
      final response = await _dio.put(
        '/1/indexes/${AlgoliaConfig.productsIndex}/${product.id}',
        data: record,
      );
      
      _logger.info('📤 Product synced to Algolia successfully: ${product.id}');
      _logger.debug('Algolia response: ${response.data}');
      _logger.info('✅ Product sync completed: ${product.id}');
      
    } catch (e) {
      _logger.error('❌ Failed to sync product to Algolia: ${product.id}, error: $e');
      // Don't throw - we want product operations to succeed even if Algolia fails
    }
  }

  /// Remove product from Algolia index
  /// Performs actual deleteObject operation via REST API
  static Future<void> syncProductDeletionToAlgolia(String productId, String workspaceId) async {
    try {
      _logger.info('🗑️ Deleting product from Algolia: $productId');
      
      // Delete the object from Algolia via REST API
      final response = await _dio.delete(
        '/1/indexes/${AlgoliaConfig.productsIndex}/$productId',
      );
      
      _logger.info('📤 Product deleted from Algolia successfully: $productId');
      _logger.debug('Algolia response: ${response.data}');
      _logger.info('✅ Product deletion completed: $productId');
      
    } catch (e) {
      _logger.error('❌ Failed to delete product from Algolia: $productId, error: $e');
      // Don't throw - we want product operations to succeed even if Algolia fails
    }
  }

  /// Sync multiple products to Algolia (for initial population)
  /// Uses batch API for better performance
  static Future<void> syncMultipleProducts(List<Product> products) async {
    try {
      _logger.info('🔄 Syncing ${products.length} products to Algolia...');
      
      if (products.isEmpty) {
        _logger.warning('No products to sync to Algolia');
        return;
      }
      
      // Build records for all products
      final records = products.map((product) => buildProductRecord(product)).toList();
      
      // Use batch API for better performance
      final response = await _dio.post(
        '/1/indexes/${AlgoliaConfig.productsIndex}/batch',
        data: {
          'requests': records.map((record) => {
            'action': 'addObject',
            'body': record,
          }).toList(),
        },
      );
      
      _logger.info('📤 Batch sync to Algolia completed');
      _logger.debug('Algolia batch response: ${response.data}');
      _logger.info('✅ Successfully synced ${products.length} products to Algolia');
      
    } catch (e) {
      _logger.error('❌ Failed to sync multiple products to Algolia: $e');
      // Fallback to individual sync
      _logger.info('📝 Falling back to individual sync...');
      for (final product in products) {
        await syncProductToAlgolia(product);
        // Small delay to avoid overwhelming the API
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }
  }

  /// Build Algolia record for a product
  /// Based on the guide: objectID, workspaceId, name, sku, skuTokens, status, category, price, hashtags, updatedAt
  static Map<String, dynamic> buildProductRecord(Product product) {
    return {
      'objectID': product.id,
      'workspaceId': product.workspaceId,
      'name': product.name,
      'sku': product.sku,
      'skuTokens': generateSkuTokens(product.sku),
      'status': product.status,
      'category': product.category,
      'price': product.price,
      'hashtags': extractHashtagTexts(product.hashtags),
      'description': product.description,
      'unit': product.unit,
      'imageUrl': product.imageUrl,
      'updatedAt': product.updatedAt.millisecondsSinceEpoch,
      'createdAt': product.createdAt.millisecondsSinceEpoch,
      // Additional searchable fields
      'searchableKeywords': product.searchableKeywords,
    };
  }

  /// Generate SKU tokens for better search
  /// Based on the guide: split by non-alphanumeric, extract digits, create variants
  static List<String> generateSkuTokens(String sku) {
    if (sku.isEmpty) return [];
    
    final tokens = <String>{};
    
    // Add original SKU
    tokens.add(sku);
    
    // Split by non-alphanumeric characters and process each part
    final parts = sku.split(RegExp(r'[^A-Za-z0-9]+'));
    
    for (final part in parts) {
      if (part.isEmpty) continue;
      
      tokens.add(part);
      
      // Extract digits from the part
      final digits = part.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.isNotEmpty) {
        tokens.add(digits);
        
        // Remove leading zeros
        final digitsNoLeadingZeros = digits.replaceFirst(RegExp(r'^0+'), '');
        if (digitsNoLeadingZeros.isNotEmpty && digitsNoLeadingZeros != digits) {
          tokens.add(digitsNoLeadingZeros);
        }
        
        // Create suffix variants for partial matching
        for (int i = 1; i <= digits.length; i++) {
          final suffix = digits.substring(digits.length - i);
          tokens.add(suffix);
        }
      }
    }
    
    return tokens.toList();
  }

  /// Extract hashtag texts for search
  static List<String> extractHashtagTexts(List<Map<String, dynamic>> hashtags) {
    return hashtags.map((hashtag) {
      return hashtag['text'] as String? ?? hashtag['name'] as String? ?? '';
    }).where((text) => text.isNotEmpty).toList();
  }
}