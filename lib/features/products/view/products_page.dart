import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../controller/products_controller.dart';
import '../widgets/product_card.dart';
import 'add_edit_product_page.dart';
import '../../../core/widgets/permission_guard.dart';
import '../../../core/services/quota_guard.dart';


class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final FocusNode _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProductsController());

    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        title: Text('products'.tr),
        backgroundColor: AppTheme.backgroundWhite,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          // Add product button
          PermissionGuard(
            permission: 'product:create',
            child: TextButton.icon(
              onPressed: () async {
                guardAction(context, 'product:create', () async {
                  final wsId = controller.currentWorkspaceId;
                  final canCreate = await QuotaGuard.ensureCanCreate(context, wsId, 'products');
                  if (!canCreate) return;
                  Get.to(() => const AddEditProductPage());
                });
              },
              icon: const Icon(Icons.add, color: AppTheme.primaryOrange),
              label: Text(
                'add_product'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.primaryOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: PermissionGuard(
        permission: 'product:view',
        fallback: Center(
          child: Text(
            'no_permission_view_products'.tr,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
        ),
        child: Column(
          children: [
            _buildSearchBar(context),

            // Products Count and Add Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppTheme.backgroundWhite,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Obx(() => Text(
                        'all_products_count'.tr.replaceFirst('{count}', controller.productsCount.value.toString()),
                        style: const TextStyle(
                          fontSize: AppTheme.fontSize14,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      )),
                      PermissionGuard(
                        permission: 'product:create',
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            guardAction(context, 'product:create', () async {
                              final wsId = controller.currentWorkspaceId;
                              final canCreate = await QuotaGuard.ensureCanCreate(context, wsId, 'products');
                              if (!canCreate) return;
                              Get.to(() => const AddEditProductPage());
                            });
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: Text('add_product'.tr),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryOrange,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                ],
              ),
            ),

            // Products List
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryOrange,
                      ),
                    ),
                  );
                }

                if (controller.isError.value) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppTheme.errorRed,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'error_occurred'.tr,
                          style: const TextStyle(
                            fontSize: AppTheme.fontSize18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          controller.errorMessage.value,
                          style: const TextStyle(
                            fontSize: AppTheme.fontSize14,
                            color: AppTheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: controller.refreshProducts,
                          child: Text('try_again'.tr),
                        ),
                      ],
                    ),
                  );
                }

                // Show searching state when Algolia search is in progress
                if (controller.isSearching.value) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          color: AppTheme.primaryOrange,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'searching_products'.tr,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (controller.filteredProducts.isEmpty) {
                  return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
                        const Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: AppTheme.textSecondary,
            ),
                        const SizedBox(height: 16),
            Text(
                          controller.searchQuery.value.isEmpty
                              ? 'no_products'.tr
                              : 'no_products_found'.tr,
                          style: const TextStyle(
                            fontSize: AppTheme.fontSize18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
                        const SizedBox(height: 8),

            Text(
                          controller.searchQuery.value.isEmpty
                              ? 'start_adding_first_product'.tr
                              : 'try_different_search'.tr,
                          style: const TextStyle(
                            fontSize: AppTheme.fontSize14,
                color: AppTheme.textSecondary,
              ),
            ),
                        PermissionGuard(
                          permission: 'product:create',
                          child: Builder(
                            builder: (context) {
                              if (controller.searchQuery.value.isEmpty) {
                                return Column(
                                  children: [
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        guardAction(context, 'product:create', () {
                                          Get.to(() => const AddEditProductPage());
                                        });
                                      },
                                      icon: const Icon(Icons.add),
                                      label: Text('add_product'.tr),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryOrange,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: controller.refreshProducts,
                  color: AppTheme.primaryOrange,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Responsive grid based on screen width
                      final screenWidth = constraints.maxWidth;
                      int crossAxisCount = 2; // Default for mobile
                      double spacing = 12;

                      if (screenWidth < 400) {
                        // Small screens
                        crossAxisCount = 2;
                        spacing = 8;
                      } else if (screenWidth < 600) {
                        // Medium screens
                        crossAxisCount = 2;
                        spacing = 12;
                      } else if (screenWidth < 900) {
                        // Large screens
                        crossAxisCount = 3;
                        spacing = 16;
                      } else {
                        // Extra large screens
                        crossAxisCount = 4;
                        spacing = 20;
                      }

                      return ListView.builder(
                        padding: EdgeInsets.all(spacing),
                        itemCount: (controller.filteredProducts.length / crossAxisCount).ceil(),
                        itemBuilder: (context, rowIndex) {
                          final startIndex = rowIndex * crossAxisCount;

                          return Padding(
                            padding: EdgeInsets.only(bottom: spacing),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: List.generate(crossAxisCount, (colIndex) {
                                final productIndex = startIndex + colIndex;
                                if (productIndex >= controller.filteredProducts.length) {
                                  return Expanded(child: SizedBox.shrink());
                                }

                                final product = controller.filteredProducts[productIndex];
                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: colIndex < crossAxisCount - 1 ? spacing : 0,
                                    ),
                                    child: ProductCard(
                                      product: product,
                                    ),
                                  ),
                                );
                              }),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // === UI: Search Bar ===
  Widget _buildSearchBar(BuildContext context) {
    final controller = Get.find<ProductsController>();
    return Container(
      color: AppTheme.backgroundWhite,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.backgroundGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: controller.safeSearchController,
                focusNode: _searchFocus,
                onChanged: (value) {
                  if (Get.isRegistered<ProductsController>()) {
                    controller.onSearchChanged(value);
                  }
                },
                onSubmitted: (_) => _triggerSearch(controller), // Trigger search when Enter is pressed
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'search_products'.tr,
                  hintStyle: const TextStyle(color: AppTheme.textSecondary),
                  border: InputBorder.none,
                  prefixIcon: Obx(
                    () => controller.isSearching.value
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primaryOrange,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.search,
                            color: AppTheme.textSecondary,
                          ),
                  ),
                  suffixIcon: _buildSearchAndClearSuffixIcons(controller),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: AppTheme.primaryOrange,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _triggerSearch(controller),
              child: const SizedBox(
                height: 44,
                width: 44,
                child: Icon(Icons.search, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndClearSuffixIcons(ProductsController controller) {
    return Obx(() {
      final hasSearchText = controller.searchQuery.value.isNotEmpty;
      
      if (!hasSearchText) {
        return const SizedBox.shrink();
      }

      return IconButton(
        tooltip: 'clear_search_tooltip'.tr,
        icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
        onPressed: () {
          controller.clearSearch();
          _searchFocus.requestFocus();
        },
      );
    });
  }

  void _triggerSearch(ProductsController controller) {
    final query = controller.safeSearchController.text.trim();
    // Always trigger Algolia search when button is clicked, even if empty
    controller.triggerAlgoliaSearch(query);
    _searchFocus.unfocus();
  }
}
