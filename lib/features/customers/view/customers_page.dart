import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../controller/customers_controller.dart';
import '../widgets/customer_tile.dart';
import 'customer_detail_page.dart';
import 'add_edit_customer_page.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  late CustomersController _controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Get the registered controller
    _controller = Get.find<CustomersController>();
    
    // Load customers for the current workspace
    // TODO: Get actual workspace ID from user session
    const workspaceId = 'GkEJ3c6u9QU4utYO6KVZ'; // Using the workspace ID from the backup data
    _controller.loadCustomers(workspaceId);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        title: const Text('ลูกค้า'),
        backgroundColor: AppTheme.backgroundWhite,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),
          
          // Customer Count and Add Button
          _buildHeaderSection(),
          
          // Customer List
          Expanded(
            child: _buildCustomerList(),
          ),
        ],
      ),

    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.backgroundWhite,
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          _controller.setSearchQuery(value);
        },
        decoration: InputDecoration(
          hintText: 'ค้นหาลูกค้า...',
          prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    _controller.clearSearch();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppTheme.backgroundGrey,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppTheme.backgroundWhite,
      child: Row(
        children: [
          // Customer Count
          Obx(() => Text(
            'ลูกค้าทั้งหมด ${_controller.filteredCustomerCount} คน',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          )),
          const Spacer(),
          // Add Button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddEditCustomerPage(),
                ),
              );
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('เพิ่มลูกค้า'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerList() {
    return Obx(() {
      if (_controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryOrange,
          ),
        );
      }

      if (_controller.errorMessage.value.isNotEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                'เกิดข้อผิดพลาด',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _controller.errorMessage.value,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // TODO: Retry loading customers
                  const workspaceId = 'GkEJ3c6u9QU4utYO6KVZ';
                  _controller.loadCustomers(workspaceId);
                },
                child: const Text('ลองใหม่'),
              ),
            ],
          ),
        );
      }

      if (_controller.filteredCustomers.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _searchController.text.isEmpty ? Icons.people_outline : Icons.search_off,
                size: 64,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                _searchController.text.isEmpty ? 'ไม่มีลูกค้า' : 'ไม่พบลูกค้าที่ค้นหา',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchController.text.isEmpty 
                    ? 'เริ่มต้นเพิ่มลูกค้าคนแรกของคุณ'
                    : 'ลองค้นหาด้วยคำอื่น',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _controller.filteredCustomers.length,
        itemBuilder: (context, index) {
          final customer = _controller.filteredCustomers[index];
          return CustomerTile(
            customer: customer,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CustomerDetailPage(customer: customer),
                ),
              );
            },
          );
        },
      );
    });
  }
}
