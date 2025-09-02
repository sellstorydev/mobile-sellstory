import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_font.dart';
import '../controller/document_center_controller.dart';
import 'add_edit_quotation_page.dart';

class DocumentCenterPage extends StatelessWidget {
  const DocumentCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DocumentCenterController());

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text(
          'เอกสาร',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: AppTheme.fontSize18,
            fontFamily: AppFont.family,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.backgroundWhite,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryOrange,
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              _buildHeaderSection(),
              const SizedBox(height: AppTheme.spacing24),
              
                             // Document Types Grid
               _buildDocumentTypesGrid(context, controller),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: AppTheme.primaryOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.spacing12),
        border: Border.all(
          color: AppTheme.primaryOrange.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AppTheme.iconSize28,
                height: AppTheme.iconSize28,
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange,
                  borderRadius: BorderRadius.circular(AppTheme.spacing8),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: Colors.white,
                  size: AppTheme.iconSize20,
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ระบบเอกสาร',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: AppTheme.fontSize18,
                        fontFamily: AppFont.family,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing4),
                    Text(
                      'จัดการใบเสนอราคา, ใบแจ้งหนี้, ใบแจ้งหนี้',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: AppTheme.fontSize14,
                        fontFamily: AppFont.family,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentTypesGrid(BuildContext context, DocumentCenterController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ประเภทเอกสาร',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: AppTheme.fontSize16,
            fontFamily: AppFont.family,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTheme.spacing16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: AppTheme.spacing16,
          mainAxisSpacing: AppTheme.spacing16,
          childAspectRatio: 1.2,
          children: [
            _buildDocumentTypeCard(
              title: 'ใบเสนอราคา',
              subtitle: 'Quotations',
              icon: Icons.receipt_long_outlined,
              color: const Color(0xFF4CAF50),
              onTap: () => controller.navigateToQuotations(),
            ),
            _buildDocumentTypeCard(
              title: 'ใบแจ้งหนี้',
              subtitle: 'Invoices',
              icon: Icons.description_outlined,
              color: const Color(0xFF2196F3),
              onTap: () => controller.navigateToInvoices(),
            ),
            _buildDocumentTypeCard(
              title: 'ใบเสร็จรับเงิน',
              subtitle: 'Receipts',
              icon: Icons.payment_outlined,
              color: const Color(0xFFFF9800),
              onTap: () => controller.navigateToReceipts(),
            ),
                         _buildDocumentTypeCard(
               title: 'สร้างใหม่',
               subtitle: 'Create New',
               icon: Icons.add_circle_outline,
               color: AppTheme.primaryOrange,
               onTap: () => _showCreateDocumentDialog(context),
             ),
          ],
        ),
      ],
    );
  }

  Widget _buildDocumentTypeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.spacing12),
          border: Border.all(
            color: AppTheme.borderGrey,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowColor.withValues(alpha: 0.1),
              blurRadius: AppTheme.spacing8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: AppTheme.iconSize28,
              height: AppTheme.iconSize28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.spacing12),
              ),
              child: Icon(
                icon,
                color: color,
                size: AppTheme.iconSize20,
              ),
            ),
            const SizedBox(height: AppTheme.spacing12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: AppTheme.fontSize14,
                fontFamily: AppFont.family,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.spacing4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: AppTheme.fontSize12,
                fontFamily: AppFont.family,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDocumentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.spacing12),
          ),
          title: const Text(
            'เลือกประเภทเอกสาร',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: AppTheme.fontSize18,
              fontFamily: AppFont.family,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDocumentTypeOption(
                context,
                title: 'ใบเสนอราคา',
                subtitle: 'Quotation',
                icon: Icons.receipt_long_outlined,
                color: const Color(0xFF4CAF50),
                onTap: () {
                  Navigator.of(context).pop();
                  Get.to(() => const AddEditQuotationPage());
                },
              ),
              const SizedBox(height: AppTheme.spacing12),
              _buildDocumentTypeOption(
                context,
                title: 'ใบแจ้งหนี้',
                subtitle: 'Invoice',
                icon: Icons.description_outlined,
                color: const Color(0xFF2196F3),
                onTap: () {
                  Navigator.of(context).pop();
                  // TODO: Navigate to create invoice page
                  Get.snackbar(
                    'Info',
                    'Create invoice page coming soon',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
              const SizedBox(height: AppTheme.spacing12),
              _buildDocumentTypeOption(
                context,
                title: 'ใบแจ้งหนี้',
                subtitle: 'Receipt',
                icon: Icons.payment_outlined,
                color: const Color(0xFFFF9800),
                onTap: () {
                  Navigator.of(context).pop();
                  // TODO: Navigate to create receipt page
                  Get.snackbar(
                    'Info',
                    'Create receipt page coming soon',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'ยกเลิก',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: AppTheme.fontSize14,
                  fontFamily: AppFont.family,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDocumentTypeOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.spacing12),
          border: Border.all(
            color: AppTheme.borderGrey,
            width: 1,
          ),
        ),
        child: Row(
          children: [
                         Container(
               width: AppTheme.iconSize28,
               height: AppTheme.iconSize28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.spacing8),
              ),
              child: Icon(
                icon,
                color: color,
                size: AppTheme.iconSize24,
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: AppTheme.fontSize16,
                      fontFamily: AppFont.family,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: AppTheme.fontSize14,
                      fontFamily: AppFont.family,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.textSecondary,
              size: AppTheme.iconSize16,
            ),
          ],
        ),
      ),
    );
  }
}
