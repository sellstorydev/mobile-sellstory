import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../domain/entities/product.dart';
import '../../../core/theme/app_theme.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCard({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.backgroundGrey,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderGrey),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                             // Cover Image with Menu
               Stack(
                 children: [
                   ClipRRect(
                     borderRadius: const BorderRadius.vertical(
                       top: Radius.circular(12),
                     ),
                     child: AspectRatio(
                       aspectRatio: 1,
                       child: product.imageUrl.isNotEmpty
                           ? Image.network(
                               product.imageUrl,
                               fit: BoxFit.cover,
                               loadingBuilder: (context, child, loadingProgress) {
                                 if (loadingProgress == null) return child;
                                 return Container(
                                   color: AppTheme.backgroundGrey,
                                   child: const Center(
                                     child: CircularProgressIndicator(
                                       strokeWidth: 2,
                                       valueColor: AlwaysStoppedAnimation<Color>(
                                         AppTheme.primaryOrange,
                                       ),
                                     ),
                                   ),
                                 );
                               },
                               errorBuilder: (context, error, stackTrace) =>
                                   Container(
                                     color: AppTheme.backgroundGrey,
                                     child: Icon(
                                       Icons.image_not_supported_outlined,
                                       color: AppTheme.textGrey,
                                       size: isSmallScreen ? 24 : 32,
                                     ),
                                   ),
                                 )
                           : Container(
                               color: AppTheme.backgroundGrey,
                               child: Icon(
                                 Icons.image_not_supported_outlined,
                                 color: AppTheme.textGrey,
                                 size: isSmallScreen ? 24 : 32,
                               ),
                             ),
                     ),
                   ),
                   // Discontinued Overlay
                   if (product.status == 'discontinued')
                     Positioned.fill(
                       child: Container(
                         decoration: BoxDecoration(
                           color: Colors.black.withOpacity(0.6),
                           borderRadius: const BorderRadius.vertical(
                             top: Radius.circular(12),
                           ),
                         ),
                         child: const Center(
                           child: Text(
                             'ยังไม่เปิดขาย',
                             style: TextStyle(
                               color: Colors.white,
                               fontSize: 16,
                               fontWeight: FontWeight.bold,
                             ),
                           ),
                         ),
                       ),
                     ),
                  // 3-dot Menu
                  Positioned(
                    top: 4,
                    right: 0,
                    child: Container(
                      child: PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: product.status == 'discontinued' ? Colors.white : Colors.black,
                          size: 20,
                        ),
                        iconSize: 10,
                        padding: const EdgeInsets.all(4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.edit,
                                  size: 18,
                                  color: AppTheme.primaryBlue,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'แก้ไข',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.delete,
                                  size: 18,
                                  color: AppTheme.errorRed,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'ลบ',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.errorRed,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') {
                            // TODO: Navigate to edit product page
                            Get.snackbar(
                              'แก้ไขสินค้า',
                              'ฟีเจอร์นี้จะเปิดใช้งานเร็วๆ นี้',
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          } else if (value == 'delete') {
                            // TODO: Show delete confirmation dialog
                            Get.snackbar(
                              'ลบสินค้า',
                              'ฟีเจอร์นี้จะเปิดใช้งานเร็วๆ นี้',
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),

              // Content Area
              Padding(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Product Name
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Description
                    if (product.description.isNotEmpty) ...[
                      Text(
                        product.description,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 13,
                          color: AppTheme.textSecondary,
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Hashtags
                    if (product.hashtags.isNotEmpty) ...[
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: product.hashtags.map((hashtag) {
                          final color = _parseColor(
                            hashtag['color'] ?? '#3b82f6',
                          );
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: color.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              hashtag['text'] ?? '',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 9 : 10,
                                color: color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Price
                    Text(
                      '฿${product.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.figmaOrange,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
