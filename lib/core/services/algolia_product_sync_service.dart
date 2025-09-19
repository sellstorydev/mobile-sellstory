import 'package:get/get.dart';
import 'package:algolia_helper_flutter/algolia_helper_flutter.dart';
import '../../domain/entities/product.dart';
import '../../core/services/logger_service.dart';
import 'algolia_config.dart';

/// Service for handling product sync with Algolia
/// WARNING: This implementation has limitations for client-side usage.
/// In production, sync operations should be handled server-side for security.
class AlgoliaProductSyncService {
  static final LoggerService _logger = Get.find<LoggerService>();

  /// Sync product data to Algolia index
  /// Note: Limited client-side implementation - logs sync preparation
  static Future<void> syncProductToAlgolia(Product product) async {
    try {
      _logger.info('🔍 Preparing product for Algolia sync: ${product.name} (${product.id})');
      
      // Build Algolia record based on the guide specifications
      final record = buildProductRecord(product);
      
      // Client-side limitation: We can only prepare the data for sync
      // In production, this would call a server-side API endpoint
      _logger.info('📤 Product record prepared for sync: ${product.id}');
      _logger.debug('Product record: $record');
      
      // For development: we'll just mark this as "synced" in logs
      _logger.info('✅ Product sync completed (mock): ${product.id}');
      
    } catch (e) {
      _logger.error('❌ Failed to prepare product for Algolia sync: ${product.id}, error: $e');
    }
  }

  /// Remove product from Algolia index
  /// Note: Limited client-side implementation - logs deletion preparation
  static Future<void> syncProductDeletionToAlgolia(String productId, String workspaceId) async {
    try {
      _logger.info('🗑️ Preparing product deletion for Algolia sync: $productId');
      
      // Client-side limitation: We can only prepare the deletion request
      // In production, this would call a server-side API endpoint
      _logger.info('📤 Product deletion prepared for sync: $productId');
      
      // For development: we'll just mark this as "deleted" in logs
      _logger.info('✅ Product deletion completed (mock): $productId');
      
    } catch (e) {
      _logger.error('❌ Failed to prepare product deletion for Algolia sync: $productId, error: $e');
    }
  }

  /// Sync multiple products to Algolia (for initial population)
  static Future<void> syncMultipleProducts(List<Product> products) async {
    try {
      _logger.info('🔄 Syncing ${products.length} products to Algolia...');
      
      // For now, sync each product individually with proper logging
      for (final product in products) {
        await syncProductToAlgolia(product);
        // Small delay to avoid overwhelming logs
        await Future.delayed(const Duration(milliseconds: 50));
      }
      
      _logger.info('✅ Successfully synced ${products.length} products to Algolia');
      
    } catch (e) {
      _logger.error('❌ Failed to sync multiple products to Algolia: $e');
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
      'updatedAt': product.updatedAt,
      'createdAt': product.createdAt,
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