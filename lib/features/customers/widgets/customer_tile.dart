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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
                      
                      // Contact Info
                      if (customer.emails.isNotEmpty || customer.phones.isNotEmpty)
                        Row(
                          children: [
                            if (customer.emails.isNotEmpty) ...[
                              Icon(
                                Icons.email_outlined,
                                size: 14,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  customer.emails,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                            if (customer.emails.isNotEmpty && customer.phones.isNotEmpty)
                              const SizedBox(width: 8),
                            if (customer.phones.isNotEmpty) ...[
                              Icon(
                                Icons.phone_outlined,
                                size: 14,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                customer.phones,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
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


