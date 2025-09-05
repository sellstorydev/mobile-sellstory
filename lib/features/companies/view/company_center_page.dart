import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../controller/companies_controller.dart';
import '../widgets/company_tile.dart';
import 'company_detail_page.dart';
import 'add_edit_company_page.dart';
import '../../../core/widgets/permission_guard.dart';
import '../../board/widgets/workspace_app_bar.dart';
import '../../board/controller/board_controller.dart';

class CompanyCenterPage extends StatefulWidget {
  const CompanyCenterPage({super.key});

  @override
  State<CompanyCenterPage> createState() => _CompanyCenterPageState();
}

class _CompanyCenterPageState extends State<CompanyCenterPage> {
  late CompaniesController _controller;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Ensure CompaniesController exists
    if (!Get.isRegistered<CompaniesController>()) {
      Get.put<CompaniesController>(CompaniesController());
    }
    _controller = Get.find<CompaniesController>();
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
      appBar: WorkspaceAppBar(controller: boardCtrl),
      body: PermissionGuard(
        permission: 'company:view:all',
        fallback: const Center(
          child: Text(
            'คุณไม่มีสิทธิ์ดูรายชื่อบริษัท',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
        child: Column(
          children: [
            _buildSearchBar(context),
            _buildHeaderSection(context),
            Expanded(child: _buildCompanyList()),
          ],
        ),
      ),
    );
  }

  // === UI: Search Bar ===
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
                  hintText: 'ชื่อบริษัท, เลขประจำตัวผู้เสียภาษี, สาขา, เบอร์โทร, อีเมล',
                  hintStyle: const TextStyle(color: AppTheme.textSecondary),
                  border: InputBorder.none,
                  prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                  suffixIcon: Obx(() {
                    final showClear = _controller.searchQuery.value.isNotEmpty;
                    return showClear
                        ? IconButton(
                            tooltip: 'ล้างคำค้น',
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

  // === UI: Header "จำนวน XX บริษัท" + ปุ่มเพิ่มบริษัท ===
  Widget _buildHeaderSection(BuildContext context) {
    return Container(
      color: AppTheme.backgroundWhite,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Row(
        children: [
          Obx(() {
            final count = _controller.filteredCompanyCount;
            return RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
                children: [
                  const TextSpan(text: 'จำนวน '),
                  TextSpan(
                    text: '$count',
                    style: const TextStyle(
                      color: AppTheme.primaryOrange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const TextSpan(text: ' บริษัท'),
                ],
              ),
            );
          }),
          const Spacer(),
          PermissionGuard(
            permission: 'company:create',
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryOrange,
                side: const BorderSide(color: AppTheme.primaryOrange, width: 1),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.business, size: 18),
              label: const Text('เพิ่มบริษัท'),
              onPressed: () {
                guardAction(context, 'company:create', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddEditCompanyPage(),
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

  // === UI: รายการบริษัท + Pull-to-Refresh + สถานะ error/empty ===
  Widget _buildCompanyList() {
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
              _controller.loadCompanies(workspaceId);
            }
          },
        );
      }

      if (_controller.filteredCompanies.isEmpty) {
        final isSearching = _controller.searchQuery.value.isNotEmpty;
        return _EmptyState(
          icon: isSearching ? Icons.search_off : Icons.business_outlined,
          title: isSearching ? 'ไม่พบบริษัทที่ค้นหา' : 'ไม่มีบริษัท',
          subtitle: isSearching
              ? 'ลองค้นหาด้วยคำอื่น'
              : 'เริ่มต้นเพิ่มบริษัทแรกของคุณ',
        );
      }

      return RefreshIndicator(
        color: AppTheme.primaryOrange,
        onRefresh: () async {
          final workspaceId = _controller.currentWorkspaceId.value;
          if (workspaceId.isNotEmpty) {
            await _controller.loadCompanies(workspaceId);
          }
        },
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          itemCount: _controller.filteredCompanies.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFEAEAEA)),
          itemBuilder: (context, index) {
            final company = _controller.filteredCompanies[index];
            return Material(
              color: Colors.white,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CompanyDetailPage(company: company),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: CompanyTile(company: company),
                ),
              ),
            );
          },
        ),
      );
    });
  }
}

// === Widgets: สถานะว่าง/ผิดพลาด ===
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
            const Text(
              'เกิดข้อผิดพลาด',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 14),
            OutlinedButton(onPressed: onRetry, child: const Text('ลองใหม่')),
          ],
        ),
      ),
    );
  }
}
