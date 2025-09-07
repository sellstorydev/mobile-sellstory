import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/customer.dart';

class CustomerTile extends StatelessWidget {
  final Customer customer;
  final VoidCallback? onTap;

  const CustomerTile({
    super.key,
    required this.customer,
    this.onTap,
  });

  // Helper methods to check for valid data
  bool _hasValidEmails() {
    return customer.emails.isNotEmpty && 
           customer.emails.any((email) => 
             email['value'] != null && 
             email['value'].toString().trim().isNotEmpty
           );
  }

  bool _hasValidPhones() {
    return customer.phones.isNotEmpty && 
           customer.phones.any((phone) => 
             phone['value'] != null && 
             phone['value'].toString().trim().isNotEmpty
           );
  }

  bool _hasValidCompanies() {
    return customer.companyNames.isNotEmpty && 
           customer.companyNames.any((company) => 
             company['value'] != null && 
             company['value'].toString().trim().isNotEmpty
           );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Profile Image
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primaryOrange.withOpacity(0.1),
                  child: Icon(
                    Icons.person,
                    size: 24,
                    color: AppTheme.primaryOrange,
                  ),
                ),
                const SizedBox(width: 16),
                // Customer Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        '${customer.prefix} ${customer.name}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      
                      // Customer ID
                      Text(
                        customer.customId,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.primaryOrange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      
                                             // Contact Info Icons
                       if (_hasValidEmails() || _hasValidPhones() || _hasValidCompanies())
                         Row(
                           children: [
                             if (_hasValidEmails())
                               Icon(
                                 Icons.email_outlined,
                                 size: 16,
                                 color: AppTheme.textSecondary,
                               ),
                             if (_hasValidEmails() && (_hasValidPhones() || _hasValidCompanies()))
                               const SizedBox(width: 8),
                             if (_hasValidPhones())
                               Icon(
                                 Icons.phone_outlined,
                                 size: 16,
                                 color: AppTheme.textSecondary,
                               ),
                             if (_hasValidPhones() && _hasValidCompanies())
                               const SizedBox(width: 8),
                             if (_hasValidCompanies())
                               Icon(
                                 Icons.business_outlined,
                                 size: 16,
                                 color: AppTheme.textSecondary,
                               ),
                           ],
                         ),
                    ],
                  ),
                ),
                
                // Customer Type Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: customer.customerType == 'Customer' 
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    customer.customerType,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: customer.customerType == 'Customer' 
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                ),
                
                // Arrow Icon
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: AppTheme.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


