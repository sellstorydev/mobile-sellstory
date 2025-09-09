import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/company.dart';

class CompanyTile extends StatelessWidget {
  final Company company;

  const CompanyTile({
    super.key,
    required this.company,
  });


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Company icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.business,
              color: AppTheme.primaryOrange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Company info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Company name and branch
                Row(
                  children: [
                    if(company.name != "")
                    Expanded(
                      child: Text(
                        company.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (company.branch.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withAlpha(25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          company.branch,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),


                if (company.customId.isNotEmpty) ...[
                  Text(
                      'รหัส: ${company.customId}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                ],
                const SizedBox(height: 4),


                // Tax ID and custom ID (single line, ellipsis as needed)
                Row(
                  children: [
                    if (company.taxId.isNotEmpty) ...[
                      Icon(
                        Icons.receipt_long,
                        size: 12,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'เลขประจำตัวผู้เสียภาษี: ${company.taxId}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],


                  ],
                ),

                const SizedBox(height: 4),

                // Contact info (first email or phone)
                _buildContactInfo(),
              ],
            ),
          ),


          // Associated customers count
          Column(
            children: [
              Text(
                '${company.associatedCustomerIds.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryOrange,
                ),
              ),
              Text(
                'ลูกค้า',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),

          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right,
            color: Colors.grey.shade400,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    // Try to get first email
    String? firstEmail;
    try {
      final emailData = company.emails.firstWhere(
        (e) => (e['value'] ?? '').toString().trim().isNotEmpty,
        orElse: () => {},
      );
      firstEmail = (emailData['value'] ?? '').toString().trim();
      if (firstEmail.isEmpty) firstEmail = null;
    } catch (_) {
      firstEmail = null;
    }

    // Try to get first phone
    String? firstPhone;
    try {
      final phoneData = company.phones.firstWhere(
        (p) => (p['value'] ?? '').toString().trim().isNotEmpty,
        orElse: () => {},
      );
      firstPhone = (phoneData['value'] ?? '').toString().trim();
      if (firstPhone.isEmpty) firstPhone = null;
    } catch (_) {
      firstPhone = null;
    }

    // Website as fallback
    final hasWebsite = company.website.isNotEmpty;

    if (firstEmail != null) {
      return Row(
        children: [
          Icon(
            Icons.email,
            size: 12,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              firstEmail,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    } else if (firstPhone != null) {
      return Row(
        children: [
          Icon(
            Icons.phone,
            size: 12,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            firstPhone,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      );
    } else if (hasWebsite) {
      return Row(
        children: [
          Icon(
            Icons.language,
            size: 12,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              company.website,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return Text(
      'ไม่มีข้อมูลติดต่อ',
      style: TextStyle(
        fontSize: 11,
        color: Colors.grey.shade400,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}
