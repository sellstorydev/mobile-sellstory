import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../services/firestore_service.dart';
import '../../domain/entities/product.dart';
import '../../core/services/logger_service.dart';
import '../../core/services/algolia_product_sync_service.dart';

class ProductRepository {
  final FirestoreService _firestoreService = Get.find<FirestoreService>();
  final LoggerService _logger = Get.find<LoggerService>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get real-time stream of products for a workspace
  Stream<List<Product>> getProductsStream(String workspaceId) {
    try {
      _logger.methodEntry('ProductRepository.getProductsStream', {
        'workspaceId': workspaceId,
      });

      return _firestore
          .collection('workspaces')
          .doc(workspaceId)
          .collection('products')
          .snapshots()
          .map((snapshot) {
            final products = <Product>[];
            for (final doc in snapshot.docs) {
              try {
                final product = Product.fromMap(doc.data(), doc.id);
                // Filter active products in memory to avoid composite index requirement
                products.add(product);
              } catch (e) {
                _logger.error('Error parsing product ${doc.id}: $e');
              }
            }
            // Sort by createdAt in memory
            products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return products;
          });
    } catch (e) {
      _logger.error('Error getting products stream: $e');
      return Stream.value([]);
    }
  }

  // Get products with search functionality
  Stream<List<Product>> searchProducts(String workspaceId, String searchTerm) {
    try {
      _logger.methodEntry('ProductRepository.searchProducts', {
        'workspaceId': workspaceId,
        'searchTerm': searchTerm,
      });

      if (searchTerm.isEmpty) {
        return getProductsStream(workspaceId);
      }

      return _firestore
          .collection('workspaces')
          .doc(workspaceId)
          .collection('products')
          .snapshots()
          .map((snapshot) {
            final products = <Product>[];
            final lowerSearchTerm = searchTerm.toLowerCase();

            for (final doc in snapshot.docs) {
              try {
                final product = Product.fromMap(doc.data(), doc.id);

                // Filter active products and search in memory
                // Search in name, description, sku, and searchableKeywords
                final matchesSearch =
                    product.name.toLowerCase().contains(lowerSearchTerm) ||
                    product.description.toLowerCase().contains(
                      lowerSearchTerm,
                    ) ||
                    product.sku.toLowerCase().contains(lowerSearchTerm) ||
                    product.searchableKeywords.any(
                      (keyword) =>
                          keyword.toLowerCase().contains(lowerSearchTerm),
                    );

                if (matchesSearch) {
                  products.add(product);
                }
              } catch (e) {
                _logger.error('Error parsing product ${doc.id}: $e');
              }
            }
            // Sort by createdAt in memory
            products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return products;
          });
    } catch (e) {
      _logger.error('Error searching products: $e');
      return Stream.value([]);
    }
  }

  // Get a single product by ID
  Future<Product?> getProduct(String workspaceId, String productId) async {
    try {
      _logger.methodEntry('ProductRepository.getProduct', {
        'workspaceId': workspaceId,
        'productId': productId,
      });

      final doc = await _firestore
          .collection('workspaces')
          .doc(workspaceId)
          .collection('products')
          .doc(productId)
          .get();

      if (doc.exists) {
        return Product.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      _logger.error('Error getting product: $e');
      return null;
    }
  }

  // Create a new product
  Future<String?> createProduct(String workspaceId, Product product) async {
    try {
      _logger.methodEntry('ProductRepository.createProduct', {
        'workspaceId': workspaceId,
        'productName': product.name,
      });

      final docRef = await _firestore
          .collection('workspaces')
          .doc(workspaceId)
          .collection('products')
          .add(product.toMap());

      // Create the product with the generated ID
      final createdProduct = product.copyWith(id: docRef.id);

      // Sync to Algolia after successful Firestore operation
      await AlgoliaProductSyncService.syncProductToAlgolia(createdProduct);

      _logger.methodExit('ProductRepository.createProduct', {
        'productId': docRef.id,
      });

      return docRef.id;
    } catch (e) {
      _logger.error('Error creating product: $e');
      return null;
    }
  }

  // Update an existing product
  Future<bool> updateProduct(String workspaceId, Product product) async {
    try {
      _logger.methodEntry('ProductRepository.updateProduct', {
        'workspaceId': workspaceId,
        'productId': product.id,
      });

      await _firestore
          .collection('workspaces')
          .doc(workspaceId)
          .collection('products')
          .doc(product.id)
          .update(product.toMap());

      // Sync to Algolia after successful Firestore operation
      await AlgoliaProductSyncService.syncProductToAlgolia(product);

      _logger.methodExit('ProductRepository.updateProduct', {'success': true});

      return true;
    } catch (e) {
      _logger.error('Error updating product: $e');
      return false;
    }
  }

  // Delete a product
  Future<bool> deleteProduct(String workspaceId, String productId) async {
    try {
      _logger.methodEntry('ProductRepository.deleteProduct', {
        'workspaceId': workspaceId,
        'productId': productId,
      });

      await _firestore
          .collection('workspaces')
          .doc(workspaceId)
          .collection('products')
          .doc(productId)
          .delete();

      // Sync deletion to Algolia after successful Firestore operation
      await AlgoliaProductSyncService.syncProductDeletionToAlgolia(productId, workspaceId);

      _logger.methodExit('ProductRepository.deleteProduct', {'success': true});

      return true;
    } catch (e) {
      _logger.error('Error deleting product: $e');
      return false;
    }
  }

  // Get products count
  Future<int> getProductsCount(String workspaceId) async {
    try {
      final snapshot = await _firestore
          .collection('workspaces')
          .doc(workspaceId)
          .collection('products')
          .get();

      // Count active products in memory
      int count = 0;
      for (final doc in snapshot.docs) {
        try {
          final product = Product.fromMap(doc.data(), doc.id);
          count++;
        } catch (e) {
          _logger.error('Error parsing product ${doc.id}: $e');
        }
      }
      return count;
    } catch (e) {
      _logger.error('Error getting products count: $e');
      return 0;
    }
  }
}
