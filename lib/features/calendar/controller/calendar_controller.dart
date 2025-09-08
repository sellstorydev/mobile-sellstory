import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/repositories/firestore_repository.dart';
import '../../../core/services/workspace_members_service.dart';

class CalendarController extends GetxController {
  final FirestoreRepository _repository = Get.find<FirestoreRepository>();
  final WorkspaceMembersService _workspaceMembersService = Get.find<WorkspaceMembersService>();
  
  // Observable variables
  final isLoading = false.obs;
  final currentUserId = ''.obs;
  final currentWorkspaceId = ''.obs;
  
  // Calendar view mode
  final selectedViewMode = 'month'.obs; // 'month', 'week', 'day'
  
  // Filter variables
  final selectedFilterType = 'all'.obs; // 'all', 'jobcard', 'todo'
  final selectedAssignees = <String>[].obs;
  final selectedDate = DateTime.now().obs;
  
  // Events data
  final events = <Map<String, dynamic>>[].obs;
  final filteredEvents = <Map<String, dynamic>>[].obs;
  final jobCards = <Map<String, dynamic>>[].obs;
  final todos = <Map<String, dynamic>>[].obs;
  
  // Available members for assignee filter
  final availableMembers = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _initializeUserAndWorkspace();
  }

  Future<void> _initializeUserAndWorkspace() async {
    try {
      isLoading.value = true;
      
      // Get current user ID from Firebase Auth
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ No authenticated user found');
        return;
      }
      
      currentUserId.value = currentUser.uid;
      print('👤 Initializing calendar with user: ${currentUserId.value}');
      
      // Get user's workspaces
      print('📋 Fetching user workspaces...');
      final workspaces = await _repository.getUserWorkspaces(currentUserId.value);
      
      print('📋 User workspaces loaded: ${workspaces.length} workspaces');
      
      if (workspaces.isNotEmpty) {
        // Try to get last active workspace ID
        String? selectedWorkspaceId;
        String? selectedWorkspaceName;
        
        try {
          final lastActiveWorkspaceId = await _repository.getUserLastActiveWorkspaceId(currentUserId.value);
          print('📋 Last active workspace ID: $lastActiveWorkspaceId');
          
          if (lastActiveWorkspaceId != null && lastActiveWorkspaceId.isNotEmpty) {
            // Check if the last active workspace still exists in user's workspaces
            final lastActiveWorkspace = workspaces.firstWhereOrNull(
              (ws) => ws['id'] == lastActiveWorkspaceId
            );
            
            if (lastActiveWorkspace != null) {
              selectedWorkspaceId = lastActiveWorkspaceId;
              selectedWorkspaceName = lastActiveWorkspace['name'] as String;
              print('✅ Using last active workspace: $selectedWorkspaceName ($selectedWorkspaceId)');
            } else {
              print('⚠️ Last active workspace not found in user workspaces, using first workspace');
            }
          }
        } catch (e) {
          print('⚠️ Failed to get last active workspace: $e');
        }
        
        // Fallback to first workspace if no last active workspace
        if (selectedWorkspaceId == null) {
          final firstWorkspace = workspaces.first;
          selectedWorkspaceId = firstWorkspace['id'] as String;
          selectedWorkspaceName = firstWorkspace['name'] as String;
          print('✅ Using first workspace: $selectedWorkspaceName ($selectedWorkspaceId)');
        }
        
        currentWorkspaceId.value = selectedWorkspaceId;
        
        print('✅ Calendar initialized with workspace: $selectedWorkspaceName');
        
        // Load data
        await _loadData();
      } else {
        print('⚠️ No workspaces found for user: ${currentUserId.value}');
      }
    } catch (e) {
      print('❌ Failed to initialize user and workspace: $e');
      Get.snackbar(
        'Error',
        'Failed to initialize: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadData() async {
    try {
      isLoading.value = true;
      
      if (currentWorkspaceId.value.isEmpty) {
        print('⚠️ No workspace ID available');
        return;
      }

      // Load job cards from Firestore
      final cardsStream = _repository.getCardsStream(currentWorkspaceId.value);
      final cards = await cardsStream.first;
      
      print('📄 Loaded ${cards.length} job cards from Firestore');
      jobCards.value = cards.map((card) {
        final cardMap = card.toMap();
        cardMap['id'] = card.id; // Add the ID field
        return cardMap;
      }).toList();
      
      // Load workspace members for assignee filter
      final members = await _workspaceMembersService.getAssignableMembers(currentWorkspaceId.value);
      availableMembers.value = members.map((member) => {
        'uid': member.uid,
        'displayName': member.displayName,
        'email': member.email,
      }).toList();
      
      // Process events from job cards and todos
      _processEvents();
      
    } catch (e) {
      print('❌ Error loading calendar data: $e');
      Get.snackbar(
        'Error',
        'Failed to load calendar data: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _processEvents() {
    final allEvents = <Map<String, dynamic>>[];
    
    // Process job cards
    for (final card in jobCards) {
      // Add job card as event
      allEvents.add({
        'id': card['id'],
        'cardId': card['id'], // Add cardId for navigation
        'title': card['title'] ?? 'Untitled Job Card',
        'type': 'jobcard',
        'date': card['dueDate'] ?? card['createdAt'],
        'status': card['status'] ?? 'TODO',
        'assignee': card['assignee'],
        'description': card['description'] ?? '',
        'priority': card['priority'] ?? 'medium',
        'data': card,
        'todos': card['todos'] ?? [],
      });

      // print(card['todos']);
      
      // Process todos within job card
      final cardTodos = card['todos'] as List<dynamic>? ?? [];
      for (final todo in cardTodos) {
        if (todo is Map<String, dynamic>) {
          allEvents.add({
            'id': '${card['id']}_todo_${todo['id']}',
            'title': todo['title'] ?? 'Untitled Todo',
            'type': 'todo',
            'date': todo['dueDate'] ?? todo['createdAt'],
            'status': todo['status'] ?? 'TODO',
            'assignee': todo['assignee'],
            'description': todo['description'] ?? '',
            'priority': todo['priority'] ?? 'medium',
            'parentCardId': card['id'],
            'parentCardTitle': card['title'] ?? 'Untitled Job Card',
            'data': todo,
          });
        }
      }
    }
    
    events.value = allEvents;
    _applyFilters();
  }

  void setViewMode(String mode) {
    selectedViewMode.value = mode;
    _applyFilters();
  }

  void setFilterType(String type) {
    selectedFilterType.value = type;
    _applyFilters();
  }

  void setSelectedAssignees(List<String> assigneeIds) {
    selectedAssignees.value = List.from(assigneeIds);
    _applyFilters();
  }

  void setSelectedDate(DateTime date) {
    selectedDate.value = date;
    _applyFilters();
  }

  void _applyFilters() {
    try {
      var filtered = List<Map<String, dynamic>>.from(events);
      
      // Apply filter type
      switch (selectedFilterType.value) {
        case 'jobcard':
          filtered = filtered.where((event) => event['type'] == 'jobcard').toList();
          break;
        case 'todo':
          filtered = filtered.where((event) => event['type'] == 'todo').toList();
          break;
        case 'all':
        default:
          // No filtering by type
          break;
      }
      
      // Apply assignee filter
      if (selectedAssignees.isNotEmpty) {
        filtered = filtered.where((event) {
          final assignee = event['assignee'];
          if (assignee == null) return false;
          
          final assigneeId = assignee is String ? assignee : assignee['uid'];
          return selectedAssignees.contains(assigneeId);
        }).toList();
      }
      
             // Apply date filter based on view mode
       switch (selectedViewMode.value) {
         case 'month':
           filtered = _filterByMonth(filtered);
           break;
         case 'week':
           filtered = _filterByWeek(filtered);
           break;
         case '2week':
           filtered = _filterBy2Week(filtered);
           break;
       }
      
      filteredEvents.value = filtered;
      
      print('🔍 Applied filters - ${filtered.length} events found');
      
    } catch (e) {
      print('❌ Error applying filters: $e');
    }
  }

  List<Map<String, dynamic>> _filterByMonth(List<Map<String, dynamic>> events) {
    final startOfMonth = DateTime(selectedDate.value.year, selectedDate.value.month, 1);
    final endOfMonth = DateTime(selectedDate.value.year, selectedDate.value.month + 1, 0);
    
    return events.where((event) {
      final eventDate = DateTime.fromMillisecondsSinceEpoch(event['date'] ?? 0);
      return eventDate.isAfter(startOfMonth.subtract(const Duration(days: 1))) && 
             eventDate.isBefore(endOfMonth.add(const Duration(days: 1)));
    }).toList();
  }

  List<Map<String, dynamic>> _filterByWeek(List<Map<String, dynamic>> events) {
    final startOfWeek = selectedDate.value.subtract(Duration(days: selectedDate.value.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    return events.where((event) {
      final eventDate = DateTime.fromMillisecondsSinceEpoch(event['date'] ?? 0);
      return eventDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) && 
             eventDate.isBefore(endOfWeek.add(const Duration(days: 1)));
    }).toList();
  }

  List<Map<String, dynamic>> _filterBy2Week(List<Map<String, dynamic>> events) {
    final startOf2Week = selectedDate.value.subtract(Duration(days: selectedDate.value.weekday - 1));
    final endOf2Week = startOf2Week.add(const Duration(days: 14));
    
    return events.where((event) {
      final eventDate = DateTime.fromMillisecondsSinceEpoch(event['date'] ?? 0);
      return eventDate.isAfter(startOf2Week.subtract(const Duration(days: 1))) && 
             eventDate.isBefore(endOf2Week.add(const Duration(days: 1)));
    }).toList();
  }

  List<Map<String, dynamic>> getEventsForDate(DateTime date) {
    return filteredEvents.where((event) {
      final eventDate = DateTime.fromMillisecondsSinceEpoch(event['date'] ?? 0);
      return eventDate.year == date.year && 
             eventDate.month == date.month && 
             eventDate.day == date.day;
    }).toList();
  }

  String getStatusText(String status) {
    switch (status) {
      case 'TODO':
        return 'รอดำเนินการ';
      case 'IN_PROGRESS':
        return 'กำลังดำเนินการ';
      case 'DONE':
        return 'เสร็จสิ้น';
      case 'CANCELLED':
        return 'ยกเลิก';
      default:
        return status;
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'TODO':
        return const Color(0xFFFF9800);
      case 'IN_PROGRESS':
        return const Color(0xFF2196F3);
      case 'DONE':
        return const Color(0xFF4CAF50);
      case 'CANCELLED':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String getPriorityText(String priority) {
    switch (priority) {
      case 'high':
        return 'สูง';
      case 'medium':
        return 'ปานกลาง';
      case 'low':
        return 'ต่ำ';
      default:
        return priority;
    }
  }

  Color getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return const Color(0xFFF44336);
      case 'medium':
        return const Color(0xFFFF9800);
      case 'low':
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String formatDate(int timestamp) {
    if (timestamp == 0) return '-';
    
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.day}/${date.month}/${date.year}';
  }

  String formatTime(int timestamp) {
    if (timestamp == 0) return '-';
    
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Refresh data
  Future<void> refreshData() async {
    await _loadData();
  }
}
