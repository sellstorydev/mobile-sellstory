import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_font.dart';
import '../../../core/widgets/permission_guard.dart';

class JobCardPage extends StatelessWidget {
  const JobCardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height,
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(color: Colors.white),
        child: Stack(
          children: [
            // Bottom Navigation Bar
            Positioned(
              left: 0,
              bottom: 0,
              right: 0,
              child: _buildBottomNavigationBar(),
            ),

            // Floating Action Button
            Positioned(
              right: 16,
              bottom: 96,
              child: PermissionGuard(
                permission: 'jobcard:create',
                hideIfUnauthorized: true,
                child: Builder(
                  builder: (context) => GestureDetector(
                    onTap: () {
                      guardAction(context, 'jobcard:create', () {
                        // TODO: navigate to create jobcard
                      });
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x4CFB3327),
                            blurRadius: 4,
                            offset: Offset(0.75, 3),
                          ),
                        ],
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF3312), Color(0xFFFF6C0C)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ),
            ),

            // Main Content with Status Bar and Header
            Positioned(
              left: 0,
              top: 0,
              right: 0,
              bottom: 80,
              child: Column(
                children: [
                  // Status Bar
                  _buildStatusBar(),
                  // Header
                  _buildHeader(context),
                  // Content Area (placeholder for now)
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      color: AppTheme.backgroundGrey,
                      // Content will be added here
                      child: const Center(
                        child: Text(
                          'Job Card Content Area',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      width: double.infinity,
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(1.00, 1.00),
          end: Alignment(-0.00, -0.03),
          colors: [Color(0xFFFF3312), Color(0xFFFF6C0C)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            '9.41',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontFamily: AppFont.family,
              fontWeight: FontWeight.w400,
            ),
          ),
          Row(
            children: [
              const SizedBox(width: 18, height: 18),
              Container(width: 4),
              const SizedBox(width: 16, height: 17),
              Container(width: 4),
              const SizedBox(width: 16, height: 17),
              Container(width: 4),
              const Text(
                '100%',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: AppFont.family,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Container(width: 4),
              const SizedBox(width: 18, height: 17),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(1.00, 1.00),
                    end: Alignment(-0.00, -0.03),
                    colors: [Color(0xFFFF0000), Color(0xFFFF6C0C)],
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
              Container(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Job Card',
                    style: TextStyle(
                      color: Color(0xFF333333),
                      fontSize: 20,
                      fontFamily: AppFont.family,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFAB73F),
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                        ),
                      ),
                      Container(width: 4),
                      const Text(
                        'ชื่อบอร์ด 1',
                        style: TextStyle(
                          color: Color(0xFF4D4D4D),
                          fontSize: 12,
                          fontFamily: AppFont.family,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              // Calendar/Filter Icon
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Color(0xFF666666),
                  ),
                ),
              ),
              Container(width: 24),
              // Search Icon
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.search,
                    size: 16,
                    color: Color(0xFF666666),
                  ),
                ),
              ),
              Container(width: 24),
              // More Options Icon
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.more_vert,
                    size: 16,
                    color: Color(0xFF666666),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      width: double.infinity,
      height: 80,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x19000000),
            blurRadius: 8,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Job Card - Active Tab
          Expanded(
            child: SizedBox(
              height: 67,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Active indicator bars
                  Column(
                    children: [
                      Container(
                        width: 15,
                        height: 6,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFFF3312), Color(0xFFFF6C0C)],
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(2)),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        width: 15,
                        height: 6,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFFF3312), Color(0xFFFF6C0C)],
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(2)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Job Card',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFFF3312),
                      fontSize: 11,
                      fontFamily: AppFont.family,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // รายการคำสั่งซื้อ
          Expanded(
            child: Container(
              height: 67,
              padding: const EdgeInsets.only(top: 2, bottom: 8),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.list_alt, size: 28, color: Color(0xFFB3B3B3)),
                  SizedBox(height: 4),
                  Text(
                    'รายการคำสั่งซื้อ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFB3B3B3),
                      fontSize: 11,
                      fontFamily: AppFont.family,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ลูกค้า
          Expanded(
            child: Container(
              height: 67,
              padding: const EdgeInsets.only(top: 2, bottom: 8),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people, size: 28, color: Color(0xFFB3B3B3)),
                  SizedBox(height: 4),
                  Text(
                    'ลูกค้า',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFB3B3B3),
                      fontSize: 11,
                      fontFamily: AppFont.family,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // สินค้า
          Expanded(
            child: Container(
              height: 67,
              padding: const EdgeInsets.only(top: 2, bottom: 8),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2, size: 28, color: Color(0xFFB3B3B3)),
                  SizedBox(height: 4),
                  Text(
                    'สินค้า',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFB3B3B3),
                      fontSize: 11,
                      fontFamily: AppFont.family,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // อื่น ๆ
          Expanded(
            child: Container(
              height: 67,
              padding: const EdgeInsets.only(top: 2, bottom: 8),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.more_horiz, size: 28, color: Color(0xFFB3B3B3)),
                  SizedBox(width: 4),
                  Text(
                    'อื่น ๆ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFB3B3B3),
                      fontSize: 11,
                      fontFamily: AppFont.family,
                      fontWeight: FontWeight.w400,
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

  Widget _buildFloatingActionButton() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Color(0x4CFB3327),
              blurRadius: 4,
              offset: Offset(0.75, 3),
            ),
          ],
          gradient: LinearGradient(
            colors: [Color(0xFFFF3312), Color(0xFFFF6C0C)],
          ),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 24),
      ),
    );
  }
}
