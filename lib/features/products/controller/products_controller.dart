import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/firestore_repository.dart';
import '../../../domain/entities/product.dart';
import '../../../core/services/logger_service.dart';

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

  // User and workspace data
  String _currentUserId = '';
  String _currentWorkspaceId = '';

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
        // Use the first workspace as default
        final firstWorkspace = workspaces.first;
        _currentWorkspaceId = firstWorkspace['id'] as String;
        
        _logger.methodEntry('ProductsController._initializeUserAndWorkspace', {
          'workspaceId': _currentWorkspaceId,
          'workspaceName': firstWorkspace['name'],
        });
        
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
}
