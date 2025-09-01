import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../domain/entities/product.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/dialog_utils.dart';
import '../controller/products_controller.dart';
import 'add_edit_product_page.dart';
import '../../../core/widgets/permission_guard.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  late Product _currentProduct;

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;
  }

  List<String> get allImages {
    final images = <String>[];
    if (_currentProduct.imageUrl.isNotEmpty) {
      images.add(_currentProduct.imageUrl);
    }
    images.addAll(_currentProduct.imageSet);
    return images;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _refreshProductData() async {
    try {
      // Get the updated product from the controller
      final controller = Get.find<ProductsController>();
      final workspaceId = controller.currentWorkspaceId;
      
      if (workspaceId.isNotEmpty) {
        final updatedProduct = await controller.getProduct(workspaceId, _currentProduct.id);
        if (updatedProduct != null) {
          setState(() {
            _currentProduct = updatedProduct;
            _currentImageIndex = 0; // Reset to first image
          });
        }
      }
    } catch (e) {
      print('Error refreshing product data: $e');
    }
  }

  void _showDeleteConfirmation() async {
    final confirmed = await DialogUtils.showDeleteConfirmDialog(
      context: context,
      title: 'ยืนยันการลบสินค้า',
      content: 'คุณต้องการลบสินค้า "${_currentProduct.name}" ใช่หรือไม่?\n\nการดำเนินการนี้ไม่สามารถยกเลิกได้',
    );

    if (confirmed == true) {
      _deleteProduct();
    }
  }

  Future<void> _deleteProduct() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final controller = Get.find<ProductsController>();
      final workspaceId = controller.currentWorkspaceId;
      
      if (workspaceId.isEmpty) {
        Navigator.of(context).pop(); // Close loading dialog
        Get.snackbar(
          'ข้อผิดพลาด',
          'ไม่สามารถลบสินค้าได้: ไม่พบ Workspace',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      final success = await controller.deleteProduct(workspaceId, _currentProduct.id);
      
      // Close loading dialog
      Navigator.of(context).pop();

      if (success) {
        // Navigate back to products list and refresh
        final controller = Get.find<ProductsController>();
        controller.refreshProducts();
        
        // Navigate back to the previous page (products list)
        Get.back();
        
        // Show success message after navigation
        Get.snackbar(
          'สำเร็จ',
          'ลบสินค้าเรียบร้อยแล้ว',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'ข้อผิดพลาด',
          'ไม่สามารถลบสินค้าได้',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      Get.snackbar(
        'ข้อผิดพลาด',
        'เกิดข้อผิดพลาดในการลบสินค้า: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showFullScreenImage(int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            title: Text('${initialIndex + 1} / ${allImages.length}'),
          ),
          body: PageView.builder(
            controller: PageController(initialPage: initialIndex),
            itemCount: allImages.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 3.0,
                child: Center(
                  child: Image.network(
                    allImages[index],
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.white,
                        size: 64,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        title: Text(
          _currentProduct.name,
          style: const TextStyle(
            fontSize: AppTheme.fontSize18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.backgroundWhite,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          // Edit button
          PermissionGuard(
            permission: 'product:edit:all',
            child: IconButton(
              onPressed: () async {
                final result = await Get.to(() => AddEditProductPage(product: _currentProduct));
                if (result == true) {
                  // Refresh product data from the controller
                  await _refreshProductData();
                }
              },
              icon: const Icon(Icons.edit, color: AppTheme.primaryBlue),
            ),
          ),
          // Delete button
          PermissionGuard(
            permission: 'product:delete',
            child: IconButton(
              onPressed: () => _showDeleteConfirmation(),
              icon: const Icon(Icons.delete, color: AppTheme.errorRed),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image Slider Section
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: AppTheme.backgroundWhite,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Image Slider
                  if (allImages.isNotEmpty)
                    GestureDetector(
                      onTap: () => _showFullScreenImage(_currentImageIndex),
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: allImages.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return ClipRRect(
                            child: Image.network(
                              allImages[index],
                              width: double.infinity,
                              height: 300,
                              fit: BoxFit.contain,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      color: AppTheme.backgroundGrey,
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                AppTheme.primaryOrange,
                                              ),
                                        ),
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: AppTheme.backgroundGrey,
                                    child: const Icon(
                                      Icons.image_not_supported_outlined,
                                      color: AppTheme.textGrey,
                                      size: 64,
                                    ),
                                  ),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Container(
                      color: AppTheme.backgroundGrey,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: AppTheme.textGrey,
                        size: 64,
                      ),
                    ),

                  // Discontinued Overlay
                  if (_currentProduct.status == 'discontinued')
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          color: Colors.black.withOpacity(0.6),
                          child: const Center(
                            child: Text(
                              'ยังไม่เปิดขาย',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Image Counter
                  if (allImages.length > 1)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${_currentImageIndex + 1} / ${allImages.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                  // Navigation Arrows
                  if (allImages.length > 1) ...[
                    // Previous Button
                    Positioned(
                      left: 16,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: _currentImageIndex > 0
                                ? () {
                                    _pageController.previousPage(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                : null,
                            icon: const Icon(
                              Icons.chevron_left,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Next Button
                    Positioned(
                      right: 16,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: _currentImageIndex < allImages.length - 1
                                ? () {
                                    _pageController.nextPage(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                : null,
                            icon: const Icon(
                              Icons.chevron_right,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Page Indicator Dots
                  if (allImages.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          allImages.length,
                          (index) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentImageIndex == index
                                  ? AppTheme.primaryOrange
                                  : Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Product Info Section
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundWhite,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    _currentProduct.name,
                    style: const TextStyle(
                      fontSize: AppTheme.fontSize24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Price
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                    ),
                    child: Text(
                      '฿${_currentProduct.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: AppTheme.fontSize20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.figmaOrange,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Description
                  if (_currentProduct.description.isNotEmpty) ...[
                    const Text(
                      'รายละเอียด',
                      style: TextStyle(
                        fontSize: AppTheme.fontSize16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentProduct.description,
                      style: const TextStyle(
                        fontSize: AppTheme.fontSize14,
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Product Details Grid
                  const Text(
                    'ข้อมูลสินค้า',
                    style: TextStyle(
                      fontSize: AppTheme.fontSize16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // SKU
                  _buildDetailRow('SKU', _currentProduct.sku),
                  const SizedBox(height: 8),

                  // Unit
                  if (_currentProduct.unit.isNotEmpty) ...[
                    _buildDetailRow('หน่วย', _currentProduct.unit),
                    const SizedBox(height: 8),
                  ],

                  // Barcode
                  if (_currentProduct.barcode.isNotEmpty) ...[
                    _buildDetailRow('บาร์โค้ด', _currentProduct.barcode),
                    const SizedBox(height: 8),
                  ],

                  // Category
                  if (_currentProduct.category.isNotEmpty) ...[
                    _buildDetailRow('หมวดหมู่', _currentProduct.category),
                    const SizedBox(height: 8),
                  ],

                  // Cost Price
                  _buildDetailRow(
                    'ต้นทุน',
                    '฿${_currentProduct.costPrice.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 8),

                  // Stock Info
                  _buildDetailRow(
                    'สต็อกเริ่มต้น',
                    _currentProduct.initialStock.toString(),
                  ),
                  const SizedBox(height: 8),

                  // Status
                  _buildDetailRow(
                    'สถานะ',
                    _getStatusText(_currentProduct.status),
                  ),
                  const SizedBox(height: 16),

                  // Hashtags
                  if (_currentProduct.hashtags.isNotEmpty) ...[
                    const Text(
                      'แท็ก',
                      style: TextStyle(
                        fontSize: AppTheme.fontSize16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _currentProduct.hashtags.map((hashtag) {
                        final color = _parseColor(
                          hashtag['color'] ?? '#3b82f6',
                        );
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: color.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            hashtag['text'] ?? '',
                            style: TextStyle(
                              fontSize: AppTheme.fontSize12,
                              color: color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),

            // Bottom spacing
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: AppTheme.fontSize14,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: AppTheme.fontSize14,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'เปิดขาย';
      case 'draft':
        return 'ร่าง';
      case 'discontinued':
        return 'ยังไม่เปิดขาย';
      default:
        return status;
    }
  }

  Color _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        return Color(
          int.parse(colorString.substring(1), radix: 16) + 0xFF000000,
        );
      }
    } catch (e) {
      // Fallback to default color
    }
    return AppTheme.primaryBlue;
  }
}
