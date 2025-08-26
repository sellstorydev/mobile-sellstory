import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/workspace_members_service.dart';

class AssigneesInputField extends StatefulWidget {
  final List<String> selectedAssignees;
  final List<WorkspaceMember> availableMembers;
  final Function(List<String>) onAssigneesChanged;
  final String label;
  final String hintText;
  final bool isLoading;

  const AssigneesInputField({
    super.key,
    required this.selectedAssignees,
    required this.availableMembers,
    required this.onAssigneesChanged,
    this.label = 'เซลที่รับผิดชอบ',
    this.hintText = 'เลือกเซลที่รับผิดชอบ',
    this.isLoading = false,
  });

  @override
  State<AssigneesInputField> createState() => _AssigneesInputFieldState();
}

class _AssigneesInputFieldState extends State<AssigneesInputField> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          
          if (widget.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          else if (widget.availableMembers.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'ไม่พบสมาชิกในเวิร์กสเปซ',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            Column(
              children: [
                // Button to add new assignees
                InkWell(
                  onTap: _showAssigneesDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        // Small profile photo
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.person,
                            size: 16,
                            color: AppTheme.primaryOrange,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'เลือกสมาชิก',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_drop_down,
                          color: Colors.grey.shade600,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                                 // Selected assignees display
                 if (widget.selectedAssignees.isNotEmpty) ...[
                   Wrap(
                     alignment: WrapAlignment.start,
                     crossAxisAlignment: WrapCrossAlignment.start,
                     spacing: 8,
                     runSpacing: 4,
                     children: widget.selectedAssignees.map((assigneeId) {
                      final member = widget.availableMembers.firstWhere(
                        (m) => m.uid == assigneeId,
                        orElse: () => WorkspaceMember(
                          uid: assigneeId,
                          email: 'Unknown',
                          displayName: 'Unknown User',
                          permission: 'member',
                        ),
                      );
                      
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryOrange.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Small profile photo
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: member.photoURL != null && member.photoURL!.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        member.photoURL!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryOrange.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Center(
                                              child: Text(
                                                member.displayName.isNotEmpty 
                                                    ? member.displayName[0].toUpperCase()
                                                    : '?',
                                                style: const TextStyle(
                                                  fontSize: 8,
                                                  color: AppTheme.primaryOrange,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                  : Container(
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryOrange.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          member.displayName.isNotEmpty 
                                              ? member.displayName[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            fontSize: 8,
                                            color: AppTheme.primaryOrange,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              member.displayName,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.primaryOrange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                final newAssignees = List<String>.from(widget.selectedAssignees)
                                  ..remove(assigneeId);
                                widget.onAssigneesChanged(newAssignees);
                              },
                              child: Icon(
                                Icons.close,
                                size: 14,
                                color: AppTheme.primaryOrange,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  void _showAssigneesDialog() {
    final availableMembers = widget.availableMembers
        .where((member) => !widget.selectedAssignees.contains(member.uid))
        .toList();

    if (availableMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่มีสมาชิกที่สามารถเลือกได้'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(widget.label),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableMembers.length,
              itemBuilder: (context, index) {
                final member = availableMembers[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryOrange.withOpacity(0.1),
                    backgroundImage: member.photoURL != null && member.photoURL!.isNotEmpty
                        ? NetworkImage(member.photoURL!)
                        : null,
                    child: member.photoURL == null || member.photoURL!.isEmpty
                        ? Text(
                            member.displayName.isNotEmpty 
                                ? member.displayName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: AppTheme.primaryOrange,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  title: Text(member.displayName),
                  subtitle: Text(member.email),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getPermissionColor(member.permission).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      member.permission,
                      style: TextStyle(
                        fontSize: 10,
                        color: _getPermissionColor(member.permission),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  onTap: () {
                    final newAssignees = List<String>.from(widget.selectedAssignees)
                      ..add(member.uid);
                    widget.onAssigneesChanged(newAssignees);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ยกเลิก'),
            ),
          ],
        );
      },
    );
  }

  Color _getPermissionColor(String permission) {
    switch (permission.toLowerCase()) {
      case 'owner':
        return Colors.red;
      case 'admin':
        return Colors.orange;
      case 'member':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
