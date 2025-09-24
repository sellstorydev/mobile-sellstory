```markdown
## 2025-09-21 — Customer detail page TabBar font fix

- Modified TabBar in customer_detail_page.dart to use 'Prompt' font family for consistency with other pages
- Added fontFamily: 'Prompt' to both labelStyle and unselectedLabelStyle TextStyle properties
- Ensures TabBar text matches the font family used throughout the application

## 2025-09-20 — Customer delete action

## 2025-09-20 — Customer list after restart

- Hooked `CustomersController` to `FirebaseAuth.instance.authStateChanges()` to reliably initialize after app restarts when auth restores asynchronously.
- On user available: call `initializeWithUser(uid)` or re-`loadCustomers(workspaceId)` if list empty.
- On sign-out: cancel subscriptions and clear in-memory state.
- Added `onReady()` lifecycle with 2-second delayed check: if customers still empty but workspace/auth available, force `loadCustomers()` reload.

- Added delete icon to `customer_detail_page.dart` AppBar for users with permission (owner or `customer:delete`).
- On press: show confirm dialog (ยืนยัน/ยกเลิก). If confirmed, delete document at `/workspaces/{workspaceId}/customers/{customerId}` via `CustomersController.deleteCustomer()` and pop the page.
- No schema changes; relies on existing `CustomerRepository.deleteCustomer()` implementation.

## 2025-09-20 — Customer workspace switching fix

- Modified `switchWorkspace()` method in `CustomersController` to clear existing customer lists before loading new workspace data
- Added `customers.clear()` and `filteredCustomers.clear()` at the beginning of workspace switch to prevent showing old customer data
- This ensures clean slate when switching workspaces, solving the issue where old customer list was showing when switching to a workspace that has different or no customers

## 2025-09-21 — Debugging and cleanup

- Added extensive debug logging to track workspace switching and customer loading processes
- Removed all non-essential print statements while keeping error logging for debugging purposes
- Focus on core functionality without cluttering console output

## 2025-09-21 — Enhanced workspace switching with board info

- Enhanced `switchWorkspace()` method to immediately clear customer lists before loading new data
- Added debug prints to show current board ID and customer counts during workspace switching
- Ensures proper cleanup of old customer data and provides visibility into the switching process
- Added import for BoardController to access current board information

## 2025-09-21 — Customer list clearing fix

- Enhanced `switchWorkspace()` method to properly clear customer lists before workspace switching
- Added cancellation of existing customer subscriptions (`_customersSub`) to prevent data conflicts
- Reordered operations: clear data → cancel subscriptions → update workspace ID → load new data
- Added better debug logging to track the clearing process and final customer counts
- Fixed the issue where customer list was not properly cleared when switching workspaces

## 2025-09-21 — BoardController and CustomersController synchronization

- Added automatic notification from `BoardController.switchWorkspace()` to `CustomersController.switchWorkspace()` 
- When workspace is switched from board controller, it now automatically triggers customer data reload for the new workspace
- Added import of `CustomersController` in `BoardController` to enable cross-controller communication
- Verified backup data shows workspace `3w5mum6fnev2IEKF7G9d` (Bew1150) contains multiple customers that should be loaded
- Fixed the main issue where changing workspace in board didn't update customer list because controllers weren't synchronized

## 2025-09-21 — Customer list update after operations

- Fixed `addCustomer()` method to immediately add new customer to in-memory list and call `_filterCustomers()` for UI update
- Fixed `updateCustomer()` method to update existing customer in in-memory list and refresh filtered results
- Fixed `deleteCustomer()` method to remove customer from in-memory list and refresh filtered results
- All CRUD operations now update the local list immediately for instant UI feedback, while still maintaining database sync
- Solves the issue where customer list didn't update after add/edit/delete operations

## 2025-09-24 — Customer data auto-refresh implementation

- Enhanced `customer_detail_page.dart` to auto-refresh customer data on page entry and app lifecycle changes
- Added `_refreshCustomerData()` method that calls `controller.refreshCustomers()` and updates current customer state
- Implemented `WidgetsBindingObserver` and `RouteAware` mixins for lifecycle monitoring
- Added `didChangeAppLifecycleState()` to refresh when app resumes from background
- Added `didPopNext()` to refresh when returning from other pages
- Enhanced `customers_page.dart` with similar auto-refresh capabilities on page load and navigation
- Added proper cleanup in dispose methods for observers and route subscriptions
- Implemented history tab in customer detail page showing Firestore activities
- Added StreamBuilder for `/workspaces/{workspaceId}/activities/` collection filtered by `type='card-create'`
- Added Thai date formatting with Buddhist calendar year (+543)
- Shows user actions, card titles, lane names, and formatted timestamps
- Solves the issue where customer data was not refreshing when navigating between pages

## 2025-09-24 — History tab timestamp type error fix (Complete)

- Fixed TypeError in history tab where timestamp field could be either Timestamp or int type
- Enhanced timestamp handling in both activities sorting AND itemBuilder to check data type before casting
- Added safe conversion from int to Timestamp using `Timestamp.fromMillisecondsSinceEpoch()` in both locations
- Prevents crash when Firestore activities contain timestamp as int rather than Timestamp object
- History tab now properly sorts and displays activities regardless of timestamp data type stored in Firestore
- Fixed line 1746 error by replacing unsafe cast with proper type checking in ListView itemBuilder

## 2025-09-24 — History tab pull-to-refresh implementation (Complete)

- Converted History tab from real-time StreamBuilder to pull-to-refresh pattern to eliminate UI flickering
- Replaced StreamBuilder with RefreshIndicator and manual data management using state variables
- Added `_historyActivities`, `_historyLoading`, and `_historyCount` state variables for manual history data control
- Created `_loadHistoryData()` method for fetching activities data with proper timestamp type handling
- Implemented pull-to-refresh functionality allowing users to manually update history when needed
- Added loading states and empty state with "ดึงลงเพื่ออัปเดต" (pull down to update) instruction
- Enhanced UX by removing unwanted continuous real-time updates that caused flickering
- History data now loads on page initialization and refreshes only when user pulls down
- Maintains all existing functionality including timestamp type safety, sorting, and Thai date formatting

## 2025-09-24 — EditCardPage customer interest dropdown fix (Complete)

- Fixed DropdownButtonFormField error "There should be exactly one item with [DropdownButton]'s value: มาก (High)"
- Added validation in `initState()` to check if card's customerInterest exists in `_customerInterestOptions` list
- If card interest value doesn't match any dropdown option, defaults to 'interest_initial'.tr instead of crashing
- Prevents assertion error when Firestore contains interest values not present in dropdown options
- Enhanced customer interest initialization with proper existence checking before setting selected value
- Fixed line 6605 error in `_buildCustomerInterestSection()` method

## 2025-09-24 — Customer detail page Todo tab interactive checkbox (Complete)

- Enhanced Todo tab in customer detail page to make checkboxes interactive with Firestore updates
- Replaced static Container checkbox with GestureDetector for tap handling in `_buildTodoItem()` 
- Added `_updateTodoCompletion()` method to update todo completion status in Firestore
- Implemented robust Firestore update pattern: check document existence, find todo by ID, update in-place
- Added jobCardId and todoId extraction from todo data to identify specific todo items for updates
- Added comprehensive error handling with SnackBar notification for both success and failure cases
- Fixed "Job card not found" error by checking both 'cards' and 'jobCards' collections in Firestore
- Enhanced fallback mechanism to handle different Firestore collection structures (cards vs jobCards)
- Enhanced user feedback with success messages when todos are marked complete/incomplete
- Users can now tap checkboxes to mark todos as completed/incomplete and changes persist to database
- Fixed path issue by updating to correct Firestore path structure: `/workspaces/{workspaceId}/cards/{cardId}/todos`



```

## 2025-09-20 — Customer workspace switching fix

- Modified `switchWorkspace()` method in `CustomersController` to clear existing customer lists before loading new workspace data
- Added `customers.clear()` and `filteredCustomers.clear()` at the beginning of workspace switch to prevent showing old customer data
- This ensures clean slate when switching workspaces, solving the issue where old customer list was showing when switching to a workspace that has different or no customers

## 2025-09-21 — Debugging and cleanup

- Added extensive debug logging to track workspace switching and customer loading processes
- Removed all non-essential print statements while keeping error logging for debugging purposes
- Focus on core functionality without cluttering console output

## 2025-09-21 — Enhanced workspace switching with board info

- Enhanced `switchWorkspace()` method to immediately clear customer lists before loading new data
- Added debug prints to show current board ID and customer counts during workspace switching
- Ensures proper cleanup of old customer data and provides visibility into the switching process
- Added import for BoardController to access current board information

## 2025-09-21 — Customer list clearing fix

- Enhanced `switchWorkspace()` method to properly clear customer lists before workspace switching
- Added cancellation of existing customer subscriptions (`_customersSub`) to prevent data conflicts
- Reordered operations: clear data → cancel subscriptions → update workspace ID → load new data
- Added better debug logging to track the clearing process and final customer counts
- Fixed the issue where customer list was not properly cleared when switching workspaces

## 2025-09-21 — BoardController and CustomersController synchronization

- Added automatic notification from `BoardController.switchWorkspace()` to `CustomersController.switchWorkspace()` 
- When workspace is switched from board controller, it now automatically triggers customer data reload for the new workspace
- Added import of `CustomersController` in `BoardController` to enable cross-controller communication
- Verified backup data shows workspace `3w5mum6fnev2IEKF7G9d` (Bew1150) contains multiple customers that should be loaded
- Fixed the main issue where changing workspace in board didn't update customer list because controllers weren't synchronized

## 2025-09-21 — Customer list update after operations

- Fixed `addCustomer()` method to immediately add new customer to in-memory list and call `_filterCustomers()` for UI update
- Fixed `updateCustomer()` method to update existing customer in in-memory list and refresh filtered results
- Fixed `deleteCustomer()` method to remove customer from in-memory list and refresh filtered results
- All CRUD operations now update the local list immediately for instant UI feedback, while still maintaining database sync
- Solves the issue where customer list didn't update after add/edit/delete operations


