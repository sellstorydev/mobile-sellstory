import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_font.dart';
import '../board/view/board_page.dart';
import '../orders/view/orders_page.dart';
import '../customers/view/customers_page.dart';
import '../products/view/products_page.dart';
import '../more/view/more_page.dart';
import 'shell_controller.dart';

class ShellPage extends StatelessWidget {
  const ShellPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ShellController());

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: Obx(
        () => IndexedStack(
          index: controller.currentIndex.value,
          children: const [
            BoardPage(),
            OrdersPage(),
            CustomersPage(),
            ProductsPage(),
            MorePage(),
          ],
        ),
      ),
      bottomNavigationBar: Obx(
        () => Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppTheme.backgroundWhite,
            boxShadow: [
              BoxShadow(
                color: AppTheme.shadowColor,
                blurRadius: AppTheme.spacing8,
                offset: Offset(0, -1),
                spreadRadius: 0,
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  index: 0,
                  currentIndex: controller.currentIndex.value,
                  icon: _buildJobCardIcon(controller.currentIndex.value == 0),
                  label: 'Job Card',
                  onTap: () => controller.onTabTapped(0),
                ),
                _buildNavItem(
                  index: 1,
                  currentIndex: controller.currentIndex.value,
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: 'คำสั่งซื้อ',
                  onTap: () => controller.onTabTapped(1),
                ),
                _buildNavItem(
                  index: 2,
                  currentIndex: controller.currentIndex.value,
                  icon: const Icon(Icons.people_outline),
                  label: 'ลูกค้า',
                  onTap: () => controller.onTabTapped(2),
                ),
                _buildNavItem(
                  index: 3,
                  currentIndex: controller.currentIndex.value,
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: 'สินค้า',
                  onTap: () => controller.onTabTapped(3),
                ),
                _buildNavItem(
                  index: 4,
                  currentIndex: controller.currentIndex.value,
                  icon: const Icon(Icons.more_horiz),
                  label: 'อื่น ๆ',
                  onTap: () => controller.onTabTapped(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required int currentIndex,
    required Widget icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isSelected = index == currentIndex;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 75,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing4,
            vertical: AppTheme.spacing2,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon with better styling
              SizedBox(
                width: AppTheme.iconSize28,
                height: AppTheme.iconSize28,
                child: IconTheme(
                  data: IconThemeData(
                    color: isSelected
                        ? AppTheme.figmaRed
                        : AppTheme.textSecondary,
                    size: AppTheme.iconSize28,
                  ),
                  child: icon,
                ),
              ),
              Container(height: AppTheme.spacing16),
              // Label with better styling and responsive
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected
                      ? AppTheme.figmaRed
                      : AppTheme.textSecondary,
                  fontSize: AppTheme.fontSize12,
                  fontFamily: AppFont.family,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJobCardIcon(bool isSelected) {
    return Icon(
      Icons.work_outline,
      color: isSelected ? AppTheme.figmaRed : AppTheme.textSecondary,
      size: AppTheme.iconSize28,
    );
  }
}
