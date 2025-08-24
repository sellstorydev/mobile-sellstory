import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/customer.dart';
import '../controller/customers_controller.dart';
import 'add_edit_customer_page.dart';

class CustomerDetailPage extends StatelessWidget {
  final Customer customer;

  const CustomerDetailPage({
    super.key,
    required this.customer,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        title: Text('รายละเอียดลูกค้า'),
        backgroundColor: AppTheme.backgroundWhite,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              // Get customer sources from controller
              final controller = Get.find<CustomersController>();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditCustomerPage(
                    customer: customer,
                    customerSources: controller.customerSources,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.edit),
            tooltip: 'แก้ไขลูกค้า',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card
            _buildProfileCard(),
            const SizedBox(height: 16),
            
            // Customer Information
            _buildInfoSection('ข้อมูลลูกค้า', [
              _buildInfoRow('รหัสลูกค้า', customer.customId),
              _buildInfoRow('ชื่อ', '${customer.prefix} ${customer.name}'),
              _buildInfoRow('เพศ', customer.gender),
              _buildInfoRow('อายุ', '${customer.age} ปี'),
              _buildInfoRow('ประเภท', customer.customerType),
            ]),
            
            const SizedBox(height: 16),
            
            // Contact Information
            _buildInfoSection('ข้อมูลติดต่อ', [
              _buildInfoRow('อีเมล', customer.emails.isNotEmpty ? customer.emails : 'ไม่ระบุ'),
              _buildInfoRow('เบอร์โทร', customer.phones.isNotEmpty ? customer.phones : 'ไม่ระบุ'),
            ]),
            
            const SizedBox(height: 16),
            
            // Company Information
            if (customer.companyNames.isNotEmpty) ...[
              _buildInfoSection('ข้อมูลบริษัท', [
                _buildInfoRow('ชื่อบริษัท', customer.companyNames),
              ]),
              const SizedBox(height: 16),
            ],
            
            // Additional Information
            _buildInfoSection('ข้อมูลเพิ่มเติม', [
              if (customer.nationalId.isNotEmpty)
                _buildInfoRow('เลขบัตรประชาชน', customer.nationalId),
              if (customer.address.isNotEmpty)
                _buildInfoRow('ที่อยู่', customer.address),
              if (customer.source.isNotEmpty)
                _buildInfoRow('แหล่งที่มา', customer.source),
              if (customer.hashtags.isNotEmpty)
                _buildInfoRow('แฮชแท็ก', customer.hashtags),
              if (customer.assignees.isNotEmpty)
                _buildInfoRow('ผู้รับผิดชอบ', customer.assignees),
            ]),
            
            const SizedBox(height: 16),
            
            // System Information
            _buildInfoSection('ข้อมูลระบบ', [
              _buildInfoRow('สร้างเมื่อ', _formatDate(customer.createdAt)),
              _buildInfoRow('อัปเดตล่าสุด', _formatDate(customer.updatedAt)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Image
          CircleAvatar(
            radius: 40,
            backgroundColor: AppTheme.primaryOrange.withOpacity(0.1),
            child: Icon(
              Icons.person,
              size: 40,
              color: AppTheme.primaryOrange,
            ),
          ),
          const SizedBox(height: 16),
          
          // Name
          Text(
            '${customer.prefix} ${customer.name}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          // Customer ID
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              customer.customId,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryOrange,
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // Customer Type
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: customer.customerType == 'Customer' 
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              customer.customerType,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: customer.customerType == 'Customer' 
                    ? Colors.green
                    : Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}


