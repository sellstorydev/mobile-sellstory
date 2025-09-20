/// Algolia Search Configuration
/// Contains API keys and indices for Algolia search functionality
class AlgoliaConfig {
  // Algolia Search (Client) - Safe for client-side use
  static const String appId = "0XBX5OR2Y7";
  static const String searchApiKey = "7006bd568392979bc98d5e18a4c9ca47";
  
  // Index names for different document types
  static const String customersIndex = "customers";
  static const String companiesIndex = "companies";
  static const String productsIndex = "products";
  static const String quotationsIndex = "quotations";
  static const String invoicesIndex = "invoices";
  static const String receiptsIndex = "receipts";
  
  // Admin API key - NOT exposed to client, for reference only
  // static const String _adminApiKey = "a9f2dae0edfbe5795fbdd980179eddca";
  
  /// Get search configuration for a specific entity type
  static Map<String, String> getSearchConfig(String entityType) {
    return {
      'appId': appId,
      'apiKey': searchApiKey,
      'indexName': _getIndexName(entityType),
    };
  }
  
  /// Get index name for entity type
  static String _getIndexName(String entityType) {
    switch (entityType.toLowerCase()) {
      case 'customers':
        return customersIndex;
      case 'companies':
        return companiesIndex;
      case 'products':
        return productsIndex;
      case 'quotations':
        return quotationsIndex;
      case 'invoices':
        return invoicesIndex;
      case 'receipts':
        return receiptsIndex;
      default:
        throw ArgumentError('Unknown entity type: $entityType');
    }
  }
}