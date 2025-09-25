import 'dart:async';
import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:get/get.dart';

/// Simple In-App Purchase Service (iOS only for now)
/// Responsibilities:
/// - Connect to store
/// - Query product details
/// - Listen to purchase updates
/// - Trigger buy / restore
/// - Expose reactive state
class InAppPurchaseService extends GetxService {
  final InAppPurchase _iap = InAppPurchase.instance;
  final isAvailable = false.obs;
  final products = <ProductDetails>[].obs;
  final purchases = <PurchaseDetails>[].obs;
  final isLoading = true.obs;
  final errorMessage = ''.obs;
  final processingPurchaseIds = <String>{}.obs;
  final notFoundIds = <String>[].obs; // product IDs not returned by store
  final _simulatedOwned = <String>{}.obs; // simulator-only owned set
  final forceMock = false.obs; // manual toggle (debug / QA)

  bool get isSimulator {
    // iOS simulator check: device model identifier contains 'x86_64' or 'i386' historically, but
    // simplest runtime heuristic inside Flutter: Platform.isIOS && !Platform.environment.containsKey('SIMULATOR_DEVICE_NAME') is unreliable.
    // We'll rely on the widely used dart:io environment flag set by iOS simulator: 'SIMULATOR_DEVICE_NAME'.
    try {
      if (!Platform.isIOS) return false;
      return Platform.environment['SIMULATOR_DEVICE_NAME'] != null;
    } catch (_) {
      return false;
    }
  }

  StreamSubscription<List<PurchaseDetails>>? _sub;

  // Configure your product identifiers here (must match App Store Connect)
  // Example: remove ads, subscription tiers, coins, etc.
  // These should eventually come from remote config / Firestore if dynamic.
  static const Set<String> _kProductIds = <String>{
    '365day',
    '365days',
  };

  Set<String> get productIds => _kProductIds; // expose for debug UI

  void toggleForceMock() {
    forceMock.value = !forceMock.value;
    if (forceMock.value) {
      errorMessage.value = 'iap_force_mock_enabled'.tr;
    } else {
      errorMessage.value = '';
      refreshProducts();
    }
  }

  Future<InAppPurchaseService> init() async {
    if (!Platform.isIOS) {
      isLoading.value = false;
      return this; // Do nothing on non-iOS platforms for now
    }

    // Short-circuit for simulator: mark available and skip real store query (Apple store returns empty on simulator often for new products)
    if (isSimulator) {
      isAvailable.value = true; // pretend available so UI flows
      isLoading.value = false;
      errorMessage.value = 'iap_simulator_mode'.tr; // informational
      return this;
    }

    final available = await _iap.isAvailable();
    isAvailable.value = available;

    if (!available) {
      isLoading.value = false;
      errorMessage.value = 'iap_not_available'.tr;
      return this;
    }

    _sub = _iap.purchaseStream.listen(_onPurchaseUpdated, onError: (e) {
      errorMessage.value = 'iap_purchase_stream_error'.trParams({'error': '$e'});
    });

    await _loadProducts();
    return this;
  }

  Future<void> _loadProducts() async {
    try {
      isLoading.value = true;
      if (forceMock.value) {
        products.clear();
        notFoundIds.clear();
        errorMessage.value = 'iap_force_mock_enabled'.tr;
        return;
      }

      final response = await _iap.queryProductDetails(_kProductIds);
      if (response.error != null) {
        errorMessage.value = 'iap_query_products_failed'.trParams({'error': response.error!.message});
      }
      notFoundIds.assignAll(response.notFoundIDs);
      products.assignAll(response.productDetails);
      if (response.productDetails.isEmpty && response.notFoundIDs.isNotEmpty) {
        errorMessage.value = 'iap_products_not_found'.trParams({'ids': response.notFoundIDs.join(', ')});
      } else if (response.productDetails.isEmpty &&
          response.notFoundIDs.isEmpty) {
        // ambiguous empty result – likely propagation / approval issue
        errorMessage.value = 'iap_products_empty_hint'.tr;
      }
    } catch (e) {
      errorMessage.value = 'iap_query_products_failed'.trParams({'error': '$e'});
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshProducts() => _loadProducts();
  Future<void> reloadProducts() => _loadProducts(); // alias to avoid stale hot-reload lookup issues

  Future<void> buy(ProductDetails product) async {
    if (!isAvailable.value) return;
    if (isSimulator || forceMock.value) {
      // Simulate immediate successful purchase
      processingPurchaseIds.add(product.id);
      await Future.delayed(const Duration(milliseconds: 350));
      _simulatedOwned.add(product.id);
      processingPurchaseIds.remove(product.id);
      return;
    }
    final purchaseParam = PurchaseParam(productDetails: product);
    processingPurchaseIds.add(product.id);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> simulatePurchase(String productId) async {
    if (!isSimulator) return;
    if (_simulatedOwned.contains(productId)) return; // already owned
    processingPurchaseIds.add(productId);
    await Future.delayed(const Duration(milliseconds: 400));
    _simulatedOwned.add(productId);
    processingPurchaseIds.remove(productId);
  }

  Future<void> restore() async {
    if (!isAvailable.value) return;
    if (forceMock.value || isSimulator) return; // nothing to restore in mock
    await _iap.restorePurchases();
  }

  void _onPurchaseUpdated(List<PurchaseDetails> detailsList) async {
    for (final purchase in detailsList) {
      purchases.removeWhere((p) => p.productID == purchase.productID);
      purchases.add(purchase);

      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // TODO: verify receipt with backend for security
          processingPurchaseIds.remove(purchase.productID);
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;
        case PurchaseStatus.error:
          processingPurchaseIds.remove(purchase.productID);
          errorMessage.value = 'iap_purchase_failed'.trParams({'error': purchase.error?.message ?? 'unknown'});
          break;
        case PurchaseStatus.pending:
          // waiting
          break;
        case PurchaseStatus.canceled:
          processingPurchaseIds.remove(purchase.productID);
          break;
      }
    }
  }

  bool hasActivePurchase(String productId) {
    if (isSimulator || forceMock.value) {
      return _simulatedOwned.contains(productId);
    }
    return purchases.any((p) => p.productID == productId && p.status == PurchaseStatus.purchased);
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
