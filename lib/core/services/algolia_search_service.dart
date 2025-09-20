import 'package:algolia_helper_flutter/algolia_helper_flutter.dart';
import 'algolia_config.dart';

/// Unified Algolia Search Service
/// Provides search functionality for all entity types (customers, products, documents)
class AlgoliaSearchService {
  static final Map<String, HitsSearcher> _searchers = {};
  
  /// Get or create a searcher for the specified entity type
  static HitsSearcher _getSearcher(String entityType) {
    if (!_searchers.containsKey(entityType)) {
      final config = AlgoliaConfig.getSearchConfig(entityType);
      
      _searchers[entityType] = HitsSearcher(
        applicationID: config['appId']!,
        apiKey: config['apiKey']!,
        indexName: config['indexName']!,
      );
    }
    return _searchers[entityType]!;
  }
  
  /// Search customers
  static Stream<SearchResponse> searchCustomers({
    required String query,
    required String workspaceId,
    Map<String, dynamic>? filters,
    int? hitsPerPage,
  }) {
    return _search(
      entityType: 'customers',
      query: query,
      workspaceId: workspaceId,
      filters: filters,
      hitsPerPage: hitsPerPage,
    );
  }
  
  /// Search companies
  static Stream<SearchResponse> searchCompanies({
    required String query,
    required String workspaceId,
    Map<String, dynamic>? filters,
    int? hitsPerPage,
  }) {
    return _search(
      entityType: 'companies',
      query: query,
      workspaceId: workspaceId,
      filters: filters,
      hitsPerPage: hitsPerPage,
    );
  }
  
  /// Search products
  static Stream<SearchResponse> searchProducts({
    required String query,
    required String workspaceId,
    Map<String, dynamic>? filters,
    int? hitsPerPage,
  }) {
    return _search(
      entityType: 'products',
      query: query,
      workspaceId: workspaceId,
      filters: filters,
      hitsPerPage: hitsPerPage,
    );
  }
  
  /// Search quotations
  static Stream<SearchResponse> searchQuotations({
    required String query,
    required String workspaceId,
    Map<String, dynamic>? filters,
    int? hitsPerPage,
  }) {
    return _search(
      entityType: 'quotations',
      query: query,
      workspaceId: workspaceId,
      filters: filters,
      hitsPerPage: hitsPerPage,
    );
  }
  
  /// Search invoices
  static Stream<SearchResponse> searchInvoices({
    required String query,
    required String workspaceId,
    Map<String, dynamic>? filters,
    int? hitsPerPage,
  }) {
    return _search(
      entityType: 'invoices',
      query: query,
      workspaceId: workspaceId,
      filters: filters,
      hitsPerPage: hitsPerPage,
    );
  }
  
  /// Search receipts
  static Stream<SearchResponse> searchReceipts({
    required String query,
    required String workspaceId,
    Map<String, dynamic>? filters,
    int? hitsPerPage,
  }) {
    return _search(
      entityType: 'receipts',
      query: query,
      workspaceId: workspaceId,
      filters: filters,
      hitsPerPage: hitsPerPage,
    );
  }
  
  /// Generic search method
  static Stream<SearchResponse> _search({
    required String entityType,
    required String query,
    required String workspaceId,
    Map<String, dynamic>? filters,
    int? hitsPerPage,
  }) {
    final searcher = _getSearcher(entityType);
    
    // Update searcher with query
    searcher.query(query);
    
    // Build filter string
    final filterStrings = <String>['workspaceId:$workspaceId'];
    
    if (filters != null) {
      filters.forEach((key, value) {
        if (value is List) {
          // Handle array filters (e.g., status IN [draft, sent])
          final valueStr = value.map((v) => '"$v"').join(',');
          filterStrings.add('$key:[$valueStr]');
        } else {
          // Handle single value filters
          filterStrings.add('$key:"$value"');
        }
      });
    }
    
    // Apply state with filters
    final filterExpression = filterStrings.join(' AND ');
    searcher.applyState((state) => state.copyWith(
      facetFilters: [filterExpression],
      hitsPerPage: hitsPerPage,
    ));
    
    return searcher.responses;
  }
  
  /// Update search query for existing searcher
  static void updateQuery(String entityType, String query) {
    if (_searchers.containsKey(entityType)) {
      _searchers[entityType]!.query(query);
    }
  }
  
  /// Clear search results
  static void clearSearch(String entityType) {
    if (_searchers.containsKey(entityType)) {
      _searchers[entityType]!.query('');
    }
  }
  
  /// Dispose searcher for entity type
  static void disposeSearcher(String entityType) {
    if (_searchers.containsKey(entityType)) {
      _searchers[entityType]!.dispose();
      _searchers.remove(entityType);
    }
  }
  
  /// Dispose all searchers
  static void disposeAll() {
    for (final searcher in _searchers.values) {
      searcher.dispose();
    }
    _searchers.clear();
  }
}