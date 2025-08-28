import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../controller/products_controller.dart';
import '../widgets/product_card.dart';
import 'add_edit_product_page.dart';
import '../../../core/widgets/permission_guard.dart';

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProductsController());

    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        title: const Text('สินค้า'),
        backgroundColor: AppTheme.backgroundWhite,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          // Add product button
          PermissionGuard(
            permission: 'product:create',
            child: TextButton.icon(
              onPressed: () {
                guardAction(context, 'product:create', () {
                  Get.to(() => const AddEditProductPage());
                });
              },
              icon: const Icon(Icons.add, color: AppTheme.primaryOrange),
              label: const Text(
                'เพิ่มสินค้า',
                style: TextStyle(
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
            'คุณไม่มีสิทธิ์ดูรายการสินค้า',
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
                onChanged: controller.searchProducts,
                decoration: InputDecoration(
                  hintText: 'ค้นหาสินค้า...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.textGrey),
                  suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppTheme.textGrey),
                          onPressed: controller.clearSearch,
                        )
                      : const SizedBox.shrink()),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Obx(() => Text(
                    'สินค้าทั้งหมด ${controller.productsCount.value} รายการ',
                    style: const TextStyle(
                      fontSize: AppTheme.fontSize14,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  )),
                  PermissionGuard(
                    permission: 'product:create',
                    child: ElevatedButton.icon(
                      onPressed: () {
                        guardAction(context, 'product:create', () {
                          Get.to(() => const AddEditProductPage());
                        });
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('เพิ่มสินค้า'),
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
                          'เกิดข้อผิดพลาด',
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
                          child: const Text('ลองใหม่'),
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
                              ? 'ไม่มีสินค้า'
                              : 'ไม่พบสินค้าที่ค้นหา',
                          style: const TextStyle(
                            fontSize: AppTheme.fontSize18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
                        const SizedBox(height: 8),
            Text(
                          controller.searchQuery.value.isEmpty
                              ? 'เริ่มต้นเพิ่มสินค้าแรกของคุณ'
                              : 'ลองค้นหาด้วยคำอื่น',
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
                                      label: const Text('เพิ่มสินค้า'),
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
                          final endIndex = (startIndex + crossAxisCount).clamp(0, controller.filteredProducts.length);

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
}
