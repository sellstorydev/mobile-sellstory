import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../jobcard/view/jobcard_page.dart';
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
      body: Obx(() => IndexedStack(
        index: controller.currentIndex.value,
        children: const [
          JobCardPage(),
          OrdersPage(),
          CustomersPage(),
          ProductsPage(),
          MorePage(),
        ],
      )),
      bottomNavigationBar: Obx(() => SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: controller.currentIndex.value,
            onTap: controller.onTabTapped,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppTheme.primaryOrange,
            unselectedItemColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.menu),
                activeIcon: Icon(Icons.menu),
                label: 'Job Card',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.description_outlined),
                activeIcon: Icon(Icons.description),
                label: 'รายการคำสั่งซื้อ',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'ลูกค้า',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_bag_outlined),
                activeIcon: Icon(Icons.shopping_bag),
                label: 'สินค้า',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.grid_view),
                activeIcon: Icon(Icons.grid_view),
                label: 'อื่น ๆ',
              ),
            ],
          ),
        ),
      )),
    );
  }
}
