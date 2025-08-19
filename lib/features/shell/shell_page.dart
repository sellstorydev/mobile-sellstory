import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
      backgroundColor: Colors.white,
      body: Obx(() => IndexedStack(
        index: controller.currentIndex.value,
        children: const [
          BoardPage(),
          OrdersPage(),
          CustomersPage(),
          ProductsPage(),
          MorePage(),
        ],
      )),
      bottomNavigationBar: Obx(() => Container(
        width: double.infinity,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0x19000000),
              blurRadius: 8,
              offset: const Offset(0, -1),
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
                icon: const Icon(Icons.description_outlined, size: 24),
                label: 'รายการคำสั่งซื้อ',
                onTap: () => controller.onTabTapped(1),
              ),
              _buildNavItem(
                index: 2,
                currentIndex: controller.currentIndex.value,
                icon: const Icon(Icons.person_outline, size: 24),
                label: 'ลูกค้า',
                onTap: () => controller.onTabTapped(2),
              ),
              _buildNavItem(
                index: 3,
                currentIndex: controller.currentIndex.value,
                icon: const Icon(Icons.shopping_bag_outlined, size: 24),
                label: 'สินค้า',
                onTap: () => controller.onTabTapped(3),
              ),
              _buildNavItem(
                index: 4,
                currentIndex: controller.currentIndex.value,
                icon: const Icon(Icons.grid_view, size: 24),
                label: 'อื่น ๆ',
                onTap: () => controller.onTabTapped(4),
              ),
            ],
          ),
        ),
      )),
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
          height: 67,
          padding: const EdgeInsets.only(top: 2, bottom: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              icon,
              Container(height: 4),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFFFF3312) : const Color(0xFFB3B3B3),
                    fontSize: 10,
                    fontFamily: 'Kanit',
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJobCardIcon(bool isSelected) {
    return Container(
      width: 60,
      height: 40,
      child: Stack(
        children: [
          if (isSelected) ...[
            Positioned(
              left: 22.50,
              top: 8.50,
              child: Container(
                width: 15,
                height: 6,
                decoration: ShapeDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment(0.50, -0.00),
                    end: Alignment(0.50, 1.00),
                    colors: [Color(0xFFFF3312), Color(0xFFFF6C0C)],
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                ),
              ),
            ),
            Positioned(
              left: 22.50,
              top: 0.50,
              child: Container(
                width: 15,
                height: 6,
                decoration: ShapeDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment(0.50, -0.00),
                    end: Alignment(0.50, 1.00),
                    colors: [Color(0xFFFF3312), Color(0xFFFF6C0C)],
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                ),
              ),
            ),
          ] else ...[
            Positioned(
              left: 22.50,
              top: 8.50,
              child: Container(
                width: 15,
                height: 6,
                decoration: ShapeDecoration(
                  color: const Color(0xFFB3B3B3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                ),
              ),
            ),
            Positioned(
              left: 22.50,
              top: 0.50,
              child: Container(
                width: 15,
                height: 6,
                decoration: ShapeDecoration(
                  color: const Color(0xFFB3B3B3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                ),
              ),
            ),
          ],
          Positioned(
            left: 0,
            top: 20,
            child: Container(
              width: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      'Job Card',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? const Color(0xFFFF3312) : const Color(0xFFB3B3B3),
                        fontSize: 10,
                        fontFamily: 'Kanit',
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
