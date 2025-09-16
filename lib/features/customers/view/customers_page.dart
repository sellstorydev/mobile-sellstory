import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../controller/customers_controller.dart';
import '../widgets/customer_tile.dart';
import 'customer_detail_page.dart';
import 'add_edit_customer_page.dart';
import '../../../core/widgets/permission_guard.dart';
import '../../board/widgets/workspace_app_bar.dart';
import '../../board/controller/board_controller.dart';
import '../../shell/shell_controller.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}



class _CustomersPageState extends State<CustomersPage> {
  late CustomersController _controller;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Ensure CustomersController exists
    if (!Get.isRegistered<CustomersController>()) {
      Get.put<CustomersController>(CustomersController(Get.find()));
    }
    _controller = Get.find<CustomersController>();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    // Resolve BoardController safely at build time
    BoardController? boardCtrl;
    if (Get.isRegistered<BoardController>()) {
      try {
        boardCtrl = Get.find<BoardController>();
      } catch (_) {
        boardCtrl = null;
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: WorkspaceAppBar(
        controller: boardCtrl,
        titleBuilder: (ctx, ctrl) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Image.asset('assets/app_icon_original.png', fit: BoxFit.cover),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'company') {
                      if (Get.isRegistered<ShellController>()) {
                        final shell = Get.find<ShellController>();
                        shell.setCustomersTabMode(companyMode: true);
                        shell.onTabTapped(2);
                      } else {
                        Get.offNamed('/companies');
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'individual',
                      child: Text('individual'.tr),
                    ),
                    PopupMenuItem<String>(
                      value: 'company',
                      child: Text('corporate'.tr),
                    ),
                  ],
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'individual'.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.black54),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),

      body: PermissionGuard(
        anyOf: const ['customer:view:all', 'customer:view:assigned'],
        fallback: Center(
          child: Text(
            'no_permission_view_customers'.tr,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
        child: Column(
          children: [
            _buildSearchBar(context),
            _buildHeaderSection(context),
            Expanded(child: _buildCustomerList()),
          ],
        ),
      ),
    );
  }

  // === UI: Search Bar (ตามภาพตัวอย่าง) ===
  Widget _buildSearchBar(BuildContext context) {
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
                controller: _searchController,
                focusNode: _searchFocus,
                onChanged: _controller.setSearchQuery,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText:
                  'search_placeholder_customers'.tr,
                  hintStyle: const TextStyle(color: AppTheme.textSecondary),
                  border: InputBorder.none,
                  prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                  suffixIcon: Obx(() {
                    final showClear = _controller.searchQuery.value.isNotEmpty;
                    return showClear
                        ? IconButton(
                      tooltip: 'clear_search'.tr,
                      icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                      onPressed: () {
                        _searchController.clear();
                        _controller.clearSearch();
                        _searchFocus.requestFocus();
                      },
                    )
                        : const SizedBox.shrink();
                  }),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // ปุ่มแว่นขยายเล็ก ๆ ตามฟีลในภาพ (กดแล้วปิดคีย์บอร์ด)
          Material(
            color: AppTheme.primaryOrange,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _searchFocus.unfocus(),
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

  // === UI: Header "จำนวน XX คน" + ปุ่มเพิ่มลูกค้า (Outlined ส้ม) ===
  Widget _buildHeaderSection(BuildContext context) {
    return Container(
      color: AppTheme.backgroundWhite,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Row(
        children: [
          Obx(() {
            final count = _controller.filteredCustomerCount;
            return RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
                children: [
                  TextSpan(text: '${'total_count'.tr} '),
                  TextSpan(
                    text: '$count',
                    style: const TextStyle(
                      color: AppTheme.primaryOrange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: ' ${'people'.tr}'),
                ],
              ),
            );
          }),
          const Spacer(),
          PermissionGuard(
            permission: 'customer:create',
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryOrange,
                side: const BorderSide(color: AppTheme.primaryOrange, width: 1),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.person_add_alt_1, size: 18),
              label: Text('add_customer'.tr),
              onPressed: () {
                guardAction(context, 'customer:create', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddEditCustomerPage(
                        customerSources: _controller.customerSources,
                      ),
                    ),
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // === UI: รายการลูกค้า + Pull-to-Refresh + สถานะ error/empty ===
  Widget _buildCustomerList() {
    return Obx(() {
      if (_controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryOrange),
        );
      }

      if (_controller.errorMessage.value.isNotEmpty) {
        return _ErrorState(
          message: _controller.errorMessage.value,
          onRetry: () {
            final workspaceId = _controller.currentWorkspaceId.value;
            if (workspaceId.isNotEmpty) {
              _controller.loadCustomers(workspaceId);
            }
          },
        );
      }

      if (_controller.filteredCustomers.isEmpty) {
        final isSearching = _controller.searchQuery.value.isNotEmpty;
        return _EmptyState(
          icon: isSearching ? Icons.search_off : Icons.people_outline,
          title: isSearching ? 'customer_not_found'.tr : 'no_customers'.tr,
          subtitle: isSearching
              ? 'try_different_search'.tr
              : 'start_adding_first_customer'.tr,
        );
      }

      return RefreshIndicator(
        color: AppTheme.primaryOrange,
        onRefresh: () async {
          final workspaceId = _controller.currentWorkspaceId.value;
          if (workspaceId.isNotEmpty) {
            await _controller.loadCustomers(workspaceId);
          }
        },
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          itemCount: _controller.filteredCustomers.length,
          separatorBuilder: (_, __) =>
          const Divider(height: 1, color: Color(0xFFEAEAEA)),
          itemBuilder: (context, index) {
            final customer = _controller.filteredCustomers[index];
            return Material(
              color: Colors.white,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CustomerDetailPage(customer: customer),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: CustomerTile(customer: customer),
                ),
              ),
            );
          },
        ),
      );
    });
  }
}

// === Widgets: สถานะว่าง/ผิดพลาด แบบกะทัดรัด ===
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppTheme.textSecondary),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;



  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 12),
            Text(
              'error_occurred'.tr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            getLotStr(message),
            const SizedBox(height: 14),
            OutlinedButton(onPressed: onRetry, child: Text('try_again'.tr)),
          ],
        ),
      ),
    );
  }
  getLotStr(message){

    print(message);
        return  Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        );
  }
}
