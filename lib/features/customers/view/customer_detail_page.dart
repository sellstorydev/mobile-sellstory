import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../app/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/workspace_members_service.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/job_card.dart';
import '../../../data/repositories/firestore_repository.dart';
import '../controller/customers_controller.dart';
import 'add_edit_customer_page.dart';
import '../../../data/services/mobile_permissions_service.dart';

class CustomerDetailPage extends StatefulWidget {
  final Customer customer;

  const CustomerDetailPage({
    super.key,
    required this.customer,
  });

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> with SingleTickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  final WorkspaceMembersService _workspaceMembersService = WorkspaceMembersService();
  final CustomersController _controller = Get.find<CustomersController>();
  final FirestoreRepository _repository = Get.find<FirestoreRepository>();
  List<WorkspaceMember> _workspaceMembers = [];

  // Current customer data that can be updated
  Customer? _currentCustomer;

  // Worker to manage the customer updates listener
  Worker? _customerUpdateListener;
  
  // Tab controller
  late TabController _tabController;

  Future<void> _refreshCustomerData() async {
    print('[CustomerDetail] Refreshing customer data...');
    
    // Refresh customers list to get latest data
    try {
      await _controller.refreshCustomers();
      
      // Find updated customer data
      final updatedCustomer = _controller.customers
          .firstWhereOrNull((c) => c.id == widget.customer.id);
      
      if (updatedCustomer != null) {
        setState(() {
          _currentCustomer = updatedCustomer;
        });
        print('[CustomerDetail] ✅ Customer data refreshed');
      } else {
        print('[CustomerDetail] ⚠️ Customer not found in refreshed list');
      }
    } catch (e) {
      print('[CustomerDetail] ❌ Failed to refresh customer data: $e');
    }
  }
  
  // Job cards data
  Stream<List<JobCard>>? _jobCardsStream;
  int _jobCardCount = 0;
  int _todoCount = 0;
  int _historyCount = 0;
  int _documentCount = 0;
  List<JobCard> _jobCards = [];
  bool _jobCardsLoading = true;
  StreamSubscription<List<JobCard>>? _jobCardsSub;

  // History data  
  List<QueryDocumentSnapshot> _historyActivities = [];
  bool _historyLoading = false;

  // Documents data
  StreamSubscription<List<Map<String, dynamic>>>? _documentsSub;

  // Helper methods to check for valid data
  bool _hasValidEmails() {
    final customer = _currentCustomer ?? widget.customer;
    return customer.emails.isNotEmpty && 
           customer.emails.any((email) => 
             email['value'] != null && 
             email['value'].toString().trim().isNotEmpty
           );
  }

  bool _hasValidPhones() {
    final customer = _currentCustomer ?? widget.customer;
    return customer.phones.isNotEmpty && 
           customer.phones.any((phone) => 
             phone['value'] != null && 
             phone['value'].toString().trim().isNotEmpty
           );
  }

  bool _hasValidCompanies() {
    final customer = _currentCustomer ?? widget.customer;
    return customer.companyNames.isNotEmpty && 
           customer.companyNames.any((company) => 
             company['value'] != null && 
             company['value'].toString().trim().isNotEmpty
           );
  }

  bool _hasValidHashtags() {
    final customer = _currentCustomer ?? widget.customer;
    return customer.hashtags.isNotEmpty && 
           customer.hashtags.any((hashtag) => 
             hashtag['id'] != null && 
             hashtag['id'].toString().trim().isNotEmpty
           );
  }

  bool _hasValidAssignees() {
    final customer = _currentCustomer ?? widget.customer;
    return customer.assignees.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _currentCustomer = widget.customer;
    _tabController = TabController(length: 6, vsync: this);
    _loadWorkspaceMembers();
    _listenToCustomerUpdates();
    _initJobCardsStream();
    _initDocumentsStream(); // Load documents data on page load
    _loadHistoryData(); // Load history data on page load
    
    // Force UI rebuild after streams are initialized to update tab counts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
    
    // Add observer for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
    
    // Refresh customer data when entering the page
    _refreshCustomerData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route changes only after dependencies are ready
    final route = ModalRoute.of(context);
    if (route is PageRoute && Get.isRegistered<RouteObserver>()) {
      Get.find<RouteObserver>().subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    super.didPopNext();
    // Called when returning to this page from another page
    print('[CustomerDetail] Returned from another page, refreshing customer data...');
    _refreshCustomerData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh data when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      print('[CustomerDetail] App resumed, refreshing customer data...');
      _refreshCustomerData();
    }
  }

  bool _isCurrentUserAssigned() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final customer = _currentCustomer ?? widget.customer;
    if (uid == null) return false;
    return customer.assignees.contains(uid);
  }

  bool _canEditCustomer() {
    final svc = MobilePermissionsService.to;
    if (svc.isOwner || svc.can('customer:edit:all')) return true;
    return svc.can('customer:edit:assigned') && _isCurrentUserAssigned();
  }

  bool _canViewAnyJobcard() {
    final svc = MobilePermissionsService.to;
    return svc.isOwner || svc.can('jobcard:view:all') || svc.can('jobcard:view:assigned');
  }

  bool _canDeleteCustomer() {
    final svc = MobilePermissionsService.to;
    return svc.isOwner || svc.can('customer:delete');
  }

  Future<void> _handleDeleteCustomer() async {
    final customer = _currentCustomer ?? widget.customer;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบลูกค้า'),
        content: Text('คุณแน่ใจหรือไม่ว่าต้องการลบลูกค้า "${customer.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final workspaceId = _controller.currentWorkspaceId.value.isNotEmpty
          ? _controller.currentWorkspaceId.value
          : customer.workspaceId;
      await _controller.deleteCustomer(workspaceId, customer.id);
      if (mounted) {
        Navigator.of(context).pop(); // leave detail page after delete
      }
    }
  }

  List<JobCard> _visibleJobcards(List<JobCard> all) {
    final svc = MobilePermissionsService.to;
    if (svc.isOwner || svc.can('jobcard:view:all')) return all;
    if (svc.can('jobcard:view:assigned')) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return const [];
      return all.where((jc) => jc.assignedTo == uid).toList();
    }
    return const [];
  }

  void _recomputeJobcardCounts(List<JobCard> all) {
    final visible = _visibleJobcards(all);
    int todoCount = 0;
    for (final jobCard in visible) {
      todoCount += jobCard.todos.length;
    }
    setState(() {
      _jobCards = all; // keep raw; filter in builders
      _jobCardsLoading = false;
      _jobCardCount = visible.length;
      _todoCount = todoCount;
    });
  }

  void _initJobCardsStream() {
    // Get current workspace ID
    final workspaceId = _controller.currentWorkspaceId.value.isNotEmpty 
        ? _controller.currentWorkspaceId.value 
        : widget.customer.workspaceId;
    
    // Initialize the job cards stream for this customer
    _jobCardsStream = _repository.getCardsForCustomerStream(workspaceId, widget.customer.id);
    
    // Listen to job cards stream to update counts
    _jobCardsSub = _jobCardsStream?.listen((jobCards) {
      if (!mounted) return;
      _recomputeJobcardCounts(jobCards);
    }, onError: (_) {
      if (!mounted) return;
      setState(() {
        _jobCardsLoading = false; // stop infinite loading even on error
      });
    });
  }

  void _initDocumentsStream() {
    final customer = _currentCustomer ?? widget.customer;
    final workspaceId = customer.workspaceId;

    // Quick one-shot prefetch to populate count ASAP before first stream emission
    FirebaseFirestore.instance
        .collection('workspaces')
        .doc(workspaceId)
        .collection('cards')
        .where('customers', arrayContains: customer.id)
        .get()
        .then((snapshot) {
      if (!mounted) return;
      int tempCount = 0;
      for (var cardDoc in snapshot.docs) {
        final cardData = cardDoc.data();
        final relatedDocuments = cardData['relatedDocuments'] as List<dynamic>? ?? [];
        tempCount += relatedDocuments.length;
      }
      // Only set if stream hasn't already provided a value
      if (mounted && _documentCount == 0 && tempCount != 0) {
        setState(() {
          _documentCount = tempCount;
        });
      }
    }).catchError((_) {});
    
    // Stream to monitor all cards in the workspace that have this customer
    final stream = FirebaseFirestore.instance
        .collection('workspaces')
        .doc(workspaceId)
        .collection('cards')
        .where('customers', arrayContains: customer.id)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> allDocuments = [];
      
      for (var cardDoc in snapshot.docs) {
        final cardData = cardDoc.data();
        final cardTitle = cardData['title'] ?? 'Untitled Card';
        final relatedDocuments = cardData['relatedDocuments'] as List<dynamic>? ?? [];
        
        for (var docRef in relatedDocuments) {
          final docData = Map<String, dynamic>.from(docRef);
          
          // Fetch detailed document information if needed
          final documentId = docData['id'];
          if (documentId != null) {
            try {
              final docSnapshot = await FirebaseFirestore.instance
                  .collection('workspaces')
                  .doc(workspaceId)
                  .collection('documents')
                  .doc(documentId)
                  .get();
              
              if (docSnapshot.exists) {
                final fullDocData = docSnapshot.data()!;
                allDocuments.add({
                  'id': documentId,
                  'fileName': fullDocData['fileName'] ?? docData['docNo'] ?? 'Unknown File',
                  'jobCard': cardTitle,
                  'cardId': cardDoc.id,
                  'uploadedBy': fullDocData['createdBy'] ?? 'Unknown',
                  'uploadedAt': fullDocData['createdAt'],
                  'type': fullDocData['type'] ?? docData['type'] ?? 'Unknown',
                  'status': fullDocData['status'] ?? 'Active',
                  'downloadUrl': fullDocData['downloadUrl'],
                  ...fullDocData,
                });
              } else {
                // Document not found, show placeholder
                allDocuments.add({
                  'id': documentId,
                  'fileName': docData['docNo'] ?? 'Missing Document',
                  'jobCard': cardTitle,
                  'cardId': cardDoc.id,
                  'uploadedBy': 'Unknown',
                  'uploadedAt': null,
                  'type': docData['type'] ?? 'Unknown',
                  'status': 'NOT_FOUND',
                });
              }
            } catch (e) {
              print('Error loading document $documentId: $e');
            }
          }
        }
      }
      
      // Sort by upload date (newest first)
      allDocuments.sort((a, b) {
        final aDate = a['uploadedAt'];
        final bDate = b['uploadedAt'];
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        
        if (aDate is String && bDate is String) {
          return DateTime.parse(bDate).compareTo(DateTime.parse(aDate));
        }
        return 0;
      });
      
      return allDocuments;
    });

    // Listen to documents stream to update count
    _documentsSub = stream.listen((documents) {
      if (!mounted) return;
      setState(() {
        _documentCount = documents.length;
      });
    }, onError: (error) {
      print('Error loading documents: $error');
      if (!mounted) return;
      setState(() {
        _documentCount = 0;
      });
    });
  }

  Future<void> _loadHistoryData() async {
    if (_historyLoading) return;
    
    setState(() {
      _historyLoading = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('workspaces')
          .doc(widget.customer.workspaceId)
          .collection('activities')
          .where('type', isEqualTo: 'card-create')
          .get();

      final activities = snapshot.docs;
      
      // Sort activities by timestamp in descending order (client-side)
      activities.sort((a, b) {
        final aData = a.data();
        final bData = b.data();
        
        // Handle timestamp that can be either Timestamp or int
        Timestamp? aTimestamp;
        Timestamp? bTimestamp;
        
        final aTimestampRaw = aData['timestamp'];
        final bTimestampRaw = bData['timestamp'];
        
        if (aTimestampRaw is Timestamp) {
          aTimestamp = aTimestampRaw;
        } else if (aTimestampRaw is int) {
          aTimestamp = Timestamp.fromMillisecondsSinceEpoch(aTimestampRaw);
        }
        
        if (bTimestampRaw is Timestamp) {
          bTimestamp = bTimestampRaw;
        } else if (bTimestampRaw is int) {
          bTimestamp = Timestamp.fromMillisecondsSinceEpoch(bTimestampRaw);
        }
        
        if (aTimestamp == null && bTimestamp == null) return 0;
        if (aTimestamp == null) return 1;
        if (bTimestamp == null) return -1;
        
        return bTimestamp.compareTo(aTimestamp); // Descending order
      });

      if (mounted) {
        setState(() {
          _historyActivities = activities;
          _historyCount = activities.length;
          _historyLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _historyLoading = false;
        });
      }
    }
  }

  Future<void> _updateTodoCompletion(String jobCardId, String todoId, bool completed) async {
    if (jobCardId.isEmpty || todoId.isEmpty) return;

    try {
      final workspaceId = _controller.currentWorkspaceId.value.isNotEmpty
          ? _controller.currentWorkspaceId.value
          : widget.customer.workspaceId;

      // Try cards collection first (new structure)
      DocumentReference docRef = FirebaseFirestore.instance
          .collection('workspaces')
          .doc(workspaceId)
          .collection('cards')
          .doc(jobCardId);
      
      DocumentSnapshot docSnapshot = await docRef.get();
      
      // If not found in cards, try jobCards collection (old structure)
      if (!docSnapshot.exists) {
        docRef = FirebaseFirestore.instance
            .collection('workspaces')
            .doc(workspaceId)
            .collection('jobCards')
            .doc(jobCardId);
        
        docSnapshot = await docRef.get();
        
        if (!docSnapshot.exists) {
          throw Exception('Job card not found in both cards and jobCards collections');
        }
      }

      // Get current todos from Firestore document
      final docData = docSnapshot.data() as Map<String, dynamic>?;
      final currentTodos = List<Map<String, dynamic>>.from(docData?['todos'] ?? []);
      
      // Find and update the specific todo
      final todoIndex = currentTodos.indexWhere((todo) => todo['id'] == todoId);
      if (todoIndex == -1) {
        throw Exception('Todo item not found');
      }

      // Update the todo completion status
      currentTodos[todoIndex]['completed'] = completed;

      // Update the entire todos array
      await docRef.update({'todos': currentTodos});

      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(completed ? 'ทำเครื่องหมายเสร็จแล้ว' : 'ยกเลิกการทำเครื่องหมาย'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถอัปเดตสถานะ To-Do ได้: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _customerUpdateListener?.dispose();
    _jobCardsSub?.cancel();
    _documentsSub?.cancel();
    _tabController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    
    // Unsubscribe from route observer
    if (Get.isRegistered<RouteObserver>()) {
      Get.find<RouteObserver>().unsubscribe(this);
    }
    
    super.dispose();
  }

  void _listenToCustomerUpdates() {
    _customerUpdateListener = ever(_controller.customers, (customers) {
      if (customers.isNotEmpty && mounted) {
        final updatedCustomer = customers.firstWhere(
          (customer) => customer.id == widget.customer.id,
          orElse: () => widget.customer,
        );

        if (updatedCustomer != _currentCustomer) {
          setState(() {
            _currentCustomer = updatedCustomer;
          });
        }
      }
    });
  }

  Future<void> _loadWorkspaceMembers() async {
    try {
      final workspaceId = _controller.currentWorkspaceId.value.isNotEmpty
          ? _controller.currentWorkspaceId.value
          : widget.customer.workspaceId;

      final members = await _workspaceMembersService.getWorkspaceMembers(workspaceId);
      setState(() {
        _workspaceMembers = members;
      });
    } catch (e) {
      setState(() {});
    }
  }

  Future<void> _launchPhone() async {
    try {
      final customer = _currentCustomer ?? widget.customer;
      final first = customer.phones.firstWhere(
        (p) => (p['value'] ?? '').toString().trim().isNotEmpty,
        orElse: () => {},
      );
      final phone = (first['value'] ?? '').toString().trim();
      if (phone.isEmpty) return;
      final uri = Uri(scheme: 'tel', path: phone);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  Future<void> _launchEmail() async {
    try {
      final customer = _currentCustomer ?? widget.customer;
      final first = customer.emails.firstWhere(
        (e) => (e['value'] ?? '').toString().trim().isNotEmpty,
        orElse: () => {},
      );
      final email = (first['value'] ?? '').toString().trim();
      if (email.isEmpty) return;
      final uri = Uri(scheme: 'mailto', path: email);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  Widget _buildActionButtons() {
    Widget circleIcon(IconData icon, VoidCallback onTap) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryOrange,
            size: 24,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          circleIcon(Icons.phone, _launchPhone),
          const SizedBox(width: 40),
          circleIcon(Icons.email, _launchEmail),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'not_specified'.tr,
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

  Widget _buildEmailsDisplay() {
    final customer = _currentCustomer ?? widget.customer;
    if (!_hasValidEmails()) {
      return _buildInfoRow('email'.tr, 'not_specified'.tr);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'email'.tr,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        ...customer.emails.where((email) => 
          email['value'] != null && 
          email['value'].toString().trim().isNotEmpty
        ).map((email) {
          final label = email['label']?.toString() ?? '';
          final value = email['value']?.toString() ?? '';
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '$label: $value',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPhonesDisplay() {
    final customer = _currentCustomer ?? widget.customer;
    if (!_hasValidPhones()) {
      return _buildInfoRow('เบอร์โทร', 'ไม่ระบุ');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'เบอร์โทร',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        ...customer.phones.where((phone) => 
          phone['value'] != null && 
          phone['value'].toString().trim().isNotEmpty
        ).map((phone) {
          final label = phone['label']?.toString() ?? '';
          final value = phone['value']?.toString() ?? '';
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '$label: $value',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildCompanyNamesDisplay() {
    final customer = _currentCustomer ?? widget.customer;
    if (!_hasValidCompanies()) {
      return _buildInfoRow('บริษัท', 'ไม่ระบุ');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'บริษัท',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: customer.companyNames.where((company) => 
            company['value'] != null && 
            company['value'].toString().trim().isNotEmpty
          ).map((company) {
            final name = company['value']?.toString() ?? '';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildHashtagDisplay() {
    final customer = _currentCustomer ?? widget.customer;
    if (!_hasValidHashtags()) {
      return _buildInfoRow('แฮชแท็ก', 'ไม่มี');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'แฮชแท็ก',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: customer.hashtags.where((hashtag) => 
            hashtag['id'] != null && 
            hashtag['id'].toString().trim().isNotEmpty
          ).map((hashtag) {
            final text = hashtag['text']?.toString() ?? hashtag['id']?.toString() ?? '';
            final color = hashtag['color']?.toString() ?? '#FF6B35';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _parseColor(color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _parseColor(color).withOpacity(0.3)),
              ),
              child: Text(
                '#$text',
                style: TextStyle(
                  fontSize: 12,
                  color: _parseColor(color),
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAssigneesDisplay() {
    final customer = _currentCustomer ?? widget.customer;
    if (!_hasValidAssignees()) {
      return _buildInfoRow('ผู้รับผิดชอบ', 'ไม่มี');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ผู้รับผิดชอบ',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: customer.assignees.map((assigneeId) {
            final member = _workspaceMembers.firstWhere(
              (m) => m.uid == assigneeId,
              orElse: () => WorkspaceMember(
                uid: assigneeId,
                email: '',
                displayName: assigneeId,
                permission: 'member',
              ),
            );
            
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primaryOrange.withOpacity(0.3)),
              ),
              child: Text(
                member.displayName,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryOrange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _parseColor(String colorString) {
    try {
      String hex = colorString.replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex'; // Add alpha if not present
      }
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return AppTheme.primaryOrange; // Default color
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year + 543}';
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
            backgroundColor: AppTheme.primaryOrange.withAlpha(25),
            backgroundImage: (_currentCustomer != null && _currentCustomer!.profileImageUrl.isNotEmpty)
                ? NetworkImage(_currentCustomer!.profileImageUrl)
                : null,
            child: (_currentCustomer == null || _currentCustomer!.profileImageUrl.isEmpty)
                ? Icon(
                    Icons.person,
                    size: 40,
                    color: AppTheme.primaryOrange,
                  )
                : null,
          ),

          const SizedBox(height: 16),
          
          // Name
          Text(
            '${_currentCustomer!.prefix} ${_currentCustomer!.name}',
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
              _currentCustomer!.customId,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryOrange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar() {
    Widget cell(String title, String value, {Color? valueColor}) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? const Color(0xFF1F2937),
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          cell('จำนวนการซื้อซ้ำ', '0 ครั้ง'),
          Container(
            width: 0.5,
            height: 60,
            color: const Color(0xFFE5E7EB),
          ),
          cell('ยอดชำระรวม', '฿0.00', valueColor: const Color(0xFF10B981)),
        ],
      ),
    );
  }

  Widget _buildHeaderSummary() {
    final customer = _currentCustomer ?? widget.customer;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: (customer.profileImageUrl.isNotEmpty)
                ? ClipOval(child: Image.network(customer.profileImageUrl, width: 56, height: 56, fit: BoxFit.cover))
                : const Icon(
                    Icons.person,
                    color: AppTheme.primaryOrange,
                    size: 28,
                  ),
          ),
          const SizedBox(height: 10),
          Text(
            '${customer.prefix.isNotEmpty ? '${customer.prefix} ' : ''}${customer.name}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Color(0xFF1F2937),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange.withAlpha(25),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'ลูกค้า',
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.primaryOrange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopInfoSection() {
    final customer = _currentCustomer ?? widget.customer;

    String? firstPhone() {
      try {
        final p = customer.phones.firstWhere(
          (e) => (e['value'] ?? '').toString().trim().isNotEmpty,
          orElse: () => {},
        );
        final v = (p['value'] ?? '').toString().trim();
        return v.isEmpty ? null : v;
      } catch (_) {
        return null;
      }
    }

    String? firstEmail() {
      try {
        final e = customer.emails.firstWhere(
          (m) => (m['value'] ?? '').toString().trim().isNotEmpty,
          orElse: () => {},
        );
        final v = (e['value'] ?? '').toString().trim();
        return v.isEmpty ? null : v;
      } catch (_) {
        return null;
      }
    }

    final phone = firstPhone();
    final email = firstEmail();

    final List<Widget> rows = [];

    if (customer.customId.isNotEmpty) {
      rows.add(Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.badge, size: 16, color: Color(0xFF6B7280)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'รหัสลูกค้า: ${customer.customId}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ));
    }

    if (phone != null) {
      rows.add(const SizedBox(height: 4));
      rows.add(Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.phone, size: 16, color: Color(0xFF6B7280)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              phone,
              style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ));
    }

    if (email != null) {
      rows.add(const SizedBox(height: 4));
      rows.add(Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.email, size: 16, color: Color(0xFF6B7280)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              email,
              style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ));
    }

    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: rows,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customer = _currentCustomer ?? widget.customer;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        elevation: 0,
        title: Text(
          customer.name.isNotEmpty ? customer.name : 'รายละเอียดลูกค้า',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_canEditCustomer())
            IconButton(
              tooltip: 'แก้ไข',
              icon: const Icon(Icons.edit, color: AppTheme.primaryOrange),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddEditCustomerPage(
                      customer: customer,
                      customerSources: _controller.customerSources,
                    ),
                  ),
                );

                if (result == true) {
                  final updated = _controller.getCustomerById(customer.id);
                  if (updated != null && mounted) {
                    setState(() {
                      _currentCustomer = updated;
                    });
                  }
                }
              },
            ),
          if (_canDeleteCustomer())
            IconButton(
              tooltip: 'ลบ',
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: _handleDeleteCustomer,
            ),
        ],
      ),
      body: Builder(
        builder: (context) {
          final svc = MobilePermissionsService.to;
          final canAllView = svc.isOwner || svc.can('customer:view:all');
          final canAssignedView = svc.can('customer:view:assigned') && _isCurrentUserAssigned();
          final canView = canAllView || canAssignedView;
          if (!canView) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.lock_outline, size: 56, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('คุณไม่มีสิทธิ์ดูรายละเอียดลูกค้ารายนี้',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey)),
                  ],
                ),
              ),
            );
          }

          return SafeArea(
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildProfileCard(),
                            const SizedBox(height: 16),
                            _buildInfoSection('ข้อมูลลูกค้า', [
                              _buildInfoRow('รหัสลูกค้า', _currentCustomer!.customId),
                              _buildInfoRow('ชื่อ', '${_currentCustomer!.prefix} ${_currentCustomer!.name}'),
                              _buildInfoRow('เพศ', _currentCustomer!.gender),
                              _buildInfoRow('อายุ', '${_currentCustomer!.age} ปี'),
                              _buildInfoRow('ประเภท', _currentCustomer!.customerType),
                              if (_currentCustomer!.nationalId.isNotEmpty)
                                _buildInfoRow(
                                  'เลขประจำตัวประชาชน',
                                  _currentCustomer!.nationalId,
                                ),
                            ]),
                            
                            const SizedBox(height: 16),
                            _buildInfoSection('ข้อมูลติดต่อ', [
                              _buildEmailsDisplay(),
                              _buildPhonesDisplay(),
                            ]),
                            const SizedBox(height: 16),
                            if (_hasValidCompanies()) ...[
                              _buildInfoSection('ข้อมูลบริษัท', [
                                _buildCompanyNamesDisplay(),
                              ]),
                              const SizedBox(height: 16),
                            ],
                            // Address section
                            _buildInfoSection('ที่อยู่', [
                              _buildAddressDisplay(),
                            ]),
                            const SizedBox(height: 16),
                            _buildInfoSection('ข้อมูลเพิ่มเติม', [
                              if (_currentCustomer!.source.isNotEmpty)
                                _buildInfoRow('แหล่งที่มา', _currentCustomer!.source),
                              _buildHashtagDisplay(),
                              if (_hasValidAssignees()) _buildAssigneesDisplay(),
                            ]),
                            const SizedBox(height: 16),
                            _buildInfoSection('ข้อมูลระบบ', [
                              _buildInfoRow('สร้างเมื่อ', _formatDate(_currentCustomer!.createdAt)),
                              _buildInfoRow('อัปเดตล่าสุด', _formatDate(_currentCustomer!.updatedAt)),
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarSliverDelegate(
                    TabBar(
                      controller: _tabController,
                      indicatorColor: AppTheme.primaryOrange,
                      labelColor: AppTheme.primaryOrange,
                      unselectedLabelColor: AppTheme.textSecondary,
                      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Prompt'),
                      unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, fontFamily: 'Prompt'),
                      isScrollable: true,
                      indicatorWeight: 3,
                      tabs: [
                        Tab(text: 'Job card (' '$_jobCardCount' ')'),
                        Tab(text: 'สิ่งที่ต้องทำ (' '$_todoCount' ')'),
                        Tab(text: 'ประวัติ ($_historyCount)'),
                        Tab(text: 'คลังเอกสาร ($_documentCount)'),
                        const Tab(text: 'โน๊ต (0)'),
                        const Tab(text: 'เอกสารการขาย (0)'),
                      ],
                    ),
                    // version changes whenever any count changes -> forces rebuild
                    _jobCardCount ^ _todoCount ^ _historyCount ^ _documentCount,
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildJobCardTab(),
                  _buildTodoTab(),
                  _buildHistoryTab(),
                  _buildDocumentTab(),
                  _buildNoteTab(),
                  _buildSalesDocumentTab(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Tab content builders
  Widget _buildJobCardTab() {
    if (_jobCardsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_canViewAnyJobcard()) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.lock_outline, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text('คุณไม่มีสิทธิ์ดู Job Card ของลูกค้ารายนี้',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    final visible = _visibleJobcards(_jobCards);

    if (visible.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_outline,
              size: 48,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'ยังไม่มี Job Card สำหรับลูกค้านี้',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    

    return Container(
      color: AppTheme.backgroundGrey,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: visible.length,
          itemBuilder: (context, index) {
            final jobCard = visible[index];
            return _buildJobCardItem(jobCard);
          },
        ),
      ),
    );
  }
  
  Widget _buildJobCardItem(JobCard jobCard) {
    return InkWell(
      onTap: () {
        final svc = MobilePermissionsService.to;
        final uid = FirebaseAuth.instance.currentUser?.uid;
        final canAll = svc.isOwner || svc.can('jobcard:view:all');
        final canAssigned = svc.can('jobcard:view:assigned') && (uid != null && jobCard.assignedTo == uid);
        if (canAll || canAssigned) {
          Get.toNamed(AppRoutes.editCard, arguments: jobCard);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('คุณไม่มีสิทธิ์เข้าถึง Job Card นี้')),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.backgroundWhite,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    jobCard.customId.isNotEmpty ? jobCard.customId : jobCard.id,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryOrange,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(jobCard.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    jobCard.status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(jobCard.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              jobCard.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (jobCard.assignedTo.isNotEmpty) ...[
                        _buildJobCardDetailRow(
                          Icons.person_outline,
                          'ผู้รับผิดชอบ',
                          _getAssigneeName(jobCard.assignedTo),
                        ),
                        const SizedBox(height: 4),
                      ],
                      if (jobCard.customerInterest?.isNotEmpty == true) ...[
                        _buildJobCardDetailRow(
                          Icons.favorite_outline,
                          'ความสนใจ',
                          jobCard.customerInterest!,
                        ),
                        const SizedBox(height: 4),
                      ],
                      if (jobCard.dueDate != null) ...[
                        _buildJobCardDetailRow(
                          Icons.calendar_today_outlined,
                          'กำหนดส่ง',
                          _formatDate(jobCard.dueDate!),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (jobCard.hashtags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: jobCard.hashtags.map((hashtag) {
                  final hashtagText = hashtag['text'] as String? ?? hashtag['id'] as String? ?? '';
                  final hashtagColor = hashtag['color'] as String? ?? '';
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _parseColor(hashtagColor).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _parseColor(hashtagColor).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      '#$hashtagText',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: _parseColor(hashtagColor),
                      ),
                    )
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildJobCardDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: AppTheme.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'done':
        return Colors.green;
      case 'in progress':
      case 'doing':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      case 'on hold':
        return Colors.orange;
      default:
        return AppTheme.textSecondary;
    }
  }
  
  String _getAssigneeName(String assigneeId) {
    final member = _workspaceMembers.firstWhere(
      (member) => member.uid == assigneeId,
      orElse: () => WorkspaceMember(
        uid: assigneeId,
        email: '',
        displayName: assigneeId, // Fallback to ID if member not found
        permission: 'member',
      ),
    );
    return member.displayName;
  }

  Widget _buildTodoTab() {
    if (_jobCardsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_canViewAnyJobcard()) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.lock_outline, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text('คุณไม่มีสิทธิ์ดู To-Do ของลูกค้ารายนี้',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    // Collect all todos from visible job cards
    final visible = _visibleJobcards(_jobCards);
    final allTodos = <Map<String, dynamic>>[];
    for (final jobCard in visible) {
      for (final todo in jobCard.todos) {
        final todoWithContext = Map<String, dynamic>.from(todo);
        todoWithContext['jobCardId'] = jobCard.id;
        todoWithContext['jobCardTitle'] = jobCard.title;
        todoWithContext['jobCardCustomId'] = jobCard.customId.isNotEmpty ? jobCard.customId : jobCard.id;
        allTodos.add(todoWithContext);
      }
    }

    if (allTodos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.checklist_outlined,
              size: 48,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'ยังไม่มี To-Do สำหรับลูกค้านี้',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: AppTheme.backgroundGrey,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: allTodos.length,
          itemBuilder: (context, index) {
            final todo = allTodos[index];
            return _buildTodoItem(todo);
          },
        ),
      ),
    );
  }
  
  Widget _buildTodoItem(Map<String, dynamic> todo) {
    final isCompleted = todo['completed'] as bool? ?? false;
    final todoTitle = todo['title'] as String? ?? '';
    final dueDate = todo['dueDate'];
    final jobCardTitle = todo['jobCardTitle'] as String? ?? '';
    final jobCardCustomId = todo['jobCardCustomId'] as String? ?? '';
    final jobCardId = todo['jobCardId'] as String? ?? '';
    final todoId = todo['id'] as String? ?? '';
    
    // Parse HTML title to plain text
    String plainTitle = todoTitle;
    try {
      // Simple HTML tag removal - you might want to use a proper HTML parser
      plainTitle = todoTitle.replaceAll(RegExp(r'<[^>]*>'), '').trim();
      if (plainTitle.isEmpty) {
        plainTitle = '-';
      }
    } catch (e) {
      plainTitle = '-';
    }
    
    DateTime? todoDate;
    if (dueDate != null) {
      try {
        if (dueDate is int) {
          todoDate = DateTime.fromMillisecondsSinceEpoch(dueDate);
        }
      } catch (e) {
        // Handle date parsing error
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with completion status and job card info
          Row(
            children: [
              // Completion checkbox
              GestureDetector(
                onTap: () => _updateTodoCompletion(jobCardId, todoId, !isCompleted),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green : Colors.transparent,
                    border: Border.all(
                      color: isCompleted ? Colors.green : AppTheme.textSecondary,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: isCompleted
                      ? const Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Job Card info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'จาก Job Card: $jobCardCustomId',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (jobCardTitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        jobCardTitle,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isCompleted ? 'เสร็จแล้ว' : 'ยังไม่เสร็จ',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isCompleted ? Colors.green : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Todo title
          Text(
            plainTitle,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
              decorationColor: AppTheme.textSecondary,
            ),
          ),
          
          // Due date
          if (todoDate != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  'กำหนดส่ง: ${_formatDate(todoDate)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Container(
      color: AppTheme.backgroundGrey,
      child: RefreshIndicator(
        onRefresh: _loadHistoryData,
        child: _historyLoading && _historyActivities.isEmpty
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _historyActivities.isEmpty
                ? CustomScrollView(
                    slivers: [
                      SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history,
                                size: 64,
                                color: AppTheme.textSecondary.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'ยังไม่มีประวัติการสร้างการ์ด',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'ดึงลงเพื่ออัปเดต',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _historyActivities.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final activity = _historyActivities[index].data() as Map<String, dynamic>;
                      
                      // Handle timestamp that can be either Timestamp or int
                      Timestamp? timestamp;
                      final timestampRaw = activity['timestamp'];
                      if (timestampRaw is Timestamp) {
                        timestamp = timestampRaw;
                      } else if (timestampRaw is int) {
                        timestamp = Timestamp.fromMillisecondsSinceEpoch(timestampRaw);
                      }
                      
                      final details = activity['details'] as Map<String, dynamic>?;
                      final userDisplayName = activity['userDisplayName'] as String? ?? 'ไม่ระบุชื่อ';
                      final cardTitle = details?['cardTitle'] as String? ?? 'ไม่มีชื่อการ์ด';
                      final laneName = details?['laneName'] as String? ?? 'ไม่ระบุโซน';

                      return Card(
                        margin: EdgeInsets.zero,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: AppTheme.primaryOrange.withOpacity(0.1),
                                    child: Icon(
                                      Icons.add_card,
                                      size: 16,
                                      color: AppTheme.primaryOrange,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '$userDisplayName สร้างการ์ดใหม่',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'การ์ด: $cardTitle',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                        Text(
                                          'โซน: $laneName',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (timestamp != null)
                                    Text(
                                      _formatThaiDateTime(timestamp.toDate()),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildDocumentTab() {
    return Container(
      color: AppTheme.backgroundGrey,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search documents...',
                prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.borderGrey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.borderGrey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.primaryOrange),
                ),
              ),
            ),
          ),
          
          // Upload File Button
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            child: ElevatedButton.icon(
              onPressed: _uploadFile,
              icon: const Icon(Icons.cloud_upload_outlined),
              label: const Text('Upload File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          
          // Header Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: AppTheme.borderGrey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('File Name', style: TextStyle(fontWeight: FontWeight.w600))),
                Expanded(flex: 2, child: Text('Job Card', style: TextStyle(fontWeight: FontWeight.w600))),
                Expanded(flex: 2, child: Text('Uploaded By', style: TextStyle(fontWeight: FontWeight.w600))),
                Expanded(flex: 2, child: Text('Uploaded At', style: TextStyle(fontWeight: FontWeight.w600))),
                SizedBox(width: 60, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600))),
              ],
            ),
          ),
          
          // Document List
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _getRelatedDocumentsStream(),
              initialData: const [],
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading documents: ${snapshot.error}',
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }
                
                final documents = snapshot.data ?? [];
                
                if (documents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 48,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No documents found',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    final document = documents[index];
                    return _buildDocumentItem(document);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Upload file functionality
  Future<void> _uploadFile() async {
    // TODO: Implement file upload functionality
    Get.snackbar(
      'Info',
      'File upload feature coming soon',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.primaryOrange,
      colorText: Colors.white,
    );
  }

  // Get stream of related documents from all customer's job cards
  Stream<List<Map<String, dynamic>>> _getRelatedDocumentsStream() {
    final customer = _currentCustomer ?? widget.customer;
    final workspaceId = customer.workspaceId;
    
    // Stream to monitor all cards in the workspace that have this customer
    return FirebaseFirestore.instance
        .collection('workspaces')
        .doc(workspaceId)
        .collection('cards')
        .where('customers', arrayContains: customer.id)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> allDocuments = [];
      
      for (var cardDoc in snapshot.docs) {
        final cardData = cardDoc.data();
        final cardTitle = cardData['title'] ?? 'Untitled Card';
        final relatedDocuments = cardData['relatedDocuments'] as List<dynamic>? ?? [];
        
        for (var docRef in relatedDocuments) {
          final docData = Map<String, dynamic>.from(docRef);
          
          // Fetch detailed document information if needed
          final documentId = docData['id'];
          if (documentId != null) {
            try {
              final docSnapshot = await FirebaseFirestore.instance
                  .collection('workspaces')
                  .doc(workspaceId)
                  .collection('documents')
                  .doc(documentId)
                  .get();
              
              if (docSnapshot.exists) {
                final fullDocData = docSnapshot.data()!;
                allDocuments.add({
                  'id': documentId,
                  'fileName': fullDocData['fileName'] ?? docData['docNo'] ?? 'Unknown File',
                  'jobCard': cardTitle,
                  'cardId': cardDoc.id,
                  'uploadedBy': fullDocData['createdBy'] ?? 'Unknown',
                  'uploadedAt': fullDocData['createdAt'],
                  'type': fullDocData['type'] ?? docData['type'] ?? 'Unknown',
                  'status': fullDocData['status'] ?? 'Active',
                  'downloadUrl': fullDocData['downloadUrl'],
                  ...fullDocData,
                });
              } else {
                // Document not found, show placeholder
                allDocuments.add({
                  'id': documentId,
                  'fileName': docData['docNo'] ?? 'Missing Document',
                  'jobCard': cardTitle,
                  'cardId': cardDoc.id,
                  'uploadedBy': 'Unknown',
                  'uploadedAt': null,
                  'type': docData['type'] ?? 'Unknown',
                  'status': 'NOT_FOUND',
                });
              }
            } catch (e) {
              print('Error loading document $documentId: $e');
            }
          }
        }
      }
      
      // Sort by upload date (newest first)
      allDocuments.sort((a, b) {
        final aDate = a['uploadedAt'];
        final bDate = b['uploadedAt'];
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        
        if (aDate is String && bDate is String) {
          return DateTime.parse(bDate).compareTo(DateTime.parse(aDate));
        }
        return 0;
      });
      
      return allDocuments;
    });
  }

  Widget _buildDocumentItem(Map<String, dynamic> document) {
    final fileName = document['fileName'] ?? 'Unknown File';
    final jobCard = document['jobCard'] ?? 'Unknown Job Card';
    final uploadedBy = document['uploadedBy'] ?? 'Unknown';
    final uploadedAt = document['uploadedAt'];
    final status = document['status'] ?? 'Active';
    
    String formattedDate = 'Unknown Date';
    if (uploadedAt != null) {
      try {
        DateTime date;
        if (uploadedAt is String) {
          date = DateTime.parse(uploadedAt);
        } else if (uploadedAt is Timestamp) {
          date = uploadedAt.toDate();
        } else {
          date = DateTime.now();
        }
        formattedDate = _formatThaiDateTime(date);
      } catch (e) {
        formattedDate = 'Invalid Date';
      }
    }
    
    final isNotFound = status == 'NOT_FOUND';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        color: isNotFound ? Colors.red.withOpacity(0.1) : Colors.white,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderGrey.withOpacity(0.5)),
        ),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Icon(
          isNotFound ? Icons.error_outline : _getFileIcon(fileName),
          color: isNotFound ? Colors.red : AppTheme.primaryOrange,
        ),
        title: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                fileName,
                style: TextStyle(
                  fontSize: 14,
                  color: isNotFound ? Colors.red : AppTheme.textPrimary,
                  decoration: isNotFound ? TextDecoration.lineThrough : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                jobCard,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                uploadedBy,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                formattedDate,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 60,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isNotFound && document['downloadUrl'] != null)
                    IconButton(
                      icon: const Icon(Icons.download, size: 16),
                      onPressed: () => _downloadFile(document),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                    ),
                  if (!isNotFound)
                    IconButton(
                      icon: const Icon(Icons.visibility, size: 16),
                      onPressed: () => _viewDocument(document),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
        return Icons.image;
      case 'zip':
      case 'rar':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }

  Future<void> _downloadFile(Map<String, dynamic> document) async {
    final downloadUrl = document['downloadUrl'];
    if (downloadUrl != null) {
      // TODO: Implement file download
      Get.snackbar(
        'Info',
        'Download functionality coming soon',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.primaryOrange,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _viewDocument(Map<String, dynamic> document) async {
    final cardId = document['cardId'];
    if (cardId != null) {
      // Navigate to job card detail to view document
      Get.toNamed('/job-card-detail', arguments: {'cardId': cardId});
    }
  }

  Widget _buildNoteTab() {
    return Container(
      color: AppTheme.backgroundGrey,
      child: Center(
        child: Text(
          'โน๊ต\n(Coming Soon)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSalesDocumentTab() {
    return Container(
      color: AppTheme.backgroundGrey,
      child: Center(
        child: Text(
          'เอกสารการขาย\n(Coming Soon)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildAddressDisplay() {
    final c = _currentCustomer ?? widget.customer;
    // Build two-line address like the screenshot: first line main parts, second line postal + country
    String joinNonEmpty(List<String> items) {
      final filtered = items.where((e) => e.trim().isNotEmpty).toList();
      return filtered.join(', ');
    }

    final line1 = joinNonEmpty([
      c.address,
      c.subdistrict,
      c.district,
      c.province,
    ]);
    final line2 = joinNonEmpty([
      c.postalCode,
      c.country,
    ]);

    if (line1.isEmpty && line2.isEmpty) {
      return Text(
        'ไม่ระบุ',
        style: const TextStyle(
          fontSize: 14,
          color: AppTheme.textPrimary,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (line1.isNotEmpty)
          Text(
            line1,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
          ),
        if (line2.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            line2,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ],
    );
  }
}

class _TabBarSliverDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final int version; // simple int that changes when counts change
  _TabBarSliverDelegate(this.tabBar, this.version);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppTheme.backgroundWhite,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    if (oldDelegate is _TabBarSliverDelegate) {
      return oldDelegate.version != version || oldDelegate.tabBar != tabBar;
    }
    return true;
  }
}

extension _DateTimeFormatting on _CustomerDetailPageState {
  String _formatThaiDateTime(DateTime dateTime) {
    final thaiMonths = [
      'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];
    
    final day = dateTime.day;
    final month = thaiMonths[dateTime.month - 1];
    final year = dateTime.year + 543; // Convert to Buddhist Era
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    return '$day $month $year เวลา $hour:$minute น.';
  }
}
