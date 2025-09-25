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
            // Search Bar
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.backgroundWhite,
              child: TextField(
                controller: controller.safeSearchController,
                onChanged: (value) {
                  try {
                    if (Get.isRegistered<ProductsController>()) {
                      controller.onSearchChanged(value);
                    }
                  } catch (e) {
                    print('⚠️ Error in onChanged: $e');
                  }
                },
                decoration: InputDecoration(
                  hintText: 'search_products'.tr,
                  prefixIcon: const Icon(Icons.search, color: AppTheme.textGrey),
                  suffixIcon: _buildSearchAndClearSuffixIcons(controller),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.borderGrey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.borderGrey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryOrange),
                  ),
                  filled: true,
                  fillColor: AppTheme.backgroundGrey,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),

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
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppTheme.primaryOrange),
                        SizedBox(height: 16),
                        Text(
                          'กำลังค้นหาสินค้า...',
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

  Widget _buildSearchAndClearSuffixIcons(ProductsController controller) {
    return Obx(() {
      try {
        if (!Get.isRegistered<ProductsController>()) {
          return const SizedBox.shrink();
        }
        
        final hasSearchText = controller.searchQuery.value.isNotEmpty;

        return Container(
          margin: const EdgeInsets.only(right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search button
              IconButton(
                onPressed: () => _triggerSearch(controller),
                icon: controller.isSearching.value
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryOrange,
                        ),
                      )
                    : Icon(
                        Icons.search,
                        color: hasSearchText 
                            ? AppTheme.primaryOrange
                            : AppTheme.textGrey,
                      ),
              ),
              // Clear button
              if (hasSearchText)
                IconButton(
                  icon: const Icon(Icons.clear, color: AppTheme.textGrey),
                  onPressed: () {
                    try {
                      if (Get.isRegistered<ProductsController>()) {
                        controller.clearSearch();
                      }
                    } catch (e) {
                      print('⚠️ Error in clearSearch: $e');
                    }
                  },
                ),
            ],
          ),
        );
      } catch (e) {
        print('⚠️ Error building search icons: $e');
        return const SizedBox.shrink();
      }
    });
  }

  Widget _buildSearchAndClearSuffixIcons(ProductsController controller) {
    return Obx(() {
      final hasSearchText = controller.searchQuery.value.isNotEmpty;
      
      if (!hasSearchText) {
        return const SizedBox.shrink();
      }

      return IconButton(
        tooltip: 'ล้างคำค้น',
        icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
        onPressed: () {
          controller.clearSearch();
          _searchFocus.requestFocus();
        },
      );
    });
  }

  void _triggerSearch(ProductsController controller) {
    try {
      if (!Get.isRegistered<ProductsController>()) {
        return;
      }
      
      final searchController = controller.safeSearchController;
      final query = searchController.text.trim();
      if (query.isNotEmpty) {
        controller.triggerAlgoliaSearch(query);
      }
    } catch (e) {
      print('⚠️ Error triggering search: $e');
    }
  }
}
