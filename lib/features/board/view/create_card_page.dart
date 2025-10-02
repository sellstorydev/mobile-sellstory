import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';

import '../../../domain/entities/job_card.dart';
import '../controller/board_controller.dart';
import '../../../data/services/mobile_permissions_service.dart';
import '../../../data/services/firestore_service.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import '../../../core/widgets/hashtag_input_field.dart';
import '../../../core/services/hashtag_service.dart';
import '../../../core/widgets/customers_input_field.dart' as cif;

class CreateCardPage extends StatefulWidget {
  final String? laneId;
  final String? boardId;
  final String? workspaceId;
  // New: preselect customer when opening from chat
  final String? initialCustomerId;

  const CreateCardPage({
    super.key,
    this.laneId,
    this.boardId,
    this.workspaceId,
    this.initialCustomerId,
  });

  @override
  State<CreateCardPage> createState() => _CreateCardPageState();
}

class _CreateCardPageState extends State<CreateCardPage> {
  final BoardController _controller = Get.find<BoardController>();
  // Permission helpers
  bool get _isOwner => MobilePermissionsService.to.isOwner;
  bool get _canCreateCard =>
      _isOwner || MobilePermissionsService.to.can('jobcard:create');

  // Form controllers
  final TextEditingController _jobIdController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _assigneeController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

  // HTML Editor controller
  final HtmlEditorController _htmlEditorController = HtmlEditorController();
  bool _isHtmlEditorReady = false;

  // Fallback controller for description if HTML editor fails
  final TextEditingController _descriptionFallbackController =
      TextEditingController();

  // Hashtag state
  List<String> _selectedHashtagIds = [];
  List<HashtagOption> _availableHashtags = [];
  final HashtagService _hashtagService = HashtagService();

  // Todo state
  List<Map<String, dynamic>> _todoItems = [];

  // Form state

  String _selectedLane = '';
  List<String> _selectedCustomerIds = [];
  String _selectedCompany = 'none';
  String _selectedCustomerInterest = 'interest_initial'.tr;
  String _selectedStatus = 'Pending';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  // Multi-select for collaborators and watchers
  List<String> _selectedCollaborators = [];
  List<String> _selectedWatchers = [];

  // Available options

  List<Map<String, dynamic>> _availableLanes = [];
  // Customer data is now managed by CustomersController
  List<Map<String, dynamic>> _availableCompanies = [];
  List<Map<String, dynamic>> _availableUsers = [];

  // Status options
  final List<Map<String, dynamic>> _statusOptions = [
    {'value': 'Pending', 'label': 'status_pending'.tr, 'icon': Icons.schedule},
    {'value': 'In Progress', 'label': 'status_in_progress'.tr, 'icon': Icons.schedule},
    {'value': 'Done', 'label': 'status_done'.tr, 'icon': Icons.schedule},
    {'value': 'Cancelled', 'label': 'status_cancelled'.tr, 'icon': Icons.schedule},
  ];

  // Customer Interest options
  final List<String> _customerInterestOptions = [
    'interest_initial'.tr,
    'interest_low'.tr + ' (Low)',
    'interest_medium'.tr + ' (Medium)',
    'interest_high'.tr + ' (High)',
  ];

  @override
  void initState() {
    super.initState();
    print('🔄 CreateCardPage.initState - Page opened');
    print('  - Received laneId: ${widget.laneId}');
    print('  - Received boardId: ${widget.boardId}');
    print('  - Received workspaceId: ${widget.workspaceId}');
    print('  - Received initialCustomerId: ${widget.initialCustomerId}');
    _initializeData().then((_) {
      setState(() {});
    });
    _loadHashtags();
  }

  Future<void> _initializeData() async {
    // If a workspaceId is provided and different from current, switch first
    final targetWsId = widget.workspaceId;
    if (targetWsId != null && targetWsId.isNotEmpty &&
        _controller.currentWorkspaceId.value != targetWsId) {
      try {
        print('🔁 Switching workspace to: $targetWsId before initialization');
        await _controller.switchWorkspace(targetWsId);
        print('✅ Workspace switched to: ${_controller.currentWorkspaceId.value}');
      } catch (e) {
        print('❌ Failed to switch workspace: $e');
      }
    }

    // Set default values
    _titleController.text = 'New Card';
    _assigneeController.text = '';

    // Generate default job ID
    _generateJobId();

    // Load available options
    await _loadAvailableOptions();

    // If initialCustomerId provided, preselect it (after customers are loaded)
    final initCid = widget.initialCustomerId;
    if (initCid != null && initCid.isNotEmpty) {
      // Customer existence is now handled by the controller
      _selectedCustomerIds = [initCid];
      // Also load companies for this customer
      await _loadCompaniesForCustomer(initCid);
    }

    // Set default lane if provided
    if (widget.laneId != null) {
      _selectedLane = widget.laneId!;
      print('✅ Set default lane from parameter: $_selectedLane');
    } else {
      print('⚠️ No laneId parameter provided');
    }
  }

  List<String> get _selectedHashtagTexts {
    return _selectedHashtagIds.map((id) {
      final hashtag = _availableHashtags.firstWhere(
        (h) => h.id == id,
        orElse: () => HashtagOption(
          id: id,
          name: id,
          color: '#6B7280',
          scopes: {},
          totalUsage: 0,
          enabled: true,
        ),
      );
      return hashtag.name;
    }).toList();
  }

  List<Map<String, dynamic>> get _selectedHashtagsAsMap {
    return _selectedHashtagIds.map((id) {
      final hashtag = _availableHashtags.firstWhere(
        (h) => h.id == id,
        orElse: () => HashtagOption(
          id: id,
          name: id,
          color: '#6B7280',
          scopes: {},
          totalUsage: 0,
          enabled: true,
        ),
      );
      return {'id': hashtag.id, 'text': hashtag.name, 'color': hashtag.color};
    }).toList();
  }

  Future<void> _loadHashtags() async {
    try {
      final wsId = widget.workspaceId;
      if (wsId == null || wsId.isEmpty) {
        print('⚠️ Skip loading hashtags: workspaceId is null/empty');
        return;
      }
      final hashtags = await _hashtagService.getHashtagsByScope(
        wsId,
        'jobBoard',
      );
      _availableHashtags = hashtags;
      if (mounted) setState(() {});
      print('✅ Hashtags loaded: ${_availableHashtags.length} hashtags');
    } catch (e) {
      if (mounted) setState(() {});
      print('❌ Failed to load hashtags: $e');
    }
  }


  Future<void> _loadAvailableOptions() async {
    // Load lanes for current board
    final currentBoardId = _controller.currentBoardId.value;
    if (currentBoardId.isNotEmpty) {
      await _loadLanesForBoard(currentBoardId);
    }

    // Load users from current workspace
    await _loadWorkspaceUsers();

    // Customer data is now managed by CustomersController
    print('🔄 Customer data will be loaded by CustomersController...');

    // Companies will be loaded when customer is selected
    _availableCompanies = [
      {'id': 'none', 'name': 'none_option_short'.tr},
    ];
    _selectedCompany = 'none';
  }

  Future<void> _loadLanesForBoard(String boardId) async {
    if (boardId.isEmpty) {
      print('⚠️ No board ID provided for loading lanes');
      _availableLanes = [];
      return;
    }

    try {
      print('🔄 Loading lanes for board: $boardId');
      final lanes = await _controller.getLanesByBoardId(boardId);

      _availableLanes = lanes
          .map((lane) => {'id': lane.id, 'name': lane.title})
          .toList();

      // Update selected lane based on available lanes
      if (widget.laneId != null &&
          _availableLanes.any((lane) => lane['id'] == widget.laneId)) {
        _selectedLane = widget.laneId!;
        print('✅ Kept pre-selected lane: $_selectedLane');
      } else if (_selectedLane.isEmpty && _availableLanes.isNotEmpty) {
        _selectedLane = _availableLanes.first['id'];
        print('✅ Set first lane as default: $_selectedLane');
      } else if (!_availableLanes.any((lane) => lane['id'] == _selectedLane)) {
        _selectedLane = _availableLanes.isNotEmpty
            ? _availableLanes.first['id']
            : '';
        print('✅ Reset to first available lane: $_selectedLane');
      }
    } catch (e) {
      print('❌ Failed to load lanes for board $boardId: $e');
      _availableLanes = [];
    }
  }

  Future<void> _loadWorkspaceUsers() async {
    try {
      final workspaceId = _controller.currentWorkspaceId.value;
      if (workspaceId.isEmpty) {
        print('⚠️ No workspace selected for loading users');
        _availableUsers = [];
        return;
      }

      print('🔄 Loading users for workspace: $workspaceId');

      // Get users from the workspace - data is already properly formatted from repository
      final users = await _controller.getWorkspaceUsers(workspaceId);

      // Deduplicate users by ID to prevent dropdown issues and ensure data consistency
      final userMap = <String, Map<String, dynamic>>{};
      for (final user in users) {
        final userId = user['id']?.toString();
        if (userId != null &&
            userId.isNotEmpty &&
            !userMap.containsKey(userId)) {
          // Ensure user has required fields
          userMap[userId] = {
            'id': userId,
            'name': user['name'] ?? user['displayName'] ?? 'Unknown User',
            'displayName':
                user['displayName'] ?? user['name'] ?? 'Unknown User',
            'email': user['email'] ?? '',
          };
        }
      }
      _availableUsers = userMap.values.toList();

      // Clear invalid assignee if current assignee is not in available users
      if (_assigneeController.text.isNotEmpty &&
          !_availableUsers.any(
            (user) => user['id'] == _assigneeController.text,
          )) {
        _assigneeController.text = '';
      }

      print('✅ Loaded ${_availableUsers.length} users for workspace');
    } catch (e) {
      print('❌ Failed to load workspace users: $e');
      _availableUsers = [];
      // Clear assignee on error
      _assigneeController.text = '';
    }
  }

  Future<void> _loadCompaniesForCustomer(String customerId) async {
    try {
      print('🔄 Loading companies for customer: $customerId');

      // Get customer details to access companyNames
      final customers = await _controller.getCustomers();
      final customer = customers.firstWhereOrNull((c) => c.id == customerId);

      if (customer != null && customer.companyNames.isNotEmpty) {
  final companyMap = <String, Map<String, dynamic>>{};
  companyMap['none'] = {'id': 'none', 'name': 'none_option_short'.tr};

        for (final company in customer.companyNames) {
          companyMap[company['id']] = {
            'id': company['id'],
            'name': company['value'], // ใช้ value แทน label เพื่อแสดงชื่อสั้นๆ
            'value': company['value'],
          };
        }

        if (mounted) {
          setState(() {
            _availableCompanies = companyMap.values.toList();
            _selectedCompany = 'none';
          });
        }

        print(
          '✅ Companies loaded for customer: ${_availableCompanies.length - 1} companies',
        );
      } else {
        if (mounted) {
          setState(() {
            _availableCompanies = [
              {'id': 'none', 'name': 'none_option_short'.tr},
            ];
            _selectedCompany = 'none';
          });
        }
        print('⚠️ No companies found for customer');
      }
    } catch (e) {
      print('❌ Failed to load companies for customer: $e');
      if (mounted) {
        setState(() {
          _availableCompanies = [
            {'id': 'none', 'name': 'none_option_short'.tr},
          ];
          _selectedCompany = 'none';
        });
      }
    }
  }

  String? _getValidAssigneeValue() {
    if (_assigneeController.text.isEmpty) return null;

    // Check if the current assignee value exists in available users
    final isValidAssignee = _availableUsers.any(
      (user) => user['id'] == _assigneeController.text,
    );
    if (!isValidAssignee) {
      // Clear invalid assignee
      _assigneeController.text = '';
      return null;
    }

    return _assigneeController.text;
  }

  

  String? _getValidCompanyValue() {
    if (_selectedCompany.isEmpty) return null;

    // Check if the current company value exists in available companies
    final isValidCompany = _availableCompanies.any(
      (company) => company['id'] == _selectedCompany,
    );
    if (!isValidCompany) {
      // Clear invalid company
      _selectedCompany = 'none';
      return null;
    }

    return _selectedCompany;
  }

  Future<void> _showTodoTemplates() async {
    try {
      final currentBoardId = _controller.currentBoardId.value;
      final currentWorkspaceId = _controller.currentWorkspaceId.value;
      if (currentBoardId.isEmpty || currentWorkspaceId.isEmpty) {
        _showError('no_board_or_workspace_selected'.tr);
        return;
      }

      // Get todo templates from Firestore directly
      final firestoreService = Get.find<FirestoreService>();
      final boardsCollection = firestoreService.getWorkspaceBoardsCollection(
        currentWorkspaceId,
      );
      final boardDocRef = boardsCollection.doc(currentBoardId);
      final boardData = await firestoreService.getDocument(boardDocRef);

      if (boardData == null ||
          boardData['todoTemplates'] == null ||
          (boardData['todoTemplates'] as List).isEmpty) {
        _showError('no_todo_templates_for_board'.tr);
        return;
      }

      final todoTemplates = boardData['todoTemplates'] as List;

      // Show template selection dialog
      final selectedTemplate = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('select_todo_template'.tr),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: todoTemplates.length,
              itemBuilder: (context, index) {
                final template = todoTemplates[index];
                return ListTile(
                  title: Text(template['name'] ?? 'unnamed_template'.tr),
                  onTap: () => Navigator.of(context).pop(template),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('cancel'.tr),
            ),
          ],
        ),
      );

      if (selectedTemplate != null && selectedTemplate['todos'] != null) {
        // Apply the selected template
        final todos = selectedTemplate['todos'] as List;
        setState(() {
          for (final todo in todos) {
            // Calculate due date from dueInDays
            DateTime? calculatedDueDate;
            if (todo['dueInDays'] != null && todo['dueInDays'] is int) {
              final now = DateTime.now();
              // Set time to 00:00:00 and add the specified days
              calculatedDueDate = DateTime(
                now.year,
                now.month,
                now.day,
              ).add(Duration(days: todo['dueInDays'] as int));
            }

            _todoItems.add({
              'id': DateTime.now().millisecondsSinceEpoch.toString(),
              'text': todo['title'] ?? '',
              'isCompleted': false,
              'dueDate': calculatedDueDate,
              'duration': null,
              'endTime': null,
              'controller': TextEditingController(text: todo['title'] ?? ''),
            });
          }
        });

        Get.snackbar(
          'success'.tr,
          'todo_template_applied_success'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      print('❌ Error showing todo templates: $e');
      _showError('failed_to_load_todo_templates'.trParams({'error': e.toString()}));
    }
  }

  void _generateJobId() {
    // Job ID will be auto-generated by the server with proper counter
  }

  @override
  void dispose() {
    print('🔄 CreateCardPage.dispose - Page being disposed');

    // Dispose todo controllers
    for (var todo in _todoItems) {
      todo['controller']?.dispose();
    }

    // Skip HTML editor disposal to prevent JavaScript evaluation errors
    // The HTML editor will be automatically disposed when the widget tree is destroyed
    print(
      '⚠️ Skipping HTML editor disposal to prevent JavaScript evaluation errors',
    );

    _jobIdController.dispose();
    _titleController.dispose();
    _assigneeController.dispose();
    _detailsController.dispose();
    _descriptionFallbackController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        // Ensure end date is not before start date
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _saveCard() async {
    if (!(MobilePermissionsService.to.isOwner ||
        MobilePermissionsService.to.can('jobcard:create'))) {
      _showError('no_create_permission'.tr);
      return;
    }
    // Validate required fields
    if (_titleController.text.trim().isEmpty) {
      _showError('card_title_required'.tr);
      return;
    }

    if (_assigneeController.text.trim().isEmpty) {
      _showError('assignee_required'.tr);
      return;
    }

    if (_selectedCustomerIds.isEmpty) {
      _showError('customer_required'.tr);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create the card with full data structure mapped to DTB.md
      final currentUserId = _controller.currentUserId.value.isNotEmpty
          ? _controller.currentUserId.value
          : 'mobile-user';
      final currentWorkspaceId =
          widget.workspaceId ?? _controller.currentWorkspaceId.value;
      final currentBoardId = _controller.currentBoardId.value;

      // Get selected assignee details
      String assigneeId = '';
      String assigneeDisplayName = '';
      if (_assigneeController.text.trim().isNotEmpty) {
        final selectedUser = _availableUsers.firstWhereOrNull(
          (user) => user['id'] == _assigneeController.text.trim(),
        );
        assigneeId = selectedUser?['id'] ?? _assigneeController.text.trim();
        assigneeDisplayName =
            selectedUser?['displayName'] ??
            selectedUser?['name'] ??
            _assigneeController.text.trim();
      }

      // Get customer name if selected
      String customerName = '';
      if (_selectedCustomerIds.isNotEmpty) {
        // Customer lookup is now handled by the controller
        final selectedCustomer = null; // Controller handles customer data
        customerName = selectedCustomer?.displayName ?? '';
      }

      // Prepare company data in correct format
      Map<String, dynamic>? companyData;
      if (_selectedCompany != 'none') {
        final selectedCompany = _availableCompanies.firstWhereOrNull(
          (c) => c['id'] == _selectedCompany,
        );
        if (selectedCompany != null) {
          companyData = {
            'id': selectedCompany['id'],
            'label': selectedCompany['name'],
            'value': selectedCompany['value'] ?? selectedCompany['name'],
          };
        }
      }

      // Prepare todos data in correct format
      final todosData = _todoItems
          .map((todo) {
            final String html = (todo['html'] ?? '').toString();
            final String text = (todo['text'] ?? '').toString();
            final String finalHtml = html.isNotEmpty
                ? html
                : '<p><span style="color: rgb(2, 8, 23); font-size: 24px;"><strong><em>$text</em></strong></span></p>';
            return {
              'id': 'todo-${todo['id']}', // Add 'todo-' prefix to match correct structure
              'title': finalHtml, // HTML content
              'completed': todo['isCompleted'] ?? false,
              'dueDate': todo['dueDate']?.millisecondsSinceEpoch,
              'mentions': [],
            };
          })
          .toList();

      // Format description as HTML from HTML editor with webview disposal protection
      String htmlDescription = '';
      try {
        print('🔍 HTML Editor Save Debug (Create):');
        print('  - _isHtmlEditorReady: $_isHtmlEditorReady');
        print(
          '  - Fallback controller text: "${_descriptionFallbackController.text}"',
        );



        // Check if we're in the middle of disposal
        if (!mounted) {
          print('⚠️ Widget not mounted, skipping HTML editor access');
          htmlDescription = _descriptionFallbackController.text;
        } else if (_isHtmlEditorReady) {
          // Add additional safety check before getText()
          try {
            // Add timeout to prevent indefinite waiting
            final textFuture = _htmlEditorController.getText();
            final editorContent = await textFuture.timeout(
              const Duration(seconds: 3),
              onTimeout: () {
                print('⚠️ HTML editor getText timeout, using fallback');
                return _descriptionFallbackController.text;
              },
            );

            print('  - HTML editor getText() result: "$editorContent"');
            if (editorContent.isNotEmpty) {
              htmlDescription = editorContent;
              print(
                '✅ Successfully retrieved HTML editor content: ${htmlDescription.length} chars',
              );
            } else {
              print('⚠️ HTML editor returned empty content, using fallback');
              htmlDescription = _descriptionFallbackController.text;
            }
          } catch (innerE) {
            print('⚠️ Inner error during getText(): $innerE');
            htmlDescription = _descriptionFallbackController.text;
          }
        } else {
          print('⚠️ HTML editor not ready, using fallback controller');
          htmlDescription = _descriptionFallbackController.text;
        }

        print('  - Final htmlDescription: "$htmlDescription"');
      } catch (e) {
        print('⚠️ Error getting HTML editor content: $e');

        // Always use fallback for any error
        htmlDescription = _descriptionFallbackController.text;

        // For specific MissingPluginException, show more informative error
        if (e.toString().contains('MissingPluginException') ||
            e.toString().contains('evaluateJavascript')) {
          print('⚠️ WebView plugin error detected - using fallback content');

          if (htmlDescription.isEmpty) {
            // Show warning that description wasn't saved
            if (!_isHtmlEditorReady) {
              _showHtmlEditorWarningDialog();
            }
          }
        }
      }

      final card = JobCard(
        id: '', // Will be generated by Firestore
        title: _titleController.text.trim(),
        description: htmlDescription, // Use HTML formatted description
        assignedTo: assigneeId,
        status: _selectedStatus,
        customId: '', // Will be auto-generated with counter
        dueDate: null, // Not using dueDate anymore
        startDate: _startDate,
        endDate: _endDate,
        badges: _selectedHashtagTexts,
        amount: 0.0,
        laneId: _selectedLane.isNotEmpty ? _selectedLane : '',
        boardId: currentBoardId,
        workspaceId: currentWorkspaceId,
        order: 0, // Will be set by the system
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        customer: customerName,
        updatedByDisplayName: assigneeDisplayName, // Use assignee display name
        customerId: _selectedCustomerIds.isNotEmpty
            ? _selectedCustomerIds.first
            : null,
        company: companyData, // Store company as object with id, label, value
        customerInterest: _selectedCustomerInterest,
        hashtag: _selectedHashtagTexts.isNotEmpty
            ? _selectedHashtagTexts.map((text) => '#$text').join(' ')
            : null,
        hashtags: _selectedHashtagsAsMap,
        expenses: [],
        todos: todosData,
        notes: [],
        collaborators: _selectedCollaborators,
        watchers: _selectedWatchers.isNotEmpty
            ? _selectedWatchers
            : [currentUserId], // Add creator as watcher if none selected
        customFields: [],
        createdBy: currentUserId,
        updatedBy: currentUserId,
      );

      // Add card using controller with full card data
      print('🔄 CreateCardPage._saveCard - Creating card...');
      print('  - Title: "${card.title}"');
      print('  - Assignee ID: "${card.assignedTo}"');
      print('  - UpdatedByDisplayName: "${card.updatedByDisplayName}"');
      print('  - Current User ID: "$currentUserId"');
      print('  - Selected Watchers: $_selectedWatchers');
      print('  - Card Watchers: ${card.watchers}');
      print('  - Selected Collaborators: $_selectedCollaborators');
      print('  - Card Collaborators: ${card.collaborators}');
      print('  - Available Users Count: ${_availableUsers.length}');
      if (_availableUsers.isNotEmpty) {
        print('  - First User Example: ${_availableUsers.first}');
      }
      final cardId = await _controller.createCard(card);

      print('✅ Card created successfully with ID: $cardId');

      // Reset loading state before navigation
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Navigate back immediately after success WITH RESULT
        Navigator.of(context).pop(cardId);
        print('✅ CreateCardPage._saveCard - Navigation completed');

        // Show warning dialog if HTML editor was unavailable
        if (!_isHtmlEditorReady) {
          _showHtmlEditorWarningDialog();
        }
      } else {
        print(
          '⚠️ CreateCardPage._saveCard - Widget not mounted, cannot navigate',
        );
      }
    } catch (e) {
      print('❌ CreateCardPage._saveCard - Error: $e');

      // Only show error and keep page open if there's an error
      if (mounted) {
  _showError('failed_to_create_card'.trParams({'error': e.toString()}));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    Get.snackbar(
      'error'.tr,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  void _showHtmlEditorWarningDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.orange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(
                'warning'.tr,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Text(
            'description_unavailable'.tr,
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'ok'.tr,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Page-level permission gate
    if (!_canCreateCard) {
      return Scaffold(
        appBar: AppBar(
          title: Text('create_job_card'.tr),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'no_create_permission'.tr,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                'need_jobcard_create_permission'.tr,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text('close'.tr),
              ),
            ],
          ),
        ),
      );
    }
    return PopScope(
      canPop: _isHtmlEditorReady,
      onPopInvoked: (didPop) {
        if (!didPop && !_isHtmlEditorReady) {
          // Show message to user that they need to wait
          // Get.snackbar(
          //   'Please Wait',
          //   'HTML editor is still loading. Please wait a moment before going back.',
          //   backgroundColor: Colors.orange,
          //   colorText: Colors.white,
          //   duration: const Duration(seconds: 2),
          // );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('create_job_card'.tr),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          actions: [
            // Action menu
            // PopupMenuButton<String>(
            //   onSelected: (value) {
            //     // Add watcher functionality will be implemented later
            //   },
            //   itemBuilder: (context) => [
            //     PopupMenuItem<String>(
            //       value: 'add_watcher',
            //       child: Row(
            //         children: [
            //           const Icon(Icons.visibility_outlined, size: 20),
            //           const SizedBox(width: 12),
            //           const Text('Add a watcher'),
            //         ],
            //       ),
            //     ),
            //   ],
            //   child: const Padding(
            //     padding: EdgeInsets.all(8.0),
            //     child: Icon(Icons.more_vert),
            //   ),
            // ),
            // // Close button
            IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryOrange,
                  ),
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Basic Information Section
                          _buildSectionCard(
                            title: 'card_information'.tr,
                            icon: Icons.info_outline,
                            color: Colors.blue,
                            children: [
                              _buildJobIdSection(),
                              const SizedBox(height: 20),
                              _buildTitleSection(),
                              const SizedBox(height: 20),
                              _buildLaneSection(),
                              const SizedBox(height: 20),
                              _buildExpectedClosingDateSection(),
                              const SizedBox(height: 20),
                              _buildAssigneeSection(),
                              const SizedBox(height: 20),
                              _buildCustomerSection(),
                              const SizedBox(height: 20),
                              _buildCompanySection(),
                              const SizedBox(height: 20),
                              _buildCustomerInterestSection(),
                              const SizedBox(height: 20),
                              _buildHashtagSection(),
                              const SizedBox(height: 20),
                              _buildCollaboratorsSection(),
                              const SizedBox(height: 20),
                              _buildWatchersSection(),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Timeline & Status Section
                          _buildSectionCard(
                            title: 'status'.tr,
                            icon: Icons.schedule,
                            color: Colors.orange,
                            children: [_buildStatusSection()],
                          ),
                          const SizedBox(height: 24),
                          // Content Section
                          _buildSectionCard(
                            title: 'description_label'.tr,
                            icon: Icons.edit_document,
                            color: Colors.lightGreen,
                            children: [
                              _buildDetailsSection(),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildSectionCard(
                            title: 'to_do_list'.tr,
                            icon: Icons.edit_document,
                            color: Colors.indigo,
                            children: [
                              _buildTodoListSection(),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  _buildActionButtons(),
                ],
              ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobIdSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'job_id'.tr,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _jobIdController,
          enabled: false, // Disable the field
          decoration: InputDecoration(
            hintText: 'auto_generated'.tr,
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            fillColor: Color(
              0xFFF5F5F5,
            ), // Light gray background for disabled state
            filled: true,
          ),
        ),
      ],
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'card_title_label'.tr,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildLaneSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'lane_label'.tr,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value:
              _selectedLane.isNotEmpty &&
                  _availableLanes.any((lane) => lane['id'] == _selectedLane)
              ? _selectedLane
              : null,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          isExpanded: true,
          items: _availableLanes.map((lane) {
            return DropdownMenuItem<String>(
              value: lane['id'],
              child: Text(
                lane['name'],
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedLane = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildHashtagSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.tag, size: 18, color: Colors.purple[700]),
            const SizedBox(width: 6),
            Text(
              'hashtags_label'.tr,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        HashtagInputField(
          selectedHashtags: _selectedHashtagIds,
          availableHashtags: _availableHashtags,
          onHashtagsChanged: (selectedHashtagIds) {
            setState(() {
              _selectedHashtagIds = selectedHashtagIds;
            });
          },
          label: 'hashtags_label'.tr,
          hintText: 'hashtags_hint'.tr,
          workspaceId: widget.workspaceId,
        ),
      ],
    );
  }

  Widget _buildAssigneeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'assignee_label'.tr + ' *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _getValidAssigneeValue(),
          decoration: InputDecoration(
            hintText: 'assignee_hint'.tr,
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          isExpanded: true,
          items: _availableUsers.map((user) {
            return DropdownMenuItem<String>(
              value: user['id'],
              child: Text(
                user['name'] ??
                    user['displayName'] ??
                    user['id'] ??
                    'Unknown User',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _assigneeController.text = value ?? '';
            });
          },
        ),
      ],
    );
  }

  Widget _buildCustomerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'customer_label'.tr + ' *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        cif.CustomersInputField(
          selectedCustomerIds: _selectedCustomerIds,
          onCustomersChanged: (List<String> selectedIds) {
            setState(() {
              _selectedCustomerIds = selectedIds;
              _selectedCompany = 'none'; // Reset company selection
            });
            // Load companies for selected customer
            if (selectedIds.isNotEmpty) {
              _loadCompaniesForCustomer(selectedIds.first);
            }
          },
          label: 'customer_label'.tr,
          hintText: 'select_customer'.tr,
          allowMultipleSelection: false,
          showBorder: false,
        ),
      ],
    );
  }

  Widget _buildCompanySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'company_label'.tr,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _getValidCompanyValue(),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                isExpanded: true,
                items: _availableCompanies.map((company) {
                  return DropdownMenuItem<String>(
                    value: company['id'],
                    child: Text(
                      company['name'],
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCompany = value!;
                  });
                },
              ),
            ),
            // const SizedBox(width: 8),
            // ElevatedButton.icon(
            //   onPressed: () {
            //     // New company functionality will be implemented later
            //   },
            //   icon: const Icon(Icons.add, size: 16),
            //   label: const Text('New'),
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: AppTheme.primaryOrange,
            //     foregroundColor: Colors.white,
            //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(6),
            //     ),
            //   ),
            // ),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomerInterestSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'customer_interest_label'.tr,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedCustomerInterest,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          isExpanded: true,
          items: _customerInterestOptions.map((interest) {
            return DropdownMenuItem<String>(
              value: interest,
              child: Text(interest),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCustomerInterest = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildExpectedClosingDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.date_range, size: 18, color: Colors.teal[700]),
            const SizedBox(width: 6),
            Text(
              'expected_closing_date_label'.tr,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[50],
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectStartDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _startDate != null
                            ? Colors.teal[300]!
                            : Colors.grey[300]!,
                      ),
                      borderRadius: BorderRadius.circular(6),
                      color: _startDate != null
                          ? Colors.teal[50]
                          : Colors.white,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.today,
                              size: 16,
                              color: _startDate != null
                                  ? Colors.teal[700]
                                  : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'start_date_type'.tr,
                              style: TextStyle(
                                fontSize: 12,
                                color: _startDate != null
                                    ? Colors.teal[700]
                                    : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _startDate != null
                              ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                              : 'select_start_date'.tr,
                          style: TextStyle(
                            fontSize: 14,
                            color: _startDate != null
                                ? Colors.black87
                                : Colors.grey[500],
                            fontWeight: _startDate != null
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => _selectEndDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _endDate != null
                            ? Colors.teal[300]!
                            : Colors.grey[300]!,
                      ),
                      borderRadius: BorderRadius.circular(6),
                      color: _endDate != null ? Colors.teal[50] : Colors.white,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.event,
                              size: 16,
                              color: _endDate != null
                                  ? Colors.teal[700]
                                  : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'end_date_type'.tr,
                              style: TextStyle(
                                fontSize: 12,
                                color: _endDate != null
                                    ? Colors.teal[700]
                                    : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _endDate != null
                              ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                              : 'select_end_date'.tr,
                          style: TextStyle(
                            fontSize: 14,
                            color: _endDate != null
                                ? Colors.black87
                                : Colors.grey[500],
                            fontWeight: _endDate != null
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[50],
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: _statusOptions.map((status) {
          final isSelected = _selectedStatus == status['value'];
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryOrange.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedStatus = status['value'];
                });
              },
              icon: Icon(status['icon'], size: 16),
              label: Text(
                status['label'],
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected
                    ? AppTheme.primaryOrange
                    : Colors.white,
                foregroundColor: isSelected ? Colors.white : Colors.black87,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: BorderSide(
                    color: isSelected
                        ? AppTheme.primaryOrange
                        : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                elevation: isSelected ? 2 : 0,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCollaboratorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.people, size: 18, color: Colors.blue[700]),
            const SizedBox(width: 6),
            Text(
              'collaborators_label'.tr,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[50],
          ),
          child: Column(
            children: [
              // Selected collaborators section
              if (_selectedCollaborators.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${'selected'.tr} (${_selectedCollaborators.length})',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _selectedCollaborators.map((userId) {
                          final user = _availableUsers.firstWhereOrNull(
                            (u) => u['id'] == userId,
                          );
                          final displayName =
                              user?['displayName'] ?? user?['name'] ?? userId;
                          return Chip(
                            label: Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            backgroundColor: Colors.blue[100],
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                _selectedCollaborators.remove(userId);
                              });
                            },
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: Colors.grey[300]),
              ],

              // Available collaborators section
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person_add,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'available_to_add'.tr,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _availableUsers
                            .where(
                              (user) =>
                                  !_selectedCollaborators.contains(user['id']),
                            )
                            .isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'all_users_selected'.tr,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: _availableUsers
                                .where(
                                  (user) => !_selectedCollaborators.contains(
                                    user['id'],
                                  ),
                                )
                                .map((user) {
                                  final displayName =
                                      user['displayName'] ??
                                      user['name'] ??
                                      user['id'];
                                  return FilterChip(
                                    label: Text(
                                      displayName,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    selected: false,
                                    backgroundColor: Colors.white,
                                    selectedColor: Colors.blue[100],
                                    checkmarkColor: Colors.blue[700],
                                    onSelected: (selected) {
                                      if (selected &&
                                          !_selectedCollaborators.contains(
                                            user['id'],
                                          )) {
                                        setState(() {
                                          _selectedCollaborators.add(
                                            user['id'],
                                          );
                                        });
                                      }
                                    },
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  );
                                })
                                .toList(),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWatchersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.visibility, size: 18, color: Colors.green[700]),
            const SizedBox(width: 6),
            Text(
              'watchers_label'.tr,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[50],
          ),
          child: Column(
            children: [
              // Selected watchers section
              if (_selectedWatchers.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${'selected'.tr} (${_selectedWatchers.length})',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _selectedWatchers.map((userId) {
                          final user = _availableUsers.firstWhereOrNull(
                            (u) => u['id'] == userId,
                          );
                          final displayName =
                              user?['displayName'] ?? user?['name'] ?? userId;
                          return Chip(
                            label: Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            backgroundColor: Colors.green[100],
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                _selectedWatchers.remove(userId);
                              });
                            },
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: Colors.grey[300]),
              ],

              // Available watchers section
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person_add,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'available_to_add'.tr,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _availableUsers
                            .where(
                              (user) => !_selectedWatchers.contains(user['id']),
                            )
                            .isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'all_users_selected'.tr,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: _availableUsers
                                .where(
                                  (user) => !_selectedWatchers.contains(user['id']),
                                )
                                .map((user) {
                                  final displayName =
                                      user['displayName'] ??
                                      user['name'] ??
                                      user['id'];
                                  return FilterChip(
                                    label: Text(
                                      displayName,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    selected: false,
                                    backgroundColor: Colors.white,
                                    selectedColor: Colors.green[100],
                                    checkmarkColor: Colors.green[700],
                                    onSelected: (selected) {
                                      if (selected &&
                                          !_selectedWatchers.contains(
                                            user['id'],
                                          )) {
                                        setState(() {
                                          _selectedWatchers.add(user['id']);
                                        });
                                      }
                                    },
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  );
                                })
                                .toList(),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'description_label'.tr,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: HtmlEditor(
            controller: _htmlEditorController,
            htmlEditorOptions: HtmlEditorOptions(
              hint: 'enter_description_hint'.tr,
              shouldEnsureVisible: false,
              initialText: '',
              characterLimit: 10000,
            ),
            htmlToolbarOptions: const HtmlToolbarOptions(
              toolbarPosition: ToolbarPosition.aboveEditor,
              toolbarType: ToolbarType.nativeScrollable,
              defaultToolbarButtons: [
                StyleButtons(style: false),
                FontSettingButtons(
                  fontName: false,
                  fontSize: false,
                  fontSizeUnit: false,
                ),
                FontButtons(
                  bold: true,
                  italic: true,
                  underline: true,
                  clearAll: false,
                  strikethrough: false,
                  superscript: false,
                  subscript: false,
                ),
                ColorButtons(foregroundColor: false, highlightColor: false),
                ListButtons(ul: true, ol: true, listStyles: false),
                ParagraphButtons(
                  textDirection: false,
                  lineHeight: false,
                  caseConverter: false,
                ),
                InsertButtons(
                  link: false,
                  picture: false,
                  audio: false,
                  video: false,
                  hr: false,
                  table: false,
                ),
                OtherButtons(
                  fullscreen: false,
                  codeview: false,
                  undo: true,
                  redo: true,
                  help: false,
                ),
              ],
            ),
            otherOptions: const OtherOptions(height: 150),
            callbacks: Callbacks(
              onInit: () {
                print('🔄 HTML editor initialized successfully');
                setState(() {
                  _isHtmlEditorReady = true;
                });
              },
              onChangeContent: (String? changed) {
                // Sync HTML editor content to fallback controller for error handling
                if (changed != null && mounted) {
                  _descriptionFallbackController.text = changed;
                  print(
                    '🔄 Synced HTML content to fallback: ${changed.length} chars',
                  );
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodoListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'to_do_list'.tr,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _showTodoTemplates,
              icon: const Icon(Icons.description, size: 16),
              label: Text('apply_template'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _addTodoItem,
              icon: const Icon(Icons.add, size: 16),
              label: Text('add_item'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Todo items list
        if (_todoItems.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                'no_todo_items_yet'.tr,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          Column(
            children: _todoItems.asMap().entries.map((entry) {
              final index = entry.key;
              final todo = entry.value;
              return _buildTodoItem(index, todo);
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final bool canSave =
        !_isLoading &&
        (MobilePermissionsService.to.isOwner ||
            MobilePermissionsService.to.can('jobcard:create'));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : () => Get.back(),
                icon: const Icon(Icons.close, size: 18),
                label: Text('cancel'.tr),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  side: BorderSide(color: Colors.grey[300]!),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: ElevatedButton.icon(
                onPressed: canSave ? _saveCard : null,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.save, size: 18),
                label: Text(
                  _isLoading ? 'saving_progress'.tr : 'save_card'.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: canSave
                      ? AppTheme.primaryOrange
                      : Colors.grey[400],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: canSave ? 2 : 0,
                  shadowColor: AppTheme.primaryOrange.withOpacity(0.3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Todo methods
  void _addTodoItem() {
    setState(() {
      _todoItems.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'text': '',
        'html': '',
        'isCompleted': false,
        'dueDate': null,
        'duration': null,
        'endTime': null,
        'controller': TextEditingController(), // fallback text controller
        'htmlController': HtmlEditorController(),
      });
    });
  }

  void _removeTodoItem(int index) {
    setState(() {
      // Dispose controller to prevent memory leaks
      _todoItems[index]['controller']?.dispose();
      _todoItems.removeAt(index);
    });
  }

  void _setTodoTime(int index) async {
    if (!mounted) return;

    // Show options dialog first
    final String? timeOption = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('set_todo_time'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Current time status
            if (_todoItems[index]['dueDate'] != null ||
                _todoItems[index]['endTime'] != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${'current'.tr}: ${_getCurrentTimeType(index)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getCurrentTimeValue(index),
                      style: TextStyle(fontSize: 12, color: Colors.blue[600]),
                    ),
                  ],
                ),
              ),

            // Time options
            ListTile(
              leading: Icon(
                Icons.today,
                color: _todoItems[index]['dueDate'] != null
                    ? Colors.green
                    : Colors.blue,
              ),
              title: Text(
                'due_date_time'.tr,
                style: TextStyle(
                  fontWeight: _todoItems[index]['dueDate'] != null
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
              subtitle: _todoItems[index]['dueDate'] != null
                  ? Text(
                      'currently_set'.tr,
                      style: TextStyle(color: Colors.green[700]),
                    )
                  : null,
              onTap: () => Navigator.of(context).pop('datetime'),
            ),
            ListTile(
              leading: Icon(
                Icons.schedule,
                color: _todoItems[index]['endTime'] != null
                    ? Colors.green
                    : Colors.green,
              ),
              title: Text(
                'set_duration'.tr,
                style: TextStyle(
                  fontWeight: _todoItems[index]['endTime'] != null
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
              subtitle: _todoItems[index]['endTime'] != null
                  ? Text(
                      'currently_set'.tr,
                      style: TextStyle(color: Colors.green[700]),
                    )
                  : null,
              onTap: () => Navigator.of(context).pop('duration'),
            ),
            if (_todoItems[index]['dueDate'] != null ||
                _todoItems[index]['endTime'] != null)
              const Divider(),
            if (_todoItems[index]['dueDate'] != null ||
                _todoItems[index]['endTime'] != null)
              ListTile(
                leading: const Icon(Icons.clear, color: Colors.red),
                title: Text('clear_all_times'.tr),
                onTap: () => Navigator.of(context).pop('clear'),
              ),
          ],
        ),
      ));


    if (timeOption != null && mounted) {
      switch (timeOption) {
        case 'datetime':
          _clearAllTimes(index); // Clear existing times first
          await _setDueDateTime(index);
          break;
        case 'duration':
          _clearAllTimes(index); // Clear existing times first
          await _setDuration(index);
          break;
        case 'clear':
          _clearAllTimes(index);
          break;
      }
    }
  }

  Future<void> _setDueDateTime(int index) async {
    if (!mounted) return;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _todoItems[index]['dueDate'] ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: _todoItems[index]['dueDate'] != null
            ? TimeOfDay.fromDateTime(_todoItems[index]['dueDate'])
            : TimeOfDay.now(),
      );

      if (pickedTime != null && mounted) {
        setState(() {
          _todoItems[index]['dueDate'] = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _setDuration(int index) async {
    if (!mounted) return;

    // Calculate end time based on current time + duration
    final DateTime now = DateTime.now();
    final int? currentDuration = _todoItems[index]['duration'];
    final DateTime? endTime = currentDuration != null
        ? now.add(Duration(minutes: currentDuration))
        : null;

    final TextEditingController durationController = TextEditingController(
      text: currentDuration?.toString() ?? '',
    );

    final int? duration = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
  title: Text('set_duration'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (endTime != null)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.green[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${'end_time'.tr}: ${_formatDateTime(endTime)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            TextField(
              controller: durationController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'duration_minutes'.tr,
                hintText: 'enter_duration_minutes'.tr,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${'quick_select'.tr}:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildDurationChip('15 ${'minutes_short'.tr}', 15, durationController, now),
                _buildDurationChip('30 ${'minutes_short'.tr}', 30, durationController, now),
                _buildDurationChip('1 ${'hour'.tr}', 60, durationController, now),
                _buildDurationChip('2 ${'hours'.tr}', 120, durationController, now),
                _buildDurationChip('4 ${'hours'.tr}', 240, durationController, now),
                _buildDurationChip('8 ${'hours'.tr}', 480, durationController, now),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(durationController.text);
              Navigator.of(context).pop(value);
            },
            child: Text('set'.tr),
          ),
        ],
      ),
    );

    durationController.dispose();

    if (duration != null && mounted) {
      setState(() {
        _todoItems[index]['duration'] = duration;
        // Calculate and store the end time
        _todoItems[index]['endTime'] = now.add(Duration(minutes: duration));
      });
    }
  }

  Widget _buildDurationChip(
    String label,
    int minutes,
    TextEditingController controller,
    DateTime now,
  ) {
    final DateTime endTime = now.add(Duration(minutes: minutes));
    return ActionChip(
      label: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          Text(
            '→ ${_formatDateTime(endTime)}',
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
      onPressed: () {
        controller.text = minutes.toString();
      },
      backgroundColor: Colors.blue[50],
      labelStyle: TextStyle(color: Colors.blue[700]),
    );
  }

  void _clearAllTimes(int index) {
    setState(() {
      _todoItems[index]['dueDate'] = null;
      _todoItems[index]['duration'] = null;
      _todoItems[index]['endTime'] = null;
    });
  }

  String _getCurrentTimeType(int index) {
    if (_todoItems[index]['dueDate'] != null) {
          return 'due_date_time'.tr;
    } else if (_todoItems[index]['endTime'] != null) {
          return 'duration'.tr;
    }
        return 'none_option_short'.tr;
  }

  String _getCurrentTimeValue(int index) {
    if (_todoItems[index]['dueDate'] != null) {
      return _formatDateTime(_todoItems[index]['dueDate']);
    } else if (_todoItems[index]['endTime'] != null) {
      return _formatDateTime(_todoItems[index]['endTime']);
    }
    return '';
  }

  Widget _buildTodoItem(int index, Map<String, dynamic> todo) {
  // Legacy plain text controller kept for backward compatibility (unused with HtmlEditor)
    final DateTime? dueDate = todo['dueDate'];
    final DateTime? endTime = todo['endTime'];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Checkbox for todo completion
              Checkbox(
                value: todo['isCompleted'] ?? false,
                onChanged: (bool? value) {
                  setState(() {
                    todo['isCompleted'] = value ?? false;
                  });
                },
                activeColor: AppTheme.primaryOrange,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),

              // Rich text input field (HtmlEditor)
              Expanded(
                child: SizedBox(
                  height: 120,
                  child: HtmlEditor(
                    controller: todo['htmlController'],
                    htmlEditorOptions: HtmlEditorOptions(
                      hint: 'enter_todo_item_hint'.tr,
                      initialText: todo['html']?.isNotEmpty == true
                          ? todo['html']
                          : (todo['text'] ?? ''),
                      shouldEnsureVisible: false,
                    ),
                    htmlToolbarOptions: const HtmlToolbarOptions(
                      defaultToolbarButtons: [
                        StyleButtons(),
                        FontButtons(clearAll: false),
                        ColorButtons(),
                      ],
                      toolbarPosition: ToolbarPosition.belowEditor,
                      toolbarType: ToolbarType.nativeScrollable,
                    ),
                    otherOptions: const OtherOptions(height: 120),
                    callbacks: Callbacks(
                      onChangeContent: (content) {
                        todo['html'] = content ?? '';
                        final plain = (content ?? '')
                            .replaceAll(RegExp(r'<[^>]*>'), '')
                            .trim();
                        todo['text'] = plain;
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Set time button with indicator
              Container(
                decoration: BoxDecoration(
                  color: (dueDate != null || endTime != null)
                      ? Colors.green
                      : Colors.blue,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: IconButton(
                  onPressed: () => _setTodoTime(index),
                  icon: Icon(
                    (dueDate != null || endTime != null)
                        ? Icons.schedule_send
                        : Icons.access_time,
                    color: Colors.white,
                    size: 20,
                  ),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Delete button
              Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: IconButton(
                  onPressed: () => _removeTodoItem(index),
                  icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ),
            ],
          ),

          // Show time information if any is set
          if (dueDate != null || endTime != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              child: Column(
                children: [
                  // Due date
                  if (dueDate != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.today, size: 16, color: Colors.blue[700]),
                          const SizedBox(width: 4),
                          Text(
                            '${'due_date_time'.tr}: ${_formatDateTime(dueDate)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Duration/End Time
                  if (endTime != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer, size: 16, color: Colors.green[700]),
                          const SizedBox(width: 4),
                          Text(
                            '${'end_time'.tr}: ${_formatDateTime(endTime)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
