import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/header_widget.dart';

class JobCardPage extends StatelessWidget {
  const JobCardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      body: CustomScrollView(
        slivers: [
          const HeaderWidget(),
          
          // Summary Statistics Row
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Status
                  Expanded(
                    child: _buildSummaryCard(
                      icon: Icons.group,
                      iconColor: Colors.red,
                      title: 'สถานะ',
                      value: '48 รายการ',
                      context: context,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Total
                  Expanded(
                    child: _buildSummaryCard(
                      icon: Icons.account_balance_wallet,
                      iconColor: Colors.green,
                      title: 'ยอดรวม',
                      value: '฿9,605,000,000',
                      context: context,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Outstanding
                  Expanded(
                    child: _buildSummaryCard(
                      icon: Icons.description,
                      iconColor: Colors.orange,
                      title: 'ค้างชำระ',
                      value: '฿4,318,000,000',
                      context: context,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Overdue
                  Expanded(
                    child: _buildSummaryCard(
                      icon: Icons.warning,
                      iconColor: Colors.red,
                      title: 'เกินกำหนด',
                      value: '฿4,159,000,432',
                      context: context,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // New Section Header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text(
                    'New',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '5',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'ยอดรวม ฿180,000.50',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.more_vert,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          
          // Job Cards List
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _buildJobCard(context, index),
                );
              },
              childCount: 2, // Show 2 job cards as in the screenshot
            ),
          ),
          
          const SliverToBoxAdapter(
            child: SizedBox(height: 80), // Bottom padding for FAB
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add new job card
        },
        backgroundColor: AppTheme.primaryOrange,
        foregroundColor: Colors.white,
        child: const Icon(Icons.keyboard_arrow_up),
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(BuildContext context, int index) {
    final isFirstCard = index == 0;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isFirstCard ? Colors.pink[50] : Colors.pink[50],
        ),
        child: Stack(
          children: [
            // Overdue banner for second card
            if (!isFirstCard)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'เกินเวลาที่กำหนด',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tags Row
                  if (isFirstCard) ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.pink[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'do Hashtag',
                            style: TextStyle(
                              color: Colors.pink[700],
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'So Hashtag',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Hashtag',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Progress bar
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.yellow[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // Job Card ID and Status
                  Row(
                    children: [
                      Text(
                        isFirstCard ? 'JC0012' : 'JC0013',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isFirstCard ? 'น้อย' : 'กลาง',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Date Range
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isFirstCard 
                            ? '30 ม.ค. 2567 - 28 ธ.ค. 2557'
                            : '30 ม.ค. 2567 - 28 ธ.ค. 2567',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  
                  // Stats for second card
                  if (!isFirstCard) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.visibility, size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text('4', style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(width: 12),
                        Icon(Icons.chat_bubble_outline, size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text('1', style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(width: 12),
                        Icon(Icons.check_circle_outline, size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text('0/3', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 12),
                  
                  // Customer Info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white,
                        child: Text(
                          isFirstCard ? 'S' : 'ก',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isFirstCard 
                                  ? 'รัญญารัตน์ วรเตชะทรัพย์'
                                  : 'กฤติรัช ปัทมเดชา',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              isFirstCard
                                  ? 'บริษัท บิงชูภูเขาไฟ จํากัด มหาชน'
                                  : 'บริษัท เบอร์ลี่ ยุคเกอร์ จํากัด (มหาชน)',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // Sales Person Info
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.grey[200],
                        child: Text(
                          isFirstCard ? 'อ' : 'อ',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isFirstCard ? 'อรสพร 5.' : 'อรสพร 5.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  
                  // Tasks for second card
                  if (!isFirstCard) ...[
                    const SizedBox(height: 12),
                    Column(
                      children: [
                        _buildTaskItem('โทรแจ้งการเปลี่ยนราคาสินค้า....', '23 ม.ค.'),
                        _buildTaskItem('ไปหาลูกค้า', '2 ก.พ.'),
                        _buildTaskItem('โทรแจ้งการเปลี่ยนราคาสินค้า...', '31 ม.ค.'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '+ เพิ่ม Job Card',
                      style: TextStyle(
                        color: AppTheme.primaryOrange,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  
                  // Amount Badge
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '฿0.00',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
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

  Widget _buildTaskItem(String task, String date) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              task,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
          Text(
            date,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
