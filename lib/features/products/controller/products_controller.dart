import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/firestore_repository.dart';
import '../../../domain/entities/product.dart';
import '../../../core/services/logger_service.dart';
import '../../../data/services/mobile_permissions_service.dart';

class ProductsController extends GetxController {
  final ProductRepository _repository = Get.find<ProductRepository>();
  final FirestoreRepository _firestoreRepository = Get.find<FirestoreRepository>();
  final LoggerService _logger = Get.find<LoggerService>();

  // Observable variables
  final RxList<Product> products = <Product>[].obs;
  final RxList<Product> filteredProducts = <Product>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isError = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString searchQuery = ''.obs;
  final RxInt productsCount = 0.obs;
  final RxInt productsQuotaUsed = 0.obs; // firestore reported used
  final RxInt productsQuotaLimit = (-2).obs; // -1 unlimited, -2 unknown

  // User and workspace data
  String _currentUserId = '';
  String _currentWorkspaceId = '';

  bool _can(String permission) =>
      MobilePermissionsService.to.isOwner || MobilePermissionsService.to.can(permission);

  @override
  void onInit() {
    super.onInit();
    _initializeUserAndWorkspace();
  }

  Future<void> _initializeUserAndWorkspace() async {
    try {
      // Get current user ID from Firebase Auth
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _logger.error('No authenticated user found');
        return;
      }
      
      _currentUserId = currentUser.uid;
      _logger.methodEntry('ProductsController._initializeUserAndWorkspace', {
        'userId': _currentUserId,
      });
      
      // Get user's workspaces
      final workspaces = await _firestoreRepository.getUserWorkspaces(_currentUserId);
      
      if (workspaces.isNotEmpty) {
        // Try to get last active workspace ID
        String? selectedWorkspaceId;
        String? selectedWorkspaceName;
        
        try {
          final lastActiveWorkspaceId = await _firestoreRepository.getUserLastActiveWorkspaceId(_currentUserId);
          _logger.info('Last active workspace ID: $lastActiveWorkspaceId');
          
          if (lastActiveWorkspaceId != null && lastActiveWorkspaceId.isNotEmpty) {
            // Check if the last active workspace still exists in user's workspaces
            final lastActiveWorkspace = workspaces.firstWhereOrNull(
              (ws) => ws['id'] == lastActiveWorkspaceId
            );
            
            if (lastActiveWorkspace != null) {
              selectedWorkspaceId = lastActiveWorkspaceId;
              selectedWorkspaceName = lastActiveWorkspace['name'] as String;
              _logger.info('Using last active workspace: $selectedWorkspaceName ($selectedWorkspaceId)');
            } else {
              _logger.warning('Last active workspace not found in user workspaces, using first workspace');
            }
          }
        } catch (e) {
          _logger.warning('Failed to get last active workspace: $e');
        }
        
        // Fallback to first workspace if no last active workspace
        if (selectedWorkspaceId == null) {
          final firstWorkspace = workspaces.first;
          selectedWorkspaceId = firstWorkspace['id'] as String;
          selectedWorkspaceName = firstWorkspace['name'] as String;
          _logger.info('Using first workspace: $selectedWorkspaceName ($selectedWorkspaceId)');
        }
        
        _currentWorkspaceId = selectedWorkspaceId;
        // Subscribe quota before loading products
        _subscribeWorkspaceQuota(_currentWorkspaceId);
        // Load products
        await loadProducts();
      } else {
        _logger.error('No workspaces found for user: $_currentUserId');
      }
    } catch (e) {
      _logger.error('Failed to initialize user and workspace: $e');
      isError.value = true;
      errorMessage.value = 'Failed to initialize: $e';
    }
  }

  Future<void> loadProducts() async {
    if (_currentWorkspaceId.isEmpty) return;

    try {
      isLoading.value = true;
      isError.value = false;
      errorMessage.value = '';

      _logger.methodEntry('ProductsController.loadProducts', {
        'workspaceId': _currentWorkspaceId,
      });

      // Listen to products stream
      _repository.getProductsStream(_currentWorkspaceId).listen(
        (productsList) {
          products.value = productsList;
          _filterProducts();
          _updateProductsCount();
        },
        onError: (error) {
          _logger.error('Error in products stream: $error');
          isError.value = true;
          errorMessage.value = 'Failed to load products: $error';
        },
      );
    } catch (e) {
      _logger.error('Error loading products: $e');
      isError.value = true;
      errorMessage.value = 'Failed to load products: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void searchProducts(String query) {
    searchQuery.value = query;
    _filterProducts();
  }

  void _filterProducts() {
    if (searchQuery.value.isEmpty) {
      filteredProducts.value = products;
    } else {
      final query = searchQuery.value.toLowerCase();
      filteredProducts.value = products.where((product) {
        return product.name.toLowerCase().contains(query) ||
               product.description.toLowerCase().contains(query) ||
               product.sku.toLowerCase().contains(query) ||
               product.searchableKeywords.any((keyword) => 
                   keyword.toLowerCase().contains(query));
      }).toList();
    }
  }

  Future<void> _updateProductsCount() async {
    if (_currentWorkspaceId.isNotEmpty) {
      productsCount.value = await _repository.getProductsCount(_currentWorkspaceId);
    }
  }

  void clearSearch() {
    searchQuery.value = '';
    _filterProducts();
  }

  Future<void> refreshProducts() async {
    await loadProducts();
  }

  // Get current workspace ID
  String get currentWorkspaceId => _currentWorkspaceId;

  // Get current user ID
  String get currentUserId => _currentUserId;

  // Add a new product
  Future<bool> addProduct(String workspaceId, Product product) async {
    if (!_can('product:create')) {
      _logger.error('Permission denied: product:create');
      errorMessage.value = 'Permission denied: product:create';
      return false;
    }
    try {
      _logger.methodEntry('ProductsController.addProduct', {
        'workspaceId': workspaceId,
        'productName': product.name,
      });

      final productId = await _repository.createProduct(workspaceId, product);
      
      if (productId != null) {
        _logger.methodExit('ProductsController.addProduct', {
          'productId': productId,
          'success': true,
        });
        return true;
      } else {
        _logger.error('Failed to create product');
        return false;
      }
    } catch (e) {
      _logger.error('Error adding product: $e');
      return false;
    }
  }

  // Update an existing product
  Future<bool> updateProduct(String workspaceId, Product product) async {
    if (!_can('product:edit:all')) {
      _logger.error('Permission denied: product:edit:all');
      errorMessage.value = 'Permission denied: product:edit:all';
      return false;
    }
    try {
      _logger.methodEntry('ProductsController.updateProduct', {
        'workspaceId': workspaceId,
        'productId': product.id,
      });

      final success = await _repository.updateProduct(workspaceId, product);
      
      if (success) {
        _logger.methodExit('ProductsController.updateProduct', {
          'success': true,
        });
      } else {
        _logger.error('Failed to update product');
      }
      
      return success;
    } catch (e) {
      _logger.error('Error updating product: $e');
      return false;
    }
  }

  // Get a single product by ID
  Future<Product?> getProduct(String workspaceId, String productId) async {
    try {
      _logger.methodEntry('ProductsController.getProduct', {
        'workspaceId': workspaceId,
        'productId': productId,
      });

      final product = await _repository.getProduct(workspaceId, productId);
      
      if (product != null) {
        _logger.methodExit('ProductsController.getProduct', {
          'productName': product.name,
          'success': true,
        });
      } else {
        _logger.error('Product not found: $productId');
      }
      
      return product;
    } catch (e) {
      _logger.error('Error getting product: $e');
      return null;
    }
  }

  // Delete a product
  Future<bool> deleteProduct(String workspaceId, String productId) async {
    if (!_can('product:delete')) {
      _logger.error('Permission denied: product:delete');
      errorMessage.value = 'Permission denied: product:delete';
      return false;
    }
    try {
      _logger.methodEntry('ProductsController.deleteProduct', {
        'workspaceId': workspaceId,
        'productId': productId,
      });

      final success = await _repository.deleteProduct(workspaceId, productId);
      
      if (success) {
        _logger.methodExit('ProductsController.deleteProduct', {
          'success': true,
        });
      } else {
        _logger.error('Failed to delete product');
      }
      
      return success;
    } catch (e) {
      _logger.error('Error deleting product: $e');
      return false;
    }
  }

  void _subscribeWorkspaceQuota(String workspaceId) {
    if (workspaceId.isEmpty) {
      productsQuotaUsed.value = 0;
      productsQuotaLimit.value = -2; // unknown
      return;
    }
    FirebaseFirestore.instance
        .collection('workspaces')
        .doc(workspaceId)
        .snapshots()
        .listen((snap) {
      if (!snap.exists) {
        productsQuotaUsed.value = 0;
        productsQuotaLimit.value = -2;
        return;
      }
      final data = snap.data() ?? {};
      final quotaRaw = data['quota'];
      if (quotaRaw is! Map<String, dynamic>) {
        productsQuotaUsed.value = 0;
        productsQuotaLimit.value = -2;
        return;
      }
      final quota = quotaRaw;
      int used = 0; int limit = -1; // unlimited default
      final entry = quota['products'];
      if (entry is Map) {
        final ru = entry['used'];
        final rl = entry['limit'] ?? entry['max'];
        if (ru is int) used = ru; else if (ru is String) used = int.tryParse(ru) ?? used;
        if (rl is int) limit = rl; else if (rl is String) limit = int.tryParse(rl) ?? limit;
      } else if (entry is int) {
        limit = entry;
      } else if (entry is String) {
        limit = int.tryParse(entry) ?? -1;
      }
      final usedContainer = quota['used'];
      if (usedContainer is Map) {
        final alt = usedContainer['products'];
        if (alt is int) used = alt; else if (alt is String) used = int.tryParse(alt) ?? used;
      }
      if (used < 0) used = 0;
      productsQuotaUsed.value = used;
      productsQuotaLimit.value = limit;
    }, onError: (e) {
      // Keep previous values
    });
  }

  int get productsDisplayUsed {
    final repoUsed = productsQuotaUsed.value;
    final actual = products.length; // live list length
    return repoUsed < actual ? actual : repoUsed;
  }

  double get productsQuotaProgress {
    final limit = productsQuotaLimit.value;
    if (limit <= 0) return 0; // unlimited/unknown
    return (productsDisplayUsed / limit).clamp(0, 1).toDouble();
  }

  bool get isProductsQuotaFull {
    final limit = productsQuotaLimit.value;
    if (limit == -1) return false; // unlimited
    if (limit <= 0) return false; // unknown
    return productsDisplayUsed >= limit;
  }
}
