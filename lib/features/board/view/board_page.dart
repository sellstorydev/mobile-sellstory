import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sellstory/core/services/card_view_settings_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/dialog_utils.dart';
import '../controller/board_controller.dart';
import '../widgets/job_card_tile.dart';
import '../widgets/board_auto_scroll_wrapper.dart';
import '../widgets/lane_header.dart';
import '../widgets/status_summary_cards.dart';
import 'unified_filter_page.dart';
import '../../../domain/entities/lane.dart';
import '../../../domain/entities/board.dart';
import '../../../data/services/mobile_permissions_service.dart';
import '../widgets/workspace_app_bar.dart';


class BoardPage extends StatefulWidget {
  const BoardPage({super.key});

  @override
  State<BoardPage> createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage> {
  final BoardController _controller = Get.find<BoardController>();
  final CardViewSettingsService _settingsService = CardViewSettingsService.to;
  Worker? _wsWorker;
  Worker? _settingsWorker;
  Map<String, dynamic> _fieldConfigCache = {};
  Map<String, String> _userNameCache = {};

  Map<String, dynamic> _currentFieldConfigForBoard(String boardId) => _fieldConfigCache.isNotEmpty ? _fieldConfigCache : _defaultFieldConfig();

  Map<String, dynamic> _defaultFieldConfig() {
    final keys = [
      'customId','status','dateRange','createdAt','assignee','customerInterest','collaborators','customer','company','hashtags','grandTotal','netTotal','totalAmountBeforeDiscount','totalAmountAfterDiscount','totalAmountBeforeVat','description','todos'
    ];
    final m = <String,dynamic>{};
    for (var i=0;i<keys.length;i++){m[keys[i]]={'order':i,'isVisible':true,'style':{}};}
    return m;
  }

  Future<void> _loadPerBoardFieldConfig() async {
    try {
      print('🔧 Loading field config from CardViewSettingsService...');
      // Load from CardViewSettingsService instead of Firestore
      final fields = _settingsService.cardFields;
      print('🔧 Found ${fields.length} fields in service');
      
      // Convert CardFieldSetting list to the expected format
      final config = <String, dynamic>{};
      for (final field in fields) {
        // Map service field IDs to our field keys
        String mappedKey = _mapServiceFieldToKey(field.id);
        config[mappedKey] = {
          'order': field.order,
          'isVisible': field.isVisible,
          'style': {},
        };
        print('🔧 Mapped field: ${field.id} -> $mappedKey (visible: ${field.isVisible}, order: ${field.order})');
      }
      
      setState(() {
        _fieldConfigCache = config;
      });
      
      print('🔧 Field config loaded from CardViewSettingsService: ${config.keys.length} fields');
      print('🔧 Field config cache updated, will trigger UI rebuild');
    } catch (e) {
      print('❌ Error loading field config: $e');
      setState(() {
        _fieldConfigCache = _defaultFieldConfig();
      });
    }
  }

  // Map service field IDs to our internal field keys
  String _mapServiceFieldToKey(String serviceFieldId) {
    const Map<String, String> fieldMapping = {
      'jobId': 'customId',
      'createdDate': 'createdAt',
      'totalBeforeDiscount': 'totalAmountBeforeDiscount',
      'totalAfterDiscount': 'totalAmountAfterDiscount',
      'totalBeforeVAT': 'totalAmountBeforeVat',
      'todoList': 'todos',
    };
    
    return fieldMapping[serviceFieldId] ?? serviceFieldId;
  }

  Future<void> _buildUserNameCache() async {
    try {
      final workspaceUsers = await _controller.getWorkspaceUsers(_controller.currentWorkspaceId.value);
      setState(() {
        _userNameCache = { for (final u in workspaceUsers) if (u['id']!=null) u['id']: (u['name']??'') };
      });
    } catch (e) { 
      debugPrint('User name cache build error: $e'); 
    }
  }

  @override
  void initState() {
    super.initState();
    print('🚀 BoardPage initialized');
    
    // Initialize with current user
    _initializeWithCurrentUser();
    // Load field config & user names asynchronously
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🚀 Post frame callback - loading field config and user cache');
      _loadPerBoardFieldConfig();
      _buildUserNameCache();
    });

    // React to workspace changes to prefetch permissions
    _wsWorker = ever<String>(_controller.currentWorkspaceId, (wsId) {
      if (wsId.isNotEmpty) {
        _ensurePermissions(wsId);
      }
    });

    // Listen to CardViewSettingsService changes
    _settingsWorker = ever<List<CardFieldSetting>>(_settingsService.cardFieldsRx, (fields) {
      print('🔄 Settings changed, reloading field config...');
      _loadPerBoardFieldConfig();
    });
  }

  Future<void> _ensurePermissions(String workspaceId) async {
    try {
      print('🔍 Ensuring permissions for workspace: $workspaceId');
      final permsSvc = MobilePermissionsService.to;
      
      print('  - Current permissions: ${permsSvc.current.value?.permissions}');
      print('  - Current workspace ID: ${permsSvc.currentWorkspaceId.value}');
      print('  - isOwner: ${permsSvc.isOwner}');
      print('  - can(jobcard:create): ${permsSvc.can('jobcard:create')}');
      
      if (permsSvc.current.value == null || permsSvc.currentWorkspaceId.value != workspaceId) {
        print('  - Fetching new permissions...');
        try {
          await permsSvc.getMyPermissions(workspaceId: workspaceId);
          print('  - New permissions loaded: ${permsSvc.current.value?.permissions}');
          print('  - New isOwner: ${permsSvc.isOwner}');
          print('  - New can(jobcard:create): ${permsSvc.can('jobcard:create')}');
        } catch (apiError) {
          print('  - API permission fetch failed: $apiError');
          print('  - Using fallback permissions for better UX');
          // Set fallback permissions to allow basic functionality
          // This ensures the UI is not completely broken when permissions fail
        }
      } else {
        print('  - Using cached permissions');
      }
    } catch (e) {
      print('❌ Error ensuring permissions: $e');
      // Ignore on UI page; actions will simply be hidden
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when returning to this page
    _refreshDataIfNeeded();
  }

  @override
  void dispose() {
    _wsWorker?.dispose();
    _settingsWorker?.dispose();
    super.dispose();
  }

  void _refreshDataIfNeeded() {
    // Check if we need to refresh data (e.g., after creating new workspace)
    if (_controller.currentWorkspaceId.value.isEmpty && !_controller.isLoading.value) {
      _initializeWithCurrentUser();
    } else if (_controller.currentWorkspaceId.value.isNotEmpty && _controller.currentBoardId.value.isNotEmpty) {
      // Refresh board data when returning to this page
      _controller.refresh();
    }
  }

  void _handleMenuAction(String value) async {
    switch (value) {
      case 'board_management':
        Get.toNamed('/board-management');
        break;
      case 'refresh':
        _initializeWithCurrentUser();
        _buildUserNameCache();
        break;
      case 'calendar':
        Get.toNamed('/calendar');
        break;
      case 'edit_workspace':
        _navigateToEditWorkspace();
        break;
      case 'card_view_settings':
        final result = await Get.toNamed('/card-view-settings', arguments: {'boardId': _controller.currentBoardId.value});
        if (result == true) {
          // Reload field config when returning from settings
          print('🔄 Manual reload field config after settings change');
          _loadPerBoardFieldConfig();
          setState(() {}); // Force rebuild
        }
        break;
      default:
        if (value.startsWith('board_')) {
          final boardId = value.substring(6); // Remove 'board_' prefix
          _controller.switchBoard(boardId);
        } else if (value.startsWith('workspace_')) {
          final workspaceId = value.substring(10); // Remove 'workspace_' prefix
          _controller.switchWorkspace(workspaceId);
        }
        break;
    }
  }

  Future<void> _initializeWithCurrentUser() async {
    try {
      // Get current user ID from Firebase Auth
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ No authenticated user found');
        return;
      }
      
      final String currentUserId = currentUser.uid;
      print('👤 Initializing board with user: $currentUserId');
      
      await _controller.initializeWithUser(currentUserId);
      
      // Load user's assigned cards
      await _controller.loadUserAssignedCards();

      // Prefetch permissions for current workspace if available
      final wsId = _controller.currentWorkspaceId.value;
      if (wsId.isNotEmpty) {
        print('🔍 Initializing permissions for workspace: $wsId');
        await _ensurePermissions(wsId);
      } else {
        print('⚠️ No workspace ID available for permissions');
      }
    } catch (e) {
      print('❌ Failed to initialize board page: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Force build user cache if empty
    if (_userNameCache.isEmpty && _controller.currentWorkspaceId.value.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _buildUserNameCache();
      });
    }
    
    return Scaffold(
      appBar: WorkspaceAppBar(
        controller: _controller,
      ),
      body: Column(
        children: [

          
          // Search and Filter Section
          Obx(() {
            if (_controller.hasWorkspaces) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    // Search Bar
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: TextField(
                          controller: _controller.searchTextController,
                          onChanged: (value) {
                            _controller.updateSearchQuery(value);
                          },
                          textAlign: TextAlign.left,
                          textDirection: TextDirection.ltr,
                          keyboardType: TextInputType.text,
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Prompt',
                            letterSpacing: 0.0,
                          ),
                          decoration: InputDecoration(
                            hintText: 'รหัส Job Card ชื่อ-นามสกุล ลูกค้าและเซล',
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            suffixIcon: Obx(() {
                              if (_controller.searchQuery.value.isNotEmpty) {
                                return GestureDetector(
                                  onTap: () {
                                    _controller.updateSearchQuery('');
                                  },
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.grey[500],
                                    size: 20,
                                  ),
                                );
                              } else {
                                return Icon(
                                  Icons.search,
                                  color: Colors.grey[500],
                                  size: 20,
                                );
                              }
                            }),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Filter Button
                    GestureDetector(
                      onTap: _showUnifiedFilterPage,
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // Check if screen width is mobile (less than 600px)
                            final isMobile = MediaQuery.of(context).size.width < 600;
                            
                            if (isMobile) {
                              // Mobile: show only icon
                              return Icon(
                                Icons.filter_list,
                                color: Colors.grey[600],
                                size: 20,
                              );
                            } else {
                              // Desktop/Tablet: show icon + text
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.filter_list,
                                    color: Colors.grey[600],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'ตัวกรอง',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          
          // Status Summary Cards
          Obx(() {
            print('🎯 Status Summary Cards Obx called - hasWorkspaces: ${_controller.hasWorkspaces}, lanes count: ${_controller.lanes.length}');
            
            if (_controller.hasWorkspaces && _controller.lanes.isNotEmpty) {
              final hasAnyFilter = _controller.selectedAssignees.isNotEmpty ||
                                 _controller.selectedCustomers.isNotEmpty ||
                                 _controller.selectedHashtags.isNotEmpty ||
                                 _controller.selectedInterests.isNotEmpty ||
                                 _controller.selectedStatuses.isNotEmpty ||
                                 _controller.selectedDateFilterTypes.isNotEmpty;
              
              print('🎯 hasAnyFilter: $hasAnyFilter, selectedStatuses: ${_controller.selectedStatuses}');
              print('🎯 selectedInterests: ${_controller.selectedInterests}');
              
              final displayLanes = _controller.displayLanes;
              final allCards = displayLanes
                  .expand((lane) => lane.cards)
                  .toList();
                  
              print('🎯 Display lanes count: ${displayLanes.length}, All cards count: ${allCards.length}');
              
              return SizedBox(
                height: 65,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: StatusSummaryCards(
                    cards: allCards,
                    selectedStatuses: _controller.selectedStatuses,
                    onStatusTap: (String status) {
                      // Toggle status filter
                      _controller.toggleStatusFilter(status);
                    },
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          
          // Debug clear filters button removed
          // Board View
          Expanded(child: _buildBoardView()),
        ],
      ),
      floatingActionButton: Obx(() {
        // Only show FAB if user has workspaces and has permission to create jobcards
        if (_controller.hasWorkspaces) {
          final canCreate = MobilePermissionsService.to.isOwner ||
              MobilePermissionsService.to.can('jobcard:create');
          if (!canCreate) return const SizedBox.shrink();
           return FloatingActionButton(
             onPressed: () => _showAddOptionsDialog(),
             backgroundColor: AppTheme.primaryOrange,
             foregroundColor: Colors.white,
             child: const Icon(Icons.add),
             tooltip: 'Add New Item',
           );
         }
         return const SizedBox.shrink(); // Hide FAB when no workspaces
       }),
     );
   }

  Widget _buildBoardView() {
    return Obx(() {
      if (_controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_controller.error.value.isNotEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                _controller.error.value,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _controller.load(),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }

      if (!_controller.hasWorkspaces && _controller.isInitialized.value) {
        return Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Welcome to KanbanFlow',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Create a workspace to get started and organize your workflow.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _navigateToCreateWorkspace(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Create Workspace',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'You can also use the + button in the top right corner',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }

      if (!_controller.isInitialized.value) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing board...'),
            ],
          ),
        );
      }

    final hasAnyFilter = _controller.selectedAssignees.isNotEmpty ||
                         _controller.selectedCustomers.isNotEmpty ||
                         _controller.selectedHashtags.isNotEmpty ||
                         _controller.selectedInterests.isNotEmpty ||
                         _controller.selectedStatuses.isNotEmpty ||
                         _controller.selectedDateFilterTypes.isNotEmpty;
    final displayLanes = _controller.displayLanes;
  // Always show all lanes; cards may be empty depending on filters
  final lanesForView = displayLanes;

    if (lanesForView.isEmpty && _controller.hasWorkspaces) {
        if (hasAnyFilter) {
          // Show filter no results
          String filterMessage = '';
          final hasAssignee = _controller.selectedAssignees.isNotEmpty;
          final hasCustomer = _controller.selectedCustomers.isNotEmpty;
          final hasHashtag = _controller.selectedHashtags.isNotEmpty;
          final hasStatus = _controller.selectedStatuses.isNotEmpty;
          final hasDate = _controller.selectedDateFilterTypes.isNotEmpty;
          
          // Count the number of active filters
          final filterCount = [hasAssignee, hasCustomer, hasHashtag, hasStatus, hasDate].where((x) => x).length;
          
          if (filterCount >= 3) {
            filterMessage = 'ไม่พบงานสำหรับเงื่อนไขที่เลือกทั้งหมด';
          } else if (hasAssignee && hasCustomer) {
            filterMessage = 'ไม่พบงานสำหรับผู้รับผิดชอบและลูกค้าที่เลือก';
          } else if (hasAssignee && hasHashtag) {
            filterMessage = 'ไม่พบงานสำหรับผู้รับผิดชอบและแฮชแท็กที่เลือก';
          } else if (hasAssignee && hasDate) {
            filterMessage = 'ไม่พบงานสำหรับผู้รับผิดชอบและช่วงวันที่ที่เลือก';
          } else if (hasCustomer && hasHashtag) {
            filterMessage = 'ไม่พบงานสำหรับลูกค้าและแฮชแท็กที่เลือก';
          } else if (hasCustomer && hasDate) {
            filterMessage = 'ไม่พบงานสำหรับลูกค้าและช่วงวันที่ที่เลือก';
          } else if (hasHashtag && hasDate) {
            filterMessage = 'ไม่พบงานสำหรับแฮชแท็กและช่วงวันที่ที่เลือก';
          } else if (hasAssignee) {
            filterMessage = 'ไม่พบงานสำหรับผู้รับผิดชอบที่เลือก';
          } else if (hasCustomer) {
            filterMessage = 'ไม่พบงานสำหรับลูกค้าที่เลือก';
          } else if (hasHashtag) {
            filterMessage = 'ไม่พบงานสำหรับแฮชแท็กที่เลือก';
          } else if (hasStatus) {
            filterMessage = 'ไม่พบงานสำหรับสถานะที่เลือก';
          } else if (hasDate) {
            filterMessage = 'ไม่พบงานในช่วงวันที่ที่เลือก';
          }
          
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.filter_list_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  filterMessage,
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  'ลองเปลี่ยนเงื่อนไขการกรอง หรือ',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _controller.clearFilter(),
                  icon: const Icon(Icons.clear),
                  label: const Text('ล้างการกรอง'),
                ),
              ],
            ),
          );
        } else if (_controller.isSearching.value) {
          // Show search no results
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'ไม่พบผลการค้นหา',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  'ลองค้นหาด้วยคำอื่น หรือ',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _controller.clearSearch(),
                  icon: const Icon(Icons.clear),
                  label: const Text('ล้างการค้นหา'),
                ),
              ],
            ),
          );
        } else {
          // Show no lanes
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.dashboard_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'No lanes found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create your first lane to get started',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                if (MobilePermissionsService.to.isOwner ||
                    MobilePermissionsService.to.can('settings:board:manage'))
                  ElevatedButton.icon(
                    onPressed: () => _showAddLaneDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Lane'),
                  ),
              ],
            ),
          );
        }
      }

  return _buildBoard();
    });
  }

  Widget _buildBoard() {
  // Respect both search and active filters (assignee/customer/hashtag/status/date)
  final hasAnyFilter = _controller.selectedAssignees.isNotEmpty ||
    _controller.selectedCustomers.isNotEmpty ||
    _controller.selectedHashtags.isNotEmpty ||
    _controller.selectedInterests.isNotEmpty ||
    _controller.selectedStatuses.isNotEmpty ||
    _controller.selectedDateFilterTypes.isNotEmpty;

  final displayLanes = _controller.displayLanes;
  // Always show all lanes; cards may be empty depending on filters
  final visibleLanes = displayLanes;
    
  print('🔍 Building board with ${visibleLanes.length} lanes');
  for (final lane in visibleLanes) {
      print('  - Lane: ${lane.title} (${lane.cards.length} cards)');
    }
        
    return BoardAutoScrollWrapper(
      child: DragAndDropLists(
        onItemReorder: (int oldItemIndex, int oldListIndex, int newItemIndex, int newListIndex) {
          _handleCardReorder(oldItemIndex, oldListIndex, newItemIndex, newListIndex);
        },
        onListReorder: (int oldListIndex, int newListIndex) {
          // Lane reordering disabled - do nothing
        },
        axis: Axis.horizontal,
        listWidth: 300,
        listPadding: const EdgeInsets.all(8),
        listDragHandle: null, // Disable lane drag handle

        children: [
          ...visibleLanes.map((lane) {
            final laneData = lane;
            return DragAndDropList(
              header: _buildLaneHeader(laneData),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(8),
              ),
              children: [
                ...laneData.cards.map((card) {
                  final fieldCfg = _currentFieldConfigForBoard(_controller.currentBoardId.value);
                  final userCache = _userNameCache; // built separately
                  return DragAndDropItem(
                    child: JobCardTile(
                      card: card,
                      fieldConfig: fieldCfg,
                      userNameCache: userCache,
                    ),
                  );
                }).toList(),
                // Add card button at the bottom of each lane
                DragAndDropItem(
                  child: Builder(
                    builder: (context) {
                      print('🔍 Building add card button for lane: ${laneData.title}');
                      return _buildAddCardButton(laneData);
                    },
                  ),
                ),
              ],
            );
          }).toList(),
          // Add Lane Column
          DragAndDropList(
            header: null, // Remove header
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(8),
            ),
            children: [
              DragAndDropItem(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: _buildAddLaneButton(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLaneHeader(Lane lane) {
    return LaneHeader(
      lane: lane,
      onCreateCard: () => _navigateToCreateCardWithLane(lane),
      onMenuTap: () => _showLaneMenu(lane),
      onCloneLane: () => _cloneLane(lane),
      onDeleteLane: () => _deleteLane(lane),
      allLaneIds: _controller.lanes.map((l) => l.id).toList(),
    );
  }

  Widget _buildAddLaneHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF9F9F9),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.add_circle_outline,
            color: AppTheme.primaryOrange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'เพิ่ม Lane',
            style: TextStyle(
              color: AppTheme.primaryOrange,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddLaneButton() {
    final canCreate = MobilePermissionsService.to.isOwner ||
        MobilePermissionsService.to.can('settings:board:manage');
    if (!canCreate) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(12),
      child: InkWell(
        onTap: () => _showAddLaneDialog(),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add,
                size: 20,
                color: Colors.orange[600],
              ),
              const SizedBox(width: 8),
              Text(
                'เพิ่ม Lane',
                style: TextStyle(
                  color: Colors.orange[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToCreateCardWithLane(Lane lane) {
    print('🔄 Navigating to create card with lane:');
    print('  - Lane ID: ${lane.id}');
    print('  - Lane Name: ${lane.title}');
    print('  - Workspace ID: ${_controller.currentWorkspaceId.value}');
    
    Get.toNamed(
      '/create-card',
      parameters: {
        'laneId': lane.id,
        'workspaceId': _controller.currentWorkspaceId.value,
      },
    );
  }

  void _cloneLane(Lane lane) async {
    print('🎯 =================================================');
    print('🎯 CLONE OPERATION STARTED');
    print('🎯 Source Lane: ${lane.title}');
    print('🎯 Source Lane ID: ${lane.id}');
    print('🎯 Cards count in source lane: ${lane.cards.length}');
    print('🎯 Current workspace ID: ${_controller.currentWorkspaceId.value}');
    print('🎯 Current board ID: ${_controller.currentBoardId.value}');
    print('🎯 =================================================');
    
    try {
      print('🔄 Cloning lane: ${lane.title}');
      await _controller.onCloneLane(lane);
      
      print('🎯 =================================================');
      print('🎯 CLONE OPERATION COMPLETED SUCCESSFULLY');
      print('🎯 =================================================');
      
      Get.snackbar(
        'Success',
        'Lane "${lane.title}" cloned successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('🎯 =================================================');
      print('🎯 CLONE OPERATION FAILED');
      print('❌ Error cloning lane: $e');
      print('📍 Error type: ${e.runtimeType}');
      print('📍 Stack trace: ${StackTrace.current}');
      print('🎯 =================================================');
      
      Get.snackbar(
        'Error',
        'Failed to clone lane: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _deleteLane(Lane lane) async {
    print('🗑️ Delete lane request for: ${lane.title} (${lane.id})');
    
    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Lane'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to delete "${lane.title}"?'),
              const SizedBox(height: 8),
              if (lane.cards.isNotEmpty) ...[
                const Text(
                  'Warning: This lane contains cards that will also be deleted.',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text('Cards to be deleted: ${lane.cards.length}'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        print('🗑️ Deleting lane: ${lane.title} (${lane.id})');
        await _controller.deleteLane(laneId: lane.id);
        
        Get.snackbar(
          'Success',
          'Lane "${lane.title}" deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } catch (e) {
        print('❌ Error deleting lane: $e');
        Get.snackbar(
          'Error',
          'Failed to delete lane: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  void _showLaneMenu(Lane lane) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (MobilePermissionsService.to.isOwner ||
                MobilePermissionsService.to.can('settings:board:manage')) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('แก้ไข Lane'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showEditLaneDialog(lane);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('คัดลอก Lane'),
                onTap: () {
                  Navigator.of(context).pop();
                  // TODO: Implement copy lane functionality
                  Get.snackbar(
                    'Info',
                    'Copy Lane functionality coming soon',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.open_with),
                title: const Text('Move Lane'),
                onTap: () {
                  Navigator.of(context).pop();
                  // TODO: Implement move lane functionality
                  Get.snackbar(
                    'Info',
                    'Move Lane functionality coming soon',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.archive),
                title: const Text('Archive Lane'),
                onTap: () {
                  Navigator.of(context).pop();
                  // TODO: Implement archive lane functionality
                  Get.snackbar(
                    'Info',
                    'Archive Lane functionality coming soon',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('ลบ Lane'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showDeleteLaneConfirmation(lane);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddCardButton(Lane lane) {
    final canCreate = MobilePermissionsService.to.isOwner ||
        MobilePermissionsService.to.can('jobcard:create');
    
    // Debug: Print permission status
    print('🔍 Add Card Button Debug for lane: ${lane.title}');
    print('  - isOwner: ${MobilePermissionsService.to.isOwner}');
    print('  - can(jobcard:create): ${MobilePermissionsService.to.can('jobcard:create')}');
    print('  - canCreate: $canCreate');
    print('  - Current permissions: ${MobilePermissionsService.to.current.value?.permissions}');
    
    // Always show the button, but disable if no permission
    return Container(
      margin: const EdgeInsets.all(8),
      // decoration: BoxDecoration(
      //   border: Border.all(
      //     color: canCreate ? Colors.orange[300]! : Colors.grey[300]!,
      //     width: 2,
      //     style: BorderStyle.solid,
      //   ),
      //   borderRadius: BorderRadius.circular(8),
      //   color: canCreate ? Colors.orange[50] : Colors.grey[50],
      // ),
      child: InkWell(
        onTap: canCreate ? () => _navigateToCreateCardWithLane(lane) : () {
          // Show permission error message
          Get.snackbar(
            'Permission Required',
            'You need permission to create cards in this workspace',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange[100],
            colorText: Colors.orange[800],
          );
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add,
                size: 20,
                color: canCreate ? Colors.orange[600] : Colors.grey[400],
              ),
              const SizedBox(width: 8),
              Text(
                'Add a card',
                style: TextStyle(
                  color: canCreate ? Colors.orange[600] : Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleCardReorder(int oldItemIndex, int oldListIndex, int newItemIndex, int newListIndex) {
    try {
      // Permission check: moving cards
      final canMove = MobilePermissionsService.to.isOwner ||
          MobilePermissionsService.to.can('jobcard:move');
      if (!canMove) {
        Get.snackbar(
          'Permission',
          'You do not have permission to move cards',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
       final oldLane = _controller.lanes[oldListIndex];
       final newLane = _controller.lanes[newListIndex];
       final card = oldLane.cards[oldItemIndex];

       print('🔄 Card reordered: ${card.id} from ${oldLane.title} to ${newLane.title}');

       _controller.onMoveCard(
         cardId: card.id,
         fromLaneId: oldLane.id,
         toLaneId: newLane.id,
         toIndex: newItemIndex,
       );
     } catch (e) {
       print('❌ Failed to handle card reorder: $e');
     }
  }

  void _showAddLaneDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController orderController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Lane'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Lane Name *',
                  hintText: 'Enter lane name...',
                  prefixIcon: Icon(Icons.label),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: orderController,
                decoration: const InputDecoration(
                  labelText: 'Order',
                  hintText: 'Enter order (optional)',
                  prefixIcon: Icon(Icons.sort),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[600], size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Lane Structure',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• boardId: Auto-generated\n'
                      '• workspaceId: Current workspace\n'
                      '• name: Lane name\n'
                      '• order: Position in board\n'
                      '• cards: Empty array\n'
                      '• hasMoreCards: false',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                final order = orderController.text.trim().isNotEmpty 
                    ? int.tryParse(orderController.text.trim()) ?? _controller.lanes.length
                    : _controller.lanes.length;
                
                print('🔄 Adding new lane:');
                print('  - Name: ${nameController.text.trim()}');
                print('  - Order: $order');
                
                _controller.onAddLane(nameController.text.trim());
                Navigator.of(context).pop();
              } else {
                // Show error for required fields
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lane name is required'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Add Lane'),
          ),
        ],
      ),
    );
  }

  void _showAddOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (MobilePermissionsService.to.isOwner ||
                MobilePermissionsService.to.can('settings:board:manage'))
              ListTile(
                leading: const Icon(Icons.view_column),
                title: const Text('Add New Lane'),
                subtitle: const Text('Create a new column in the board'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showAddLaneDialog();
                },
              ),
            const Divider(),
            if (MobilePermissionsService.to.isOwner ||
                MobilePermissionsService.to.can('jobcard:create'))
              ListTile(
                leading: const Icon(Icons.note_add),
                title: const Text('Create New Card'),
                subtitle: const Text('Create a new card with full details'),
                onTap: () {
                  Navigator.of(context).pop();
                  _navigateToCreateCard();
                },
              ),
            // const Divider(),
            // ListTile(
            //   leading: const Icon(Icons.workspace_premium),
            //   title: const Text('Add New Workspace'),
            //   subtitle: const Text('Create a new workspace with boards'),
            //   onTap: () {
            //     Navigator.of(context).pop();
            //     _navigateToCreateWorkspace();
            //   },
            // ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _navigateToCreateCard() {
    Get.toNamed(
      '/create-card',
      parameters: {
        'workspaceId': _controller.currentWorkspaceId.value,
      },
    );
  }

  void _navigateToCreateWorkspace() {
    Get.toNamed('/create-workspace');
  }

  void _navigateToEditWorkspace() {
    final currentWorkspace = _controller.availableWorkspaces.firstWhereOrNull(
      (workspace) => workspace['id'] == _controller.currentWorkspaceId.value,
    );
    
    if (currentWorkspace != null) {
      Get.toNamed(
        '/edit-workspace',
        parameters: {
          'workspaceId': currentWorkspace['id'] as String,
          'currentName': currentWorkspace['name'] as String,
        },
      );
    }
  }

  void _showEditLaneDialog(Lane lane) {
    final TextEditingController nameController = TextEditingController(text: lane.title);
    final TextEditingController orderController = TextEditingController(text: lane.order.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Lane: ${lane.title}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Lane Name *',
                  hintText: 'Enter lane name...',
                  prefixIcon: Icon(Icons.label),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: orderController,
                decoration: const InputDecoration(
                  labelText: 'Order',
                  hintText: 'Enter order (optional)',
                  prefixIcon: Icon(Icons.sort),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                final newOrder = int.tryParse(orderController.text.trim()) ?? lane.order;
                
                print('🔄 Updating lane:');
                print('  - Lane ID: ${lane.id}');
                print('  - Old Title: ${lane.title}');
                print('  - New Title: ${nameController.text.trim()}');
                print('  - Old Order: ${lane.order}');
                print('  - New Order: $newOrder');
                
                try {
                  await _controller.updateLane(
                    laneId: lane.id,
                    title: nameController.text.trim(),
                    order: newOrder,
                  );
                  
                  Navigator.of(context).pop();
                  
                  Get.snackbar(
                    'Success',
                    'Lane updated successfully',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                } catch (e) {
                  print('❌ Error updating lane: $e');
                  Get.snackbar(
                    'Error',
                    'Failed to update lane: ${e.toString()}',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lane name is required'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Update Lane'),
          ),
        ],
      ),
    );
  }

  void _showDeleteLaneConfirmation(Lane lane) async {
    final confirmed = await DialogUtils.showDeleteConfirmDialog(
      context: context,
      title: 'Delete Lane',
      content: 'Are you sure you want to delete "${lane.title}"? This action cannot be undone and will also delete all cards in this lane.',
    );

    if (confirmed == true) {
      _controller.deleteLane(laneId: lane.id);
      
      Get.snackbar(
        'Success',
        'Lane deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    }
  }

  void _showSearchDialog() {
    if (_controller.isSearching.value) {
      // If already searching, clear search
      _controller.clearSearch();
      return;
    }

    final TextEditingController searchController = TextEditingController(
      text: _controller.searchQuery.value,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ค้นหางาน'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'คำค้นหา',
                hintText: 'ชื่องาน, รหัสงาน, ลูกค้า, ผู้รับผิดชอบ...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              autofocus: true,
                                    onChanged: (value) {
                // Real-time search as user types
                _controller.updateSearchQuery(value);
              },
              onSubmitted: (value) {
                _controller.updateSearchQuery(value);
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 16),
            // Debug button for testing search
            ElevatedButton(
              onPressed: () {
                print('🔍 DEBUG: Testing search with common terms...');
                final testTerms = ['New', 'Card', 'To Do', 'test', 'JB'];
                for (final term in testTerms) {
                  print('🔍 Testing search for: "$term"');
                  _controller.updateSearchQuery(term);
                  // Wait a bit then clear
                  Future.delayed(Duration(milliseconds: 100), () {
                    _controller.clearSearch();
                  });
                }
              },
              child: Text('Debug Search'),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[600], size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'ค้นหาจาก',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• ชื่องาน\n'
                    '• รายละเอียดงาน\n'
                    '• รหัสงาน\n'
                    '• ชื่อลูกค้า\n'
                    '• ผู้รับผิดชอบ\n'
                    '• สถานะงาน\n'
                    '• ชื่อเลน',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _controller.clearSearch();
              Navigator.of(context).pop();
            },
            child: const Text('ล้าง'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              final query = searchController.text.trim();
              if (query.isNotEmpty) {
                _controller.updateSearchQuery(query);
              }
              Navigator.of(context).pop();
            },
            child: const Text('ค้นหา'),
          ),
        ],
      ),
    );
  }

  void _showUnifiedFilterPage() {
    Get.to(() => const UnifiedFilterPage());
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showWorkspaceBoardSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Workspace Section
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    _navigateToEditWorkspace();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(color: Color(0xFFD9D9D9)),
                          child: Image.asset(
                            'assets/app_icon_original.png',
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Workspace ปัจจุบัน',
                                style: TextStyle(
                                  color: Color(0xFFFF6C0C),
                                  fontSize: 12,
                                  fontFamily: 'Prompt',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Obx(() => Text(
                                _controller.currentWorkspaceName.value.isNotEmpty 
                                  ? _controller.currentWorkspaceName.value 
                                  : 'My Workspace1',
                                style: const TextStyle(
                                  color: Color(0xFF4D4D4D),
                                  fontSize: 16,
                                  fontFamily: 'Prompt',
                                  fontWeight: FontWeight.w500,
                                ),
                              )),
                            ],
                          ),
                        ),
                        Icon(Icons.settings, color: Colors.grey[400], size: 20),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Current Board Section
                const Text(
                  'บอร์ดปัจจุบัน',
                  style: TextStyle(
                    color: Color(0xFFFF6C0C),
                    fontSize: 12,
                    fontFamily: 'Prompt',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                
                Obx(() {
                  final currentBoard = _controller.boards.firstWhereOrNull(
                    (board) => board.id == _controller.currentBoardId.value,
                  );
                  if (currentBoard != null) {
                    return _buildBoardItemWithAction(
                      currentBoard.name,
                      'Job Card ของคุณ ${currentBoard.lanes.length} ใบ',
                      const Color(0xFFFF6C0C),
                      currentBoard.id,
                      workspaceId: _controller.currentWorkspaceId.value,
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                }),
                
                const SizedBox(height: 24),
                
                // Your Boards Section
                const Text(
                  'บอร์ดของคุณ',
                  style: TextStyle(
                    color: Color(0xFFB3B3B3),
                    fontSize: 12,
                    fontFamily: 'Prompt',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                
                Obx(() {
                  if (_controller.boards.isNotEmpty) {
                    return Column(
                      children: _controller.boards.where((board) => 
                        board.id != _controller.currentBoardId.value
                      ).map((board) {
                        return _buildBoardItemWithAction(
                          board.name,
                          'Job Card ของคุณ ${board.lanes.length} ใบ',
                          const Color(0xFFFAB73F),
                          board.id,
                          workspaceId: _controller.currentWorkspaceId.value,
                        );
                      }).toList(),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                }),
                
                const SizedBox(height: 24),
                
                // Your Workspaces Section
                const Text(
                  'Workspace ของคุณ',
                  style: TextStyle(
                    color: Color(0xFFB3B3B3),
                    fontSize: 12,
                    fontFamily: 'Prompt',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                
                Obx(() {
                  if (_controller.availableWorkspaces.isNotEmpty) {
                    return Column(
                      children: _controller.availableWorkspaces.where((workspace) => 
                        workspace['id'] != _controller.currentWorkspaceId.value
                      ).map((workspace) {
                        return _buildWorkspaceItemWithAction(
                          workspace['name'] as String,
                          'Job Board ของคุณ ${workspace['boardCount'] ?? 0} บอร์ด',
                          false,
                          workspace['id'] as String,
                        );
                      }).toList(),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                }),
                

                
                const SizedBox(height: 24),
                
                // Create Workspace Button
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    _navigateToCreateWorkspace();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFF6C0C)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6C0C),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 12),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'สร้าง Workspace',
                          style: TextStyle(
                            color: Color(0xFFFF6C0C),
                            fontSize: 14,
                            fontFamily: 'Prompt',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 40), // Extra space for scrolling
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBoardItemWithAction(String title, String subtitle, Color color, String boardId, {String? workspaceId}) {
    return GestureDetector(
      onTap: () async {
        Navigator.of(context).pop();
        
        // If workspaceId is provided and different from current workspace, switch workspace first
        if (workspaceId != null && workspaceId != _controller.currentWorkspaceId.value) {
          try {
            print('🔄 Switching to workspace: $workspaceId');
            await _controller.switchWorkspace(workspaceId);
            
            // Wait a bit for workspace switch to complete
            await Future.delayed(const Duration(milliseconds: 500));
            
            // Then switch to the board
            print('🔄 Switching to board: $boardId');
            await _controller.switchBoard(boardId);
          } catch (e) {
            print('❌ Error switching workspace and board: $e');
            Get.snackbar(
              'Error',
              'เกิดข้อผิดพลาดในการเปลี่ยน workspace และ board',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          }
        } else {
          // Just switch board if in same workspace
          try {
            await _controller.switchBoard(boardId);
          } catch (e) {
            print('❌ Error switching board: $e');
            Get.snackbar(
              'Error',
              'เกิดข้อผิดพลาดในการเปลี่ยน board',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          // borderRadius: BorderRadius.circular(8),
          // border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF4D4D4D),
                      fontSize: 16,
                      fontFamily: 'Prompt',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF999999),
                        fontSize: 14,
                        fontFamily: 'Prompt',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.settings, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBoardItemSimple(String title, String subtitle, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF4D4D4D),
                    fontSize: 16,
                    fontFamily: 'Prompt',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF999999),
                      fontSize: 14,
                      fontFamily: 'Prompt',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.settings, color: Colors.grey[400], size: 20),
        ],
      ),
    );
  }

    Future<List<Board>> _getBoardsForWorkspace(String workspaceId) async {
    try {
      // Get boards for the specific workspace from Firestore
      final boards = await _controller.getBoardsForWorkspace(workspaceId);
      return boards;
    } catch (e) {
      print('❌ Failed to get boards for workspace $workspaceId: $e');
      return [];
    }
  }

  Widget _buildWorkspaceItemWithAction(String title, String subtitle, bool isExpanded, String workspaceId) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  isExpanded = !isExpanded;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  // borderRadius: BorderRadius.circular(8),
                  // border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: Colors.grey[500],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Color(0xFF4D4D4D),
                              fontSize: 16,
                              fontFamily: 'Prompt',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: Color(0xFF999999),
                              fontSize: 14,
                              fontFamily: 'Prompt',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.settings, color: Colors.grey[400], size: 20),
                  ],
                ),
              ),
            ),
            // Expanded boards section
            if (isExpanded) ...[
              Container(
                margin: const EdgeInsets.only(left: 24, top: 8, bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sub-header for boards
                    const Padding(
                      padding: EdgeInsets.only(left: 12, bottom: 8),
                      child: Text(
                        'บอร์ดของคุณ',
                        style: TextStyle(
                          color: Color(0xFFB3B3B3),
                          fontSize: 12,
                          fontFamily: 'Prompt',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    // Boards list
                    FutureBuilder<List<Board>>(
                      future: _getBoardsForWorkspace(workspaceId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6C0C)),
                              ),
                            ),
                          );
                        }
                        
                        if (snapshot.hasError) {
                          return Container(
                            padding: const EdgeInsets.all(16.0),
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red[200]!),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red, size: 16),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'เกิดข้อผิดพลาดในการโหลดข้อมูล',
                                    style: TextStyle(color: Colors.red, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        
                        final boards = snapshot.data ?? [];
                        if (boards.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(16.0),
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.grey, size: 16),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'ไม่มีบอร์ดใน workspace นี้',
                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        
                                                 return Column(
                           children: boards.map((board) {
                             return Container(
                               margin: const EdgeInsets.only(bottom: 4),
                               child: _buildBoardItemWithAction(
                                 board.name,
                                 'Job Card ของคุณ ${board.lanes.length} ใบ',
                                 const Color(0xFF44B87B),
                                 board.id,
                                 workspaceId: workspaceId,
                               ),
                             );
                           }).toList(),
                         );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildWorkspaceItemSimple(String title, String subtitle, bool isExpanded) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(
            isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            color: Colors.grey[500],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF4D4D4D),
                    fontSize: 16,
                    fontFamily: 'Prompt',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 14,
                    fontFamily: 'Prompt',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.settings, color: Colors.grey[400], size: 20),
        ],
      ),
    );
  }


}
