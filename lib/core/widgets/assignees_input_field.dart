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
  final bool allowMultipleSelection;

  const AssigneesInputField({
    super.key,
    required this.selectedAssignees,
    required this.availableMembers,
    required this.onAssigneesChanged,
    this.label = 'เซลที่รับผิดชอบ',
    this.hintText = 'เลือกเซลที่รับผิดชอบ',
    this.isLoading = false,
    this.allowMultipleSelection = true,
  });

  @override
  State<AssigneesInputField> createState() => _AssigneesInputFieldState();
}

class _AssigneesInputFieldState extends State<AssigneesInputField> {
  final TextEditingController _searchController = TextEditingController();
  List<WorkspaceMember> _filteredMembers = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _filteredMembers = List.from(widget.availableMembers);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _isSearching = _searchController.text.isNotEmpty;
      if (_isSearching) {
        _filteredMembers = widget.availableMembers
            .where((member) =>
                member.displayName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                member.email.toLowerCase().contains(_searchController.text.toLowerCase()))
            .toList();
      } else {
        _filteredMembers = List.from(widget.availableMembers);
      }
    });
  }

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
                // Button to open full page selection
                InkWell(
                  onTap: _showAssigneesFullPage,
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
                          widget.allowMultipleSelection ? 'เลือกสมาชิก' : 'เลือกสมาชิก',
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

  void _showAssigneesFullPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AssigneesSelectionPage(
          selectedAssignees: List.from(widget.selectedAssignees),
          availableMembers: widget.availableMembers,
          onAssigneesChanged: widget.onAssigneesChanged,
          label: widget.label,
          allowMultipleSelection: widget.allowMultipleSelection,
        ),
      ),
    );
  }
}

class AssigneesSelectionPage extends StatefulWidget {
  final List<String> selectedAssignees;
  final List<WorkspaceMember> availableMembers;
  final Function(List<String>) onAssigneesChanged;
  final String label;
  final bool allowMultipleSelection;

  const AssigneesSelectionPage({
    super.key,
    required this.selectedAssignees,
    required this.availableMembers,
    required this.onAssigneesChanged,
    required this.label,
    required this.allowMultipleSelection,
  });

  @override
  State<AssigneesSelectionPage> createState() => _AssigneesSelectionPageState();
}

class _AssigneesSelectionPageState extends State<AssigneesSelectionPage> {
  final TextEditingController _searchController = TextEditingController();
  List<WorkspaceMember> _filteredMembers = [];
  List<String> _tempSelectedAssignees = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tempSelectedAssignees = List.from(widget.selectedAssignees);
    _filteredMembers = List.from(widget.availableMembers);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _isSearching = _searchController.text.isNotEmpty;
      if (_isSearching) {
        _filteredMembers = widget.availableMembers
            .where((member) =>
                member.displayName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                member.email.toLowerCase().contains(_searchController.text.toLowerCase()))
            .toList();
      } else {
        _filteredMembers = List.from(widget.availableMembers);
      }
    });
  }

  void _toggleSelection(String assigneeId) {
    setState(() {
      if (_tempSelectedAssignees.contains(assigneeId)) {
        _tempSelectedAssignees.remove(assigneeId);
      } else {
        if (widget.allowMultipleSelection) {
          _tempSelectedAssignees.add(assigneeId);
        } else {
          // Single selection mode - replace current selection
          _tempSelectedAssignees = [assigneeId];
        }
      }
    });
  }

  void _applySelection() {
    widget.onAssigneesChanged(_tempSelectedAssignees);
    Navigator.of(context).pop();
  }

  void _clearSelection() {
    setState(() {
      _tempSelectedAssignees.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: Text(
          widget.label,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.backgroundWhite,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          if (_tempSelectedAssignees.isNotEmpty)
            TextButton(
              onPressed: _clearSelection,
              child: const Text(
                'ล้าง',
                style: TextStyle(
                  color: AppTheme.primaryOrange,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ค้นหาสมาชิก...',
                hintStyle: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppTheme.textSecondary,
                ),
                filled: true,
                fillColor: AppTheme.backgroundGrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Selection mode indicator
          if (widget.allowMultipleSelection)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange.withOpacity(0.05),
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.primaryOrange.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: AppTheme.primaryOrange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'เลือกแล้ว ${_tempSelectedAssignees.length} รายการ',
                    style: TextStyle(
                      color: AppTheme.primaryOrange,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // Members list
          Expanded(
            child: _filteredMembers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'ไม่พบสมาชิกที่ตรงกับคำค้นหา',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredMembers.length,
                    itemBuilder: (context, index) {
                      final member = _filteredMembers[index];
                      final isSelected = _tempSelectedAssignees.contains(member.uid);

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryOrange.withOpacity(0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryOrange
                                : Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
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
                          title: Text(
                            member.displayName,
                            style: TextStyle(
                              color: isSelected ? AppTheme.primaryOrange : AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            member.email,
                            style: TextStyle(
                              color: isSelected ? AppTheme.primaryOrange.withOpacity(0.7) : AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
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
                          onTap: () => _toggleSelection(member.uid),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.grey.shade400),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'ยกเลิก',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _applySelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'ยืนยัน',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
