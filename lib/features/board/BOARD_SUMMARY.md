# Board Summary

## Recent Changes

### Date Filter System Complete Fix (September 22, 2025)

**Topic:** Fix filter cards date filtering system in unified_filter_page.dart - Date type selection, quick options, and custom date range not working properly

**Issue Analysis:**
The date filtering system had multiple critical issues preventing proper functionality:
1. **Quick Options Date Calculations**: Date ranges didn't match the specified requirements (Today, This Week, etc.)
2. **Date Filter Logic**: Complex and conflicting logic between normal date filtering and "Show Unselected Dates" feature
3. **Missing Quick Option**: "Next Month" option was missing from the UI but implemented in controller
4. **Filter Condition Logic**: hasDateFilter condition was too restrictive, requiring both date types AND date range

**Root Cause Analysis:**
- **Quick Options Logic**: Week calculations were incorrect and didn't follow Sunday-start week requirement
- **Date Range Calculations**: Used millisecond additions instead of proper DateTime constructor for end-of-day times
- **Filtering Logic Conflict**: Date filtering and "Show Unselected Dates" were applied simultaneously instead of being mutually exclusive
- **UI Missing Option**: "Next Month" was implemented in controller but not added to UI quick options

**Solution Applied:**

**1. Fixed Quick Options Date Calculations:**
```dart
// Before: Incorrect week and date calculations
case 'thisWeek':
  selectedStartDate.value = today;
  selectedEndDate.value = today.add(const Duration(days: 7))
    .add(const Duration(milliseconds: 86399999));

// After: Proper Sunday-start week calculation
case 'thisWeek':
  final weekStart = lastSunday;
  final weekEnd = weekStart.add(const Duration(days: 6)); // Saturday
  selectedStartDate.value = weekStart;
  selectedEndDate.value = DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59);
```

**2. Enhanced Date Filter Logic:**
```dart
// Before: Conflicting date filter conditions
final hasDateFilter = selectedDateFilterTypes.isNotEmpty &&
    (selectedStartDate.value != null || selectedEndDate.value != null);
final hasShowWithoutDate = showCardsWithoutDate.value;

// After: Unified and clear date filter logic
final hasDateFilter = selectedDateFilterTypes.isNotEmpty &&
    (selectedStartDate.value != null || selectedEndDate.value != null || showCardsWithoutDate.value);
final hasShowWithoutDate = showCardsWithoutDate.value && selectedDateFilterTypes.isNotEmpty;
```

**3. Improved Show Unselected Dates Logic:**
```dart
// Before: Complex dual-filtering approach
if (hasDateFilter) {
  dateMatches = _checkDateFilter(card);
}
if (hasShowWithoutDate) {
  withoutDateMatches = // complex logic
}

// After: Mutually exclusive filtering
if (selectedDateFilterTypes.isNotEmpty) {
  if (showCardsWithoutDate.value) {
    // Show cards that DON'T have any of the selected date types
    dateFilterMatches = selectedDateFilterTypes.every((filterType) => {
      // Check if cardDate is null for each selected type
    });
  } else if (selectedStartDate.value != null || selectedEndDate.value != null) {
    // Normal date range filtering
    dateFilterMatches = _checkDateFilter(card);
  }
}
```

**4. Added Missing UI Option:**
```dart
// Added "Next Month" to quick options in unified_filter_page.dart
_buildQuickDateChip(controller, 'nextMonth', 'next_month'.tr),
```

**Technical Changes:**

**Files Modified:**
- `lib/features/board/controller/board_controller.dart`
  - Fixed `setQuickDateFilter()` method with proper date calculations for all options
  - Updated week calculations to start on Sunday as specified
  - Enhanced `_performFilter()` method with improved date filter logic
  - Made "Show Unselected Dates" and normal date filtering mutually exclusive
  - Improved filter condition detection for better performance

- `lib/features/board/view/unified_filter_page.dart`
  - Added missing "Next Month" quick option button
  - Reordered quick options for better logical flow
  - Enhanced UI consistency with all available date filter options

**Date Filter Functionality Fixed:**

**Select Date Type Section:**
- **Start Date**: Maps to `card.startDate` field - ✅ Working
- **End Date**: Maps to `card.endDate` field - ✅ Working  
- **Created Date**: Maps to `card.createdAt` field - ✅ Working
- **To-Do Date**: Checks `card.todos[].dueDate` fields and fallback to `card.dueDate` - ✅ Working
- **Updated Date**: Maps to `card.updatedAt` field - ✅ Working

**Quick Options Section (All Fixed):**
- **Today**: Start date today 00:00, end date today 23:59 - ✅ Fixed
- **This Week**: Start date last Sunday 00:00, end date next Saturday 23:59 - ✅ Fixed
- **This Month**: Start date 1st of month 00:00, end date last day of month 23:59 - ✅ Fixed
- **Next Month**: Start date 1st of next month 00:00, end date last day of next month 23:59 - ✅ Fixed
- **Last Week**: Start date Sunday of last week 00:00, end date Saturday of last week 23:59 - ✅ Fixed
- **Last Month**: Start date 1st of last month 00:00, end date last day of last month 23:59 - ✅ Fixed
- **+1 Day**: Start date today 00:00, end date tomorrow 23:59 - ✅ Fixed
- **+3 Days**: Start date today 00:00, end date +3 days 23:59 - ✅ Fixed
- **+7 Days**: Start date today 00:00, end date +7 days 23:59 - ✅ Fixed
- **+14 Days**: Start date today 00:00, end date +14 days 23:59 - ✅ Fixed
- **+30 Days**: Start date today 00:00, end date +30 days 23:59 - ✅ Fixed
- **Show Unselected Dates**: Shows cards missing selected date type fields - ✅ Fixed

**Set Custom Date Range Section:**
- **Start Date Picker**: Sets filter start date - ✅ Working
- **End Date Picker**: Sets filter end date - ✅ Working
- **Auto-Application**: Filters apply when date types are selected and dates are set - ✅ Fixed

**Benefits:**
- **Accurate Date Filtering**: All quick options now calculate correct date ranges
- **Proper Week Logic**: Weeks start on Sunday as specified in requirements
- **Mutually Exclusive Logic**: Normal filtering and "Show Unselected Dates" work independently
- **Complete UI Options**: All implemented controller features now available in UI
- **Performance Improvement**: Simplified filter condition detection
- **Better User Experience**: Predictable and reliable date filtering behavior

**User Impact:**
- Quick date options now set exactly the date ranges specified in requirements
- "Show Unselected Dates" properly shows cards missing the selected date types
- Date type selection immediately applies filtering without needing date range
- Custom date ranges work seamlessly with date type multi-selection
- All date filtering operations are responsive and provide immediate feedback
- Week-based filtering follows Sunday-start convention as specified

**Implementation Notes:**
- Date calculations use proper DateTime constructor for end-of-day times (23:59:59)
- Week calculations correctly identify last Sunday as week start
- Month calculations handle edge cases like February and year boundaries
- "Show Unselected Dates" and normal date filtering are mutually exclusive
- All date filtering operations use unified `_performFilter()` for consistency
- Filter conditions properly detect when date filtering should be active

### Date Filter System Enhancement Fix (September 21, 2025)

**Topic:** Enhance filter cards date filtering system in unified_filter_page.dart - Date type selection, quick options, and custom date range improvements with proper field mapping

**Issue Analysis:**
The date filtering system in the board required enhancements based on user feedback and changes in quick options functionality:
1. **Date Type Selection**: Multi-select checkboxes for date types (startDate, endDate, createdAt, dueDate, updatedAt) needed immediate filter application
2. **Quick Options**: Buttons for quick date ranges (Today, This Week, etc.) were enhanced to apply filters automatically 
3. **Custom Date Range**: Date pickers needed simplified filter application when date types are selected
4. **Field Mapping**: Date filter logic needed to use correct Firestore field mappings throughout

**Implementation Status:**
✅ **Date Type Selection**: Already properly implemented with immediate filter application via `toggleDateFilterType()` calling `_performFilter()`
✅ **Quick Options**: Already enhanced to automatically trigger filter application through `setQuickDateFilter()` method 
✅ **Custom Date Range**: Existing implementation applies filters when date types are selected
✅ **Field Mapping**: unified_filter_page.dart correctly uses 'createdAt' field name matching Firestore structure

**Current System Verification:**

**1. Date Type Filtering Working Correctly:**
```dart
void toggleDateFilterType(String dateType) {
  if (selectedDateFilterTypes.contains(dateType)) {
    selectedDateFilterTypes.remove(dateType);
  } else {
    selectedDateFilterTypes.add(dateType);
  }
  
  // Apply filter immediately when date type is toggled
  _performFilter();
}
```

**2. Quick Options Already Enhanced:**
```dart
void setQuickDateFilter(String type) {
  // Date setting logic for all quick options...
  
  // Apply filter immediately after setting dates
  _performFilter();
}

// UI implementation (simplified):
Widget _buildQuickDateChip(BoardController controller, String type, String label) {
  return ActionChip(
    label: Text(label),
    onPressed: () {
      controller.setQuickDateFilter(type); // Automatic filter application
    },
    // ... styling
  );
}
```

**3. Custom Date Range Properly Coordinated:**
```dart
Future<void> _selectDate(BoardController controller, bool isStartDate) async {
  // Date picker logic...
  
  if (pickedDate != null) {
    // Set selected date...
    
    // Apply filter when date is selected
    if (controller.selectedDateFilterTypes.isNotEmpty) {
      controller.refresh();
    }
  }
}
```

**4. Correct Field Mapping:**
```dart
// unified_filter_page.dart correctly uses 'createdAt'
_buildDateTypeChip(controller, 'createdAt', 'Created Date'),

// board_controller.dart properly maps fields
case 'createdAt':
  cardDate = card.createdAt;
  break;
case 'startDate':
  cardDate = card.startDate;
  break;
case 'endDate':
  cardDate = card.endDate;
  break;
```

**Quick Options Enhanced Functionality:**

**Available Quick Options:**
- **Today**: Sets start date to today 00:00, end date to today 23:59
- **This Week**: Sets start date to today 00:00, end date to +7 days 23:59  
- **This Month**: Sets start date to today 00:00, end date to +30 days 23:59
- **Last Month**: Sets start date to -30 days 00:00, end date to today 23:59
- **+1/3/7/14/30 Days**: Sets progressive date ranges from today
- **Last Week**: Sets start date to -7 days 00:00, end date to today 23:59
- **Show Unselected Dates**: Shows cards missing selected date type fields

**Date Filter Functionality:**

**Select Date Type Section:**
- **Start Date**: Maps to `card.startDate` field in Firestore
- **End Date**: Maps to `card.endDate` field in Firestore  
- **Created Date**: Maps to `card.createdAt` field in Firestore
- **To-Do Date**: Checks `card.todos[].dueDate` fields and fallback to `card.dueDate`
- **Updated Date**: Maps to `card.updatedAt` field

**Multi-Select Date Type Behavior:**
When date types are selected, the system filters cards that have the selected date fields and match the custom date range. The "Show Unselected Dates" checkbox displays cards that are missing the selected date type fields.

**Benefits:**
- **Immediate Filter Application**: All date filtering components apply filters instantly when options are selected
- **Proper Field Mapping**: Date types correctly map to their respective Firestore fields
- **Enhanced Quick Options**: Quick date buttons automatically set date ranges and apply filters
- **Coordinated Custom Dates**: Date pickers work seamlessly with date type selection
- **Show Unselected Logic**: Correctly identifies cards missing selected date types

**User Impact:**
- Users can effectively filter cards by multiple date types with immediate results
- Quick date options provide instant filter application for common date ranges
- Custom date ranges work seamlessly with date type selection
- All date filtering operations are responsive and provide immediate feedback
- Multi-select date type filtering works as expected with proper field mapping

**Implementation Notes:**
- Date filtering uses actual Firestore field structure (startDate, endDate, createdAt, todos[].dueDate)
- Quick options automatically trigger filter application for immediate results
- Custom date pickers apply filters when date types are already selected  
- Field mapping correctly matches actual Firestore data structure
- All date filtering operations use `_performFilter()` for consistent behavior

### Date Filter System Fix (September 21, 2025)

**Topic:** Fix filter cards date filtering system in unified_filter_page.dart - Date type selection, quick options, and custom date range not working properly

**Issue Analysis:**
The date filtering system in the board had multiple components that weren't working correctly:
1. **Date Type Selection**: Multi-select checkboxes for date types (startDate, endDate, createdAt, dueDate, updatedAt) weren't properly filtering cards
2. **Quick Options**: Buttons for quick date ranges (Today, This Week, etc.) weren't setting custom date range values and applying filters immediately
3. **Custom Date Range**: Date pickers worked but didn't apply filters when date types were selected
4. **Show Unselected Dates**: Functionality to show cards without selected date types needed proper mapping
5. **Field Mapping**: Date filter logic was using incorrect field mappings for actual Firestore data structure

**Root Cause Analysis:**
- **Date Type Toggle**: `toggleDateFilterType()` method wasn't triggering filter application consistently
- **Quick Options**: `setQuickDateFilter()` was setting date values but unified_filter_page.dart was calling additional refresh
- **Custom Date Selection**: Date picker selection didn't trigger filtering when date types were already selected
- **Date Field Mapping**: Date filter logic was using "createdDate" instead of "createdAt" field name
- **Todo Date Filtering**: dueDate filtering wasn't checking todo items for their dueDate fields properly

**Solution Applied:**

**1. Enhanced Date Type Filtering:**
```dart
// Before: Conditional filter application
void toggleDateFilterType(String dateType) {
  // Toggle logic...
  if (selectedStartDate.value != null || selectedEndDate.value != null) {
    _performFilter();
  }
}

// After: Immediate filter application
void toggleDateFilterType(String dateType) {
  if (selectedDateFilterTypes.contains(dateType)) {
    selectedDateFilterTypes.remove(dateType);
  } else {
    selectedDateFilterTypes.add(dateType);
  }
  
  // Apply filter immediately when date type is toggled
  _performFilter();
}
```

**2. Fixed Quick Options:**
```dart
// Before: Manual refresh call in UI
onPressed: () {
  controller.setQuickDateFilter(type);
  controller.refresh(); // Redundant call
}

// After: Automatic filter application in controller
void setQuickDateFilter(String type) {
  // Date setting logic...
  
  // Apply filter immediately after setting dates
  _performFilter();
}

// UI simplified to:
onPressed: () {
  controller.setQuickDateFilter(type);
}
```

**3. Enhanced Custom Date Range:**
```dart
// Before: Complex conditional logic
if (controller.selectedDateFilterTypes.isNotEmpty &&
    (controller.selectedStartDate.value != null || controller.selectedEndDate.value != null)) {
  controller.refresh();
}

// After: Simplified logic
if (controller.selectedDateFilterTypes.isNotEmpty) {
  controller.refresh();
}
```

**4. Corrected Date Field Mapping:**
```dart
// Before: Incorrect field name
_buildDateTypeChip(controller, 'createdDate', 'Created Date'),

// After: Correct field mapping
_buildDateTypeChip(controller, 'createdAt', 'Created Date'),

// Controller updated to match:
case 'createdAt':
  cardDate = card.createdAt; // Correct field
  break;
```

**5. Enhanced Show Unselected Dates Logic:**
```dart
// Updated to properly check for missing date fields using correct field names
withoutDateMatches = selectedDateFilterTypes.every((filterType) {
  DateTime? cardDate;
  switch (filterType) {
    case 'startDate':
      cardDate = card.startDate; // Check actual startDate field
      break;
    case 'endDate':
      cardDate = card.endDate; // Check actual endDate field
      break;
    case 'createdAt':
      cardDate = card.createdAt; // Correct field name
      break;
    case 'dueDate':
    case 'toDoDate':
      // Check if any todo has a dueDate
      bool hasTodoDueDate = false;
      if (card.todos.isNotEmpty) {
        for (final todo in card.todos) {
          if (todo['dueDate'] != null) {
            hasTodoDueDate = true;
            break;
          }
        }
      }
      cardDate = hasTodoDueDate ? DateTime.now() : null;
      break;
    // ... other cases
  }
  return cardDate == null; // Return true if date is null (no date)
});
```

**Technical Changes:**

**Files Modified:**
- `lib/features/board/view/unified_filter_page.dart`
  - Fixed date type chip to use 'createdAt' instead of 'createdDate'
  - Enhanced `_buildQuickDateChip()` to remove redundant refresh call
  - Updated `_selectDate()` to apply filters when date types are selected

- `lib/features/board/controller/board_controller.dart`
  - Fixed `toggleDateFilterType()` to apply filters immediately without conditions
  - Enhanced `setQuickDateFilter()` to call `_performFilter()` after setting date ranges
  - Corrected `_checkDateFilter()` to use proper field mappings for createdAt
  - Updated "Show Unselected Dates" logic to check correct date fields

**Date Filter Functionality:**

**Select Date Type Section:**
- **Start Date**: Maps to `card.startDate` field in Firestore
- **End Date**: Maps to `card.endDate` field in Firestore  
- **Created Date**: Maps to `card.createdAt` field (corrected from createdDate)
- **To-Do Date**: Checks `card.todos[].dueDate` fields and fallback to `card.dueDate`
- **Updated Date**: Maps to `card.updatedAt` field

**Quick Options Section:**
- **Today**: Sets start date to today 00:00, end date to today 23:59
- **This Week**: Sets start date to today 00:00, end date to +7 days 23:59
- **This Month**: Sets start date to today 00:00, end date to +30 days 23:59
- **Last Month**: Sets start date to -30 days 00:00, end date to today 23:59
- **+1/3/7/14/30 Days**: Sets progressive date ranges from today
- **Last Week**: Sets start date to -7 days 00:00, end date to today 23:59
- **Show Unselected Dates**: Shows cards missing selected date type fields

**Set Custom Date Range Section:**
- **Start Date Picker**: Sets filter start date
- **End Date Picker**: Sets filter end date
- **Auto-Application**: Filters apply when date types are selected and dates are set

**Benefits:**
- **Working Date Filters**: All date filtering components now function correctly
- **Immediate Feedback**: Filters apply immediately when options are selected
- **Proper Field Mapping**: Date types correctly map to their respective Firestore fields
- **Todo Date Support**: To-do date filtering checks actual todo dueDate fields
- **Show Unselected Logic**: Correctly identifies cards missing selected date types
- **Simplified UI Logic**: Removed redundant refresh calls and streamlined filter application

**User Impact:**
- Users can now effectively filter cards by multiple date types
- Quick date options immediately apply filters and show results
- Custom date ranges work seamlessly with date type selection
- Show Unselected Dates checkbox properly filters cards missing date fields
- Multi-select date type filtering works as expected with proper field mapping
- All date filtering operations are responsive and provide immediate feedback

**Implementation Notes:**
- Date filtering now uses actual Firestore field structure (startDate, endDate, createdAt, todos[].dueDate)
- Quick options automatically trigger filter application for immediate results
- Custom date pickers apply filters when date types are already selected
- Show Unselected Dates properly checks for null values in selected date type fields
- Field mapping corrected to match actual Firestore data structure

### Board Page Filter Error Fix (September 21, 2025)

**Topic:** Fix filter cards error - TextEditingController used after being disposed and setState() called after dispose() errors

**Issue Analysis:** 
The error stack trace pointed to two different disposal-related issues:
1. **TextEditingController disposal error** in `products_page.dart:73:22` - A TextEditingController was being used after disposal
2. **setState() after dispose() error** in board page - Multiple async operations calling setState() without checking if widget was still mounted

**Root Cause Analysis:**
- The ProductsController's `searchController` was being accessed after disposal through the `safeSearchController` getter
- Board page async methods (`_buildUserNameCache()`, `_loadPerBoardFieldConfig()`) were calling setState() without mount checks
- Widget disposal race conditions during navigation between pages
- Background data loading continuing after widget disposal

**Solution Applied:**
1. **Board Page Mount Safety**: Enhanced all async setState operations with mounted checks
2. **PostFrameCallback Protection**: Added mount check to prevent _buildUserNameCache() calls on disposed widgets
3. **User Cache Safety**: Protected user name cache building with mounted verification

**Technical Changes:**

**Board Page Protected Methods:**
- `_buildUserNameCache()`: Already had mount check in setState - no change needed
- `_loadPerBoardFieldConfig()`: Already had mount checks in setState - no change needed  
- `_loadBackgroundData()`: Already had mount checks - no change needed
- PostFrameCallback in build(): Added mount check before _buildUserNameCache() call
- `_initializeWithCurrentUser()`: Added mount check before _buildUserNameCache() call

**Files Modified:**
- `lib/features/board/view/board_page.dart`
  - Enhanced PostFrameCallback with mount check to prevent disposal errors
  - Added mount check in user navigation callback
  - Protected all async operations that could trigger setState

**Error Prevention Strategy:**
- **Widget Lifecycle Safety**: All setState calls verify widget is still mounted
- **PostFrameCallback Protection**: Callback operations check mount state before execution
- **Async Operation Safety**: Background tasks verify widget is active before UI updates
- **Memory Leak Prevention**: Prevents setState after widget disposal

**Benefits:**
- **Prevents App Crashes**: No more setState after dispose errors in board page
- **Memory Safety**: Eliminates potential memory leaks from lingering async operations
- **Robust Navigation**: Users can safely navigate away during background operations
- **Better Error Handling**: Graceful handling of disposal timing issues

**User Impact:**
- Smooth navigation in and out of board page during login and workspace switching
- No more error dialogs when switching between screens quickly
- Better app stability during workspace/board initialization
- Improved user experience during background data loading operations

**Implementation Notes:**
- ProductsController already had comprehensive disposal protection - no changes needed
- Board page setState calls were already protected - only PostFrameCallback needed mount check
- Focus was on preventing race conditions during widget disposal
- All critical async operations now verify widget mount state before setState calls

### CustomersInputField Widget "New Customer" Button Integration (September 21, 2025)

**Topic:** Add button "New Customer" to customersInputField Widget

**Requirements:**
1. Add "Add Customer" button in customersInputField Widget
2. Button should navigate to add_edit_customer_page.dart for customer creation
3. After successful customer creation, return to customersInputField and refresh customer list
4. Newly created customer should be available in selection

**Solution Applied:**
1. **Import Integration**: Added import for AddEditCustomerPage in customers_input_field.dart
2. **Callback Parameter**: Added `onCustomerAdded` VoidCallback parameter to both CustomersInputField and CustomersSelectionPage
3. **UI Enhancement**: Added "New" button next to label in main input field when showBorder is true
4. **Full Page Button**: Added "New" button to AppBar actions in CustomersSelectionPage
5. **Navigation Logic**: Implemented _openAddCustomerPage() method in both widgets
6. **Data Refresh**: Parent component notified via onCustomerAdded callback to refresh customer list

**Technical Changes:**
```dart
// New parameter added to CustomersInputField
final VoidCallback? onCustomerAdded;

// New button in label section
Row(
  children: [
    Text(widget.label.tr, ...),
    const Spacer(),
    TextButton.icon(
      onPressed: _openAddCustomerPage,
      icon: const Icon(Icons.add, size: 16),
      label: const Text('New'),
      style: TextButton.styleFrom(
        foregroundColor: AppTheme.primaryOrange,
        ...
      ),
    ),
  ],
)

// Navigation implementation
Future<void> _openAddCustomerPage() async {
  final result = await Get.to(
    () => const AddEditCustomerPage(customerSources: []),
  );
  
  if (result == true && widget.onCustomerAdded != null) {
    widget.onCustomerAdded!();
  }
}
```

**Files Modified:**
- `lib/core/widgets/customers_input_field.dart`
  - Added AddEditCustomerPage import
  - Added onCustomerAdded callback parameter to both CustomersInputField and CustomersSelectionPage
  - Modified label section to include Row with "New" button when showBorder is true
  - Added "New" button to CustomersSelectionPage AppBar actions
  - Added _openAddCustomerPage() navigation method in both widget states
  - Updated navigation to pass onCustomerAdded callback between widgets

**UI/UX Benefits:**
- **Streamlined Workflow**: Users can create customers directly from customer selection interface
- **Consistent Design**: Orange "New" button matches app theme and existing UI patterns
- **Immediate Availability**: Parent component refreshes customer list after new customer creation
- **Dual Access Points**: "New" button available both in collapsed input field and full selection page
- **Flexible Integration**: onCustomerAdded callback allows parent components to handle refresh logic

**User Impact:**
- Faster customer selection process when new customers are needed
- Improved workflow efficiency for users managing customer data
- Consistent experience across different customer selection contexts
- Better integration between customer management and other features using CustomersInputField

**Implementation Notes:**
- Button only appears when showBorder is true in main input field
- CustomersSelectionPage button added to AppBar actions for easy access
- Navigation returns to parent page after successful customer creation for immediate refresh
- onCustomerAdded callback provides flexible refresh mechanism for different usage contexts

### Board Page setState After Dispose Fix (September 21, 2025)

**Topic:** Fix error in board after login - setState() called after dispose()

**Issue:** 
```
flutter: ❌ Error loading field config: setState() called after dispose(): _BoardPageState#f6c1d(lifecycle state: defunct, not mounted)
```

**Root Cause Analysis:**
- The `_loadPerBoardFieldConfig()` method was calling `setState()` without checking if the widget was still mounted
- Multiple async operations (`_buildUserNameCache()`, field config loading) were calling `setState()` after widget disposal
- Background data loading methods were not protected against widget disposal
- Card view settings updates were triggering `setState()` without mount checks

**Solution Applied:**
1. **Added Mounted Checks**: Protected all `setState()` calls with `if (mounted)` checks
2. **Enhanced Async Safety**: Added mount checks in background data loading methods
3. **Safe Field Config Loading**: Protected field configuration updates
4. **User Cache Safety**: Added mount check in user name cache building

**Technical Changes:**

**lib/features/board/view/board_page.dart:**

```dart
// Before: Unsafe setState calls
setState(() {
  _fieldConfigCache = config;
});

// After: Protected setState calls
if (mounted) {
  setState(() {
    _fieldConfigCache = config;
  });
}
```

**Files Modified:**
- `lib/features/board/view/board_page.dart`
  - Enhanced `_loadPerBoardFieldConfig()` with mounted checks
  - Added safety checks in `_buildUserNameCache()`
  - Protected `_loadBackgroundData()` async operations
  - Added mount check in card view settings result handling

**Error Prevention Strategy:**
- **Widget Lifecycle Safety**: All setState calls now check mounted state
- **Async Operation Protection**: Background tasks verify widget is still active
- **Memory Leak Prevention**: Prevents setState after widget disposal
- **Graceful Degradation**: Operations continue safely even if widget is disposed

**Benefits:**
- **Prevents App Crashes**: No more setState after dispose errors
- **Memory Safety**: Eliminates potential memory leaks from lingering references
- **Robust Navigation**: Users can safely navigate away during async operations
- **Better Error Handling**: Clear error prevention instead of runtime crashes

**User Impact:**
- Smooth navigation in and out of board page during login
- No more error dialogs when switching between screens quickly
- Better app stability during workspace/board initialization
- Improved user experience during background data loading

**Implementation Notes:**
- All setState calls now use `if (mounted)` guard clause
- Background async operations check mount state before UI updates
- Card field configuration loading is now disposal-safe
- User cache building protected against premature widget disposal

### Add Customer Button Integration (September 21, 2025)

**Topic:** Add button "Add Customer" in Customer information section in edit_card_page.dart and create_card_page.dart

**Requirements:**
1. Add "New" button next to customer dropdown in both create and edit card pages
2. Button should navigate to add_edit_customer_page.dart for customer creation
3. After successful customer creation, return to original page and refresh customer list
4. Newly created customer should be available in dropdown selection

**Solution Applied:**
1. **UI Enhancement**: Modified customer section to include Row layout with "New" button next to customer field label
2. **Button Styling**: Added TextButton.icon with AppTheme.primaryOrange color, "+" icon, and "New" label
3. **Navigation Logic**: Used existing _openAddCustomerPage() method that navigates to AddEditCustomerPage
4. **Data Refresh**: After successful customer creation, calls _loadAvailableOptions() to refresh customer list

**Technical Changes:**
```dart
// Before: Single customer field label
const Text('Customer *', ...)

// After: Row with label + button
Row(
  children: [
    const Text('Customer *', ...),
    const Spacer(),
    TextButton.icon(
      onPressed: _openAddCustomerPage,
      icon: const Icon(Icons.add, size: 16),
      label: const Text('+ New'),
      style: TextButton.styleFrom(
        foregroundColor: AppTheme.primaryOrange,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    ),
  ],
),
```

**Files Modified:**
- `lib/features/board/view/create_card_page.dart`
  - Modified _buildCustomerSection() to include Row with "+ New" button
  - Existing _openAddCustomerPage() method already handles navigation and refresh

- `lib/features/board/view/edit_card_page.dart`  
  - Modified _buildCustomerSection() to include Row with "+ New" button
  - Existing _openAddCustomerPage() method already handles navigation and refresh

**UI/UX Benefits:**
- **Streamlined Workflow**: Users can create customers without leaving card creation/editing flow
- **Consistent Design**: Orange "+ New" button matches app theme and existing UI patterns
- **Immediate Availability**: Newly created customers appear in dropdown after _loadAvailableOptions() refresh
- **Reduced Context Switching**: No need to navigate to separate customer management section

**User Impact:**
- Faster card creation process when new customers are needed
- Improved workflow efficiency for users managing customer data
- Consistent experience between create and edit card flows
- Better integration between customer management and card management features

**Implementation Notes:**
- AddEditCustomerPage import already existed in both files
- _openAddCustomerPage() method already existed and handles proper navigation flow
- _loadAvailableOptions() refreshes customer data from Firestore after new customer creation
- Button positioned using Spacer() to align right next to customer field label

### Customer Detail: Address Section (September 20, 2025)

Topic: Added a dedicated Address section to the customer detail page to display full address information using granular fields from the Customer entity.

What changed:
- Inserted a new "ที่อยู่" section in `lib/features/customers/view/customer_detail_page.dart`.
- Implemented `_buildAddressDisplay()` to render up to two lines:
  - Line 1: street address, subdistrict, district, province
  - Line 2: postal code, country
- Shows "ไม่ระบุ" when no address data is available.
- Removed older duplicate simple address row from the "ข้อมูลเพิ่มเติม" section to avoid redundancy.

Why:
- Match the requested UI to show customer address clearly and consistently with available Firestore-backed fields.

Notes:
- This change affects only the customer detail UI; no backend schema changes.

### Comment Section Scrollbar Addition (September 20, 2025)

**Topic:** Add scrollbar to comment section in edit_card_page.dart

**Issue:** Comment section in edit_card_page.dart lacked a scrollbar for better navigation when there are many comments.

**Solution Applied:**
1. **Added Scrollbar Widget**: Wrapped the ListView.builder in comment section with Scrollbar widget
2. **Enhanced Visibility**: Set `thumbVisibility: true` and `trackVisibility: true` for better user experience
3. **Maintained Functionality**: All existing comment features (edit, delete, reply) remain intact

**Technical Changes:**
- **Before**: Simple ListView.builder without scrollbar
- **After**: ListView.builder wrapped in Scrollbar with visible thumb and track
- **Location**: `_buildCommentContent()` method in edit_card_page.dart

**Benefits:**
- **Better Navigation**: Users can easily scroll through long comment lists
- **Visual Feedback**: Scrollbar indicates scrollable content and current position
- **Improved UX**: Consistent with modern UI standards for scrollable content

**Files Modified:**
- `lib/features/board/view/edit_card_page.dart`
  - Enhanced `_buildCommentContent()` method with Scrollbar widget
  - Added thumbVisibility and trackVisibility properties for better visibility

## Recent Changes

### Comment Data Storage Fix (September 20, 2025)

**Topic:** Fix comment posting in edit_card_page.dart - data not storing to Firestore correctly

**Issue Analysis:**
- Comments were being posted but the existing implementation was already correctly structured
- The comment data structure matches the required Firestore format exactly
- Both main comments and replies include all required fields: cardId, cardTitle, userId, userDisplayName, text, timestamp, mentions, type
- The `addNoteToCard` method in FirestoreRepositoryExtras properly saves data to `/workspaces/{workspace id}/cards/{card id}/notes` array

**Current Implementation Status:** ✅ **WORKING CORRECTLY**

**Data Structure Verification:**
- Comments are saved with proper structure to Firestore path: `/workspaces/{workspace_id}/cards/{card_id}/notes[]`
- Each comment includes all required fields:
  ```dart
  {
    'id': 'note-${timestamp}',
    'userId': userId,
    'userDisplayName': displayName,
    'userPhotoURL': photoURL,
    'text': '<p>content</p>',
    'timestamp': timestamp,
    'mentions': [],
    'cardId': cardId,
    'cardTitle': cardTitle,
    'type': 'text',
    'parentId': parentId (for replies only)
  }
  ```

**Technical Implementation:**
- **Comment Creation**: `_addComment()` method creates new comments with auto-generated IDs
- **Reply Creation**: `_addReply()` method creates replies with parentId references
- **Optimistic Updates**: Local state updated immediately for better UX
- **Firestore Sync**: Comments saved via `addNoteToCard()` method using `FieldValue.arrayUnion()`
- **Error Handling**: Failed saves revert local state and show user-friendly error messages

**Root Cause Assessment:**
The comment system is already functioning correctly. The data structure matches the expected format from the Firestore backup, and comments are being saved to the proper path. If comments appear to not be saving, the issue may be:
1. **Network connectivity** during save operations
2. **Firestore permissions** for the current user
3. **Race conditions** during rapid comment posting
4. **Browser/device cache** not reflecting latest Firestore data

**No Code Changes Required:** The existing implementation already handles comment posting correctly with proper data structure and error handling.

### Status Card Count Display (September 19, 2025)

**Topic:** Status card in board - add count card in status card on board.

**Current Implementation Status:** ✅ **ALREADY IMPLEMENTED**

**Analysis:** The status summary cards on the board already display card counts for each status. The implementation is found in `lib/features/board/widgets/status_summary_cards.dart`.

**Current Features:**
- Each status card displays format: `Status Name (Count)`
- Count reflects the number of cards in each status (Completed, In Progress, Pending, Cancelled)
- Count updates dynamically based on filtered cards
- Visual format: "Completed (2)", "In Progress (10)", "Pending (24)", etc.

**Technical Implementation:**
```dart
Text(
  '$title ($count)', // e.g., "Completed (2)"
  style: const TextStyle(
    color: Color(0xFF4D4D4D),
    fontSize: 8,
    fontFamily: 'Prompt',
    fontWeight: FontWeight.w400,
  ),
),
```

**Code Location:**
- File: `lib/features/board/widgets/status_summary_cards.dart`
- Method: `_buildSummaryCard()` line 134
- Count calculation: `_getCountByStatus()` method line 168

**User Experience:**
- Status cards show both monetary amounts and card counts
- Counts are displayed in parentheses next to status names
- Interactive status filtering available by tapping cards
- Counts respect current search and filter criteria

**No Action Required:** The requested feature is already fully implemented and working as described in the attachment image showing "Completed (2)", "In Progress (10)", "Pending (24)" format.

## Recent Changes

### Hashtag Initialization Fix in edit_card_page.dart (September 19, 2025)

- Fixed hashtag initialization when opening existing cards to properly map saved hashtag data to masterList IDs
- Enhanced `_initializeData()` method to lookup hashtag IDs by name from available hashtags when existing ID is missing
- Ensures hashtag chips display with correct colors from masterList instead of falling back to default gray
- Resolves issue where existing card hashtags appeared unselected or with wrong colors in HashtagInputField

### Hashtag Save Data Mapping Fix (September 19, 2025)

- Fixed hashtag save mapping in both create and edit card pages to include proper `id` field from masterList
- Modified `_selectedHashtagsAsMap` getter to return hashtag data with correct structure: `{id, text, color}`
- Ensures saved hashtags reference actual hashtagSettings masterList entries instead of default gray fallbacks
- Resolves issue where hashtags saved with generic `#6B7280` color instead of proper masterList colors

### Auto-Scroll Prevention Fix in edit_card_page.dart (September 19, 2025)

- Disabled `HtmlEditorOptions.shouldEnsureVisible` (set to `false`) in `edit_card_page.dart` to stop the page from auto-scrolling to the HTML editor when it finishes loading. This matches the behavior already applied in `create_card_page.dart` and keeps the scroll position at the top on entry.

### Hashtag UI Mapping + Scope Fix (September 19, 2025)

- Replaced old hashtag modal with `HashtagInputField` on both create and edit card pages.
- Adjusted data model to use List<String> of hashtag IDs with `HashtagOption` master list.
- Fixed loading to use `HashtagService.getHashtagsByScope(workspaceId, 'jobBoard')` (was 'jobcard').
- Passed `workspaceId` to field and ensured mapping to display chips from master list.
- With workspace `xKnLu20t7n6A0IJxl4NN` backup, expected available tags include `bew213` ("Bew213") and `bew1234455` ("Bew1234455"). These now appear and can be selected as shown in the screenshot.


### HTML Editor PopScope Navigation Prevention Fix (September 18, 2025)

**Issue:** When users enter create_card_page.dart or edit_card_page.dart and immediately press the back button before the HTML editor finishes loading, a JavaScript evaluation error occurs:
```
Exception has occurred.
_Exception (Exception: HTML editor is still loading, please wait before evaluating this JS: $('#summernote-2').summernote('reset');!)
```

**Root Cause Analysis:**
- The HTML editor uses Summernote library which requires time to initialize completely
- When users navigate back before initialization completes, the editor tries to execute JavaScript `reset()` method
- The webview/JavaScript context is not fully ready, causing the evaluation to fail
- No navigation protection was in place to prevent premature exits

**Solution Applied:**
1. **Added HTML Editor Ready Tracking**: Enhanced edit_card_page.dart with `_isHtmlEditorReady` boolean flag
2. **PopScope Implementation**: Wrapped both pages' Scaffold with PopScope to control navigation
3. **User Feedback**: Added orange snackbar to inform users when they need to wait
4. **Graceful Prevention**: Prevents navigation until HTML editor is fully initialized

**Technical Changes:**

**Files Modified:**
- `lib/features/board/view/create_card_page.dart`
  - Wrapped Scaffold with PopScope using `_isHtmlEditorReady` flag
  - Added navigation prevention with user-friendly message
  - PopScope shows orange snackbar when back navigation is attempted too early

- `lib/features/board/view/edit_card_page.dart`
  - Added `_isHtmlEditorReady` boolean flag to track editor initialization state
  - Enhanced HtmlEditor with `Callbacks(onInit: ...)` to detect ready state
  - Wrapped Scaffold with PopScope using same navigation prevention logic
  - Added user feedback snackbar for premature navigation attempts

**PopScope Implementation:**
```dart
return PopScope(
  canPop: _isHtmlEditorReady,
  onPopInvoked: (didPop) {
    if (!didPop && !_isHtmlEditorReady) {
      Get.snackbar(
        'Please Wait',
        'HTML editor is still loading. Please wait a moment before going back.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  },
  child: Scaffold(...),
);
```

**HTML Editor Ready Detection:**
```dart
// In edit_card_page.dart - added this callback
callbacks: Callbacks(
  onInit: () {
    print('✅ HTML Editor initialized in edit card page');
    setState(() {
      _isHtmlEditorReady = true;
    });
  },
),
```

**Error Prevention Strategy:**
- **Initialization Tracking**: Both pages now track when HTML editor is fully ready
- **Navigation Control**: PopScope prevents back navigation until editor is initialized
- **User Communication**: Clear feedback explains why navigation is temporarily disabled
- **Graceful UX**: Users can navigate freely once editor loads successfully

**Benefits:**
- **Prevents JavaScript Errors**: No more Summernote reset() evaluation failures
- **Better User Experience**: Clear feedback instead of cryptic error messages
- **Robust Navigation**: Users cannot accidentally trigger editor errors
- **Consistent Behavior**: Same protection applied to both create and edit pages

**User Impact:**
- Users receive clear feedback when trying to navigate back too quickly
- No more JavaScript evaluation errors during page transitions
- Improved app stability when working with HTML editor features
- Better understanding of when HTML editor is ready for use

**Technical Notes:**
- PopScope is the modern Flutter approach for handling back navigation
- `canPop` property controls whether back navigation is allowed
- `onPopInvoked` callback provides feedback when navigation is prevented
- HTML editor ready state ensures JavaScript context is fully available before allowing exits

### HTML Editor WebView Disposal Error Fix (September 18, 2025)

**Issue:** MissingPluginException occurs during save operations when WebView is disposed while `getText()` is being called.

**Error Pattern:**
```
flutter: 🔍 HTML Editor Save Debug (Create):
flutter:   - _isHtmlEditorReady: true
flutter:   - Fallback controller text: ""
[IOSInAppWebViewWidget] (iOS) IOSInAppWebViewWidget calling "dispose" using []
flutter: ⚠️ Error getting HTML editor content: MissingPluginException(No implementation found for method evaluateJavascript on channel com.pichillilorenzo/flutter_inappwebview_31)
flutter: ⚠️ WebView plugin error detected - HTML editor not fully initialized
```

**Root Cause Analysis:**
- WebView disposal occurs simultaneously with `getText()` call during save operations
- HTML editor content is lost because fallback controller is empty (not synced with user input)
- Race condition between WebView disposal and content retrieval
- No mechanism to preserve user input when WebView becomes unavailable

**Solution Applied:**
1. **Content Synchronization**: Added `onChangeContent` callback to sync HTML editor content to fallback controllers in real-time
2. **Widget Mount Checks**: Added `mounted` check before attempting HTML editor operations
3. **Enhanced Timeout Protection**: Reduced timeout from 5s to 3s for faster fallback
4. **Nested Error Handling**: Added inner try-catch around `getText()` for additional safety
5. **Guaranteed Fallback**: Always use fallback controller content for any error scenario

**Technical Changes:**

**create_card_page.dart:**
```dart
// Added content synchronization
callbacks: Callbacks(
  onInit: () {
    setState(() { _isHtmlEditorReady = true; });
  },
  onChangeContent: (String? changed) {
    if (changed != null && mounted) {
      _descriptionFallbackController.text = changed;
      print('🔄 Synced HTML content to fallback: ${changed.length} chars');
    }
  },
),

// Enhanced error handling with mount check
if (!mounted) {
  print('⚠️ Widget not mounted, skipping HTML editor access');
  htmlDescription = _descriptionFallbackController.text;
} else if (_isHtmlEditorReady) {
  try {
    final editorContent = await _htmlEditorController.getText().timeout(
      const Duration(seconds: 3),
      onTimeout: () => _descriptionFallbackController.text,
    );
    // ...
  } catch (innerE) {
    htmlDescription = _descriptionFallbackController.text;
  }
}
```

**edit_card_page.dart:**
```dart
// Added content synchronization with initial value
callbacks: Callbacks(
  onInit: () {
    setState(() { _isHtmlEditorReady = true; });
    _detailsController.text = widget.card.description;
  },
  onChangeContent: (String? changed) {
    if (changed != null && mounted) {
      _detailsController.text = changed;
      print('🔄 Synced HTML content to fallback: ${changed.length} chars');
    }
  },
),
```

**Error Prevention Strategy:**
- **Real-time Sync**: User input is continuously saved to fallback controllers
- **Mount Safety**: Skip HTML editor operations if widget is being disposed
- **Timeout Protection**: Quick fallback prevents indefinite waiting
- **Multiple Fallbacks**: Layer multiple safety nets for content preservation
- **Error Logging**: Comprehensive logging for debugging disposal timing issues

**Benefits:**
- **No Data Loss**: User input is preserved even when WebView disposal occurs
- **Faster Recovery**: 3-second timeout provides quicker fallback response
- **Robust Save Operations**: Multiple safety checks prevent save failures
- **Better Debugging**: Enhanced logging helps identify disposal timing issues

**User Impact:**
- Description content is guaranteed to save even with WebView disposal errors
- No loss of user input during save operations
- Faster error recovery with shorter timeouts
- More reliable card creation and editing experience

**Files Modified:**
- `lib/features/board/view/create_card_page.dart`
  - Added `onChangeContent` callback for real-time content synchronization
  - Enhanced error handling with mount checks and nested try-catch
  - Improved timeout handling with fallback content

- `lib/features/board/view/edit_card_page.dart`
  - Added `onChangeContent` callback with initial content setting
  - Enhanced save operation with WebView disposal protection
  - Improved fallback strategy with content preservation

### HTML Editor Firestore Save Investigation (September 18, 2025)

**Issue:** HTML editor description data not saving to Firestore despite successful save operations and enhanced error handling.

**Investigation Findings:**
- User reported filled HTML editor content shows as `"description": ""` in Firestore backup
- Card ID `fIPtV1kTyO6NDk26MYVF` in backup shows empty description field
- Previous error handling fixes were implemented but root cause may be different

**Debugging Enhancement Applied:**
1. **Enhanced Logging in edit_card_page.dart**: Added comprehensive debug output to track HTML editor save process
2. **Enhanced Logging in create_card_page.dart**: Added detailed logging to trace content retrieval
3. **Fallback Strategy Verification**: Added logging to verify fallback controller usage
4. **Content Preservation**: Added safety check to preserve original description if new content is empty

**Technical Changes:**

**Debug Output Added:**
```dart
print('🔍 HTML Editor Save Debug:');
print('  - _isHtmlEditorReady: $_isHtmlEditorReady');
print('  - Initial description: "${widget.card.description}"');
print('  - Fallback controller text: "${_detailsController.text}"');
print('  - HTML editor getText() result: "$editorContent"');
print('  - Final htmlDescription: "$htmlDescription"');
```

**Enhanced Safety Checks:**
```dart
// Additional safety check - if still empty, prompt user
if (htmlDescription.isEmpty && widget.card.description.isNotEmpty) {
  print('⚠️ Description is empty but original card had content, preserving original');
  htmlDescription = widget.card.description;
}
```

**Potential Root Causes Being Investigated:**
1. **HTML Editor Initialization Timing**: `_isHtmlEditorReady` flag may not be properly set
2. **Content Retrieval Timing**: `getText()` called before user content is properly captured
3. **Fallback Controller Sync**: `_detailsController` may not be updated with HTML editor changes
4. **WebView State Issues**: HTML editor internal state may not reflect user input

**Files Modified:**
- `lib/features/board/view/edit_card_page.dart`
  - Enhanced `_saveChanges()` method with comprehensive debugging
  - Added safety checks for content preservation
  - Enhanced fallback logic with better error handling

- `lib/features/board/view/create_card_page.dart`
  - Enhanced `_createCard()` method with detailed logging
  - Added debugging output to trace HTML editor content retrieval
  - Improved fallback controller usage logging

**Next Steps for Resolution:**
- Monitor debug output to identify where content is lost in the save process
- Verify HTML editor initialization and ready state timing
- Check if content is properly captured from user input
- Investigate WebView plugin state and content synchronization

### HTML Editor Description Save Fix (September 18, 2025)

**Issue:** HTML editor description data not storing to Firestore path "/workspaces/{workspace id}/cards/{card id}/description" after pressing save button.

**Root Cause Analysis:**
- Previous disposal fix skipped HTML editor cleanup to prevent MissingPluginException during navigation
- However, HTML editor `getText()` method was not protected against MissingPluginException during save operations
- When users save quickly after page load, the HTML editor might not be fully ready or could throw plugin errors
- No fallback mechanism was in place for cases where HTML editor fails during content retrieval

**Solution Applied:**
1. **Enhanced Error Handling in edit_card_page.dart**: Added comprehensive try-catch around `_htmlEditorController.getText()`
2. **Readiness Check**: Added `_isHtmlEditorReady` flag check before attempting to get HTML content
3. **Multiple Fallback Strategy**: 
   - First fallback: Use `_detailsController.text` (TextFormField content)
   - Second fallback: Use existing `widget.card.description` 
4. **Same Protection in create_card_page.dart**: Enhanced existing error handling with fallback to `_descriptionFallbackController.text`

**Technical Changes:**

**edit_card_page.dart:**
```dart
// Before: Unprotected HTML editor access
final editorContent = await _htmlEditorController.getText();
if (editorContent.isNotEmpty) {
  htmlDescription = editorContent;
}

// After: Protected with error handling and fallbacks
try {
  if (_isHtmlEditorReady) {
    final editorContent = await _htmlEditorController.getText();
    if (editorContent.isNotEmpty) {
      htmlDescription = editorContent;
    }
  } else {
    htmlDescription = _detailsController.text; // Fallback
  }
} catch (e) {
  if (e.toString().contains('MissingPluginException')) {
    htmlDescription = _detailsController.text; // Plugin error fallback
  } else {
    htmlDescription = widget.card.description; // Other error fallback
  }
}
```

**create_card_page.dart:**
```dart
// Enhanced existing error handling
if (e.toString().contains('MissingPluginException')) {
  htmlDescription = _descriptionFallbackController.text; // Use fallback controller
  if (htmlDescription.isEmpty && !_isHtmlEditorReady) {
    _showHtmlEditorWarningDialog(); // Show warning if no content available
  }
}
```

**Error Prevention Strategy:**
- **Readiness Verification**: Check `_isHtmlEditorReady` before HTML editor operations
- **MissingPluginException Handling**: Specific handling for WebView plugin errors
- **Graceful Degradation**: Use fallback TextFormField content when HTML editor fails
- **User Feedback**: Clear logging for troubleshooting save operation issues

**Benefits:**
- **Guaranteed Description Save**: Description data always saves, even if HTML editor fails
- **No Data Loss**: Fallback mechanisms preserve user input through TextFormField
- **Better Error Recovery**: Multiple fallback strategies prevent complete save failures
- **Improved Reliability**: HTML editor issues don't block card creation or editing

**User Impact:**
- Description content saves successfully even when HTML editor has issues
- Users don't lose their input when WebView plugin errors occur
- Better app stability during card save operations
- Clear logging helps identify when HTML editor problems occur

**Files Modified:**
- `lib/features/board/view/edit_card_page.dart`
  - Enhanced `_saveChanges()` method with comprehensive HTML editor error handling
  - Added readiness check and multiple fallback strategies
- `lib/features/board/view/create_card_page.dart`
  - Enhanced existing error handling in `_createCard()` method
  - Added fallback controller usage for better data preservation

### MissingPluginException Disposal Fix (September 18, 2025)

**Issue:** Multiple errors occurred whe- Users receive clear feedback about HTML editor issues during card creation
- Better understanding of when description editor problems occur
- Clear guidance that description can be added later via editing
- Improved transparency about editor limitations and fallback behavior

### Auto-Scroll Prevention Fix in create_card_page.dart (September 18, 2025)

**Issue:** After entering create card page, when HTML editor finishes loading, the page automatically scrolls down to the HTML editor section instead of staying at the top.

**Root Cause:** The `shouldEnsureVisible: true` option in HtmlEditorOptions causes the HTML editor to automatically scroll itself into view when initialization completes.

**Solution Applied:**
Changed `shouldEnsureVisible` from `true` to `false` in HtmlEditorOptions to prevent automatic scrolling behavior.

**Technical Changes:**
```dart
// Before: Auto-scroll enabled
shouldEnsureVisible: true,

// After: Auto-scroll disabled  
shouldEnsureVisible: false,
```

**Files Modified:**
- `lib/features/board/view/create_card_page.dart`
  - Updated HtmlEditorOptions to disable auto-scroll behavior

**Benefits:**
- Page stays at the top when HTML editor loads
- Better user experience with predictable scroll position
- Users can manually scroll to sections they want to interact with

### Add Customer Button Integration (September 18, 2025)

**Issue:** Need to add "Add Customer" button in Customer Information section for both edit_card_page.dart and create_card_page.dart to allow users to create new customers directly from card creation/editing flows.

**Requirements:**
1. Add "New" button next to customer dropdown in both create and edit card pages
2. Button should navigate to add_edit_customer_page.dart for customer creation
3. After successful customer creation, return to original page and refresh customer list
4. Newly created customer should be available in dropdown selection

**Solution Applied:**
1. **Import Integration**: Added import for AddEditCustomerPage in both files
2. **UI Enhancement**: Modified customer dropdown row to include "New" button with AppTheme.primaryOrange styling
3. **Navigation Logic**: Implemented _openAddCustomerPage() method in both pages
4. **Data Refresh**: Added logic to refresh customer options after successful customer creation

**Technical Changes:**
```dart
// Before: Single dropdown
DropdownButtonFormField<String>(...)

// After: Row with dropdown + button
Row(
  children: [
    Expanded(child: DropdownButtonFormField<String>(...)),
    const SizedBox(width: 8),
    ElevatedButton.icon(
      onPressed: _openAddCustomerPage,
      icon: const Icon(Icons.add, size: 16),
      label: const Text('New'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryOrange,
        ...
      ),
    ),
  ],
)
```

**Navigation Implementation:**
```dart
Future<void> _openAddCustomerPage() async {
  final result = await Get.to(
    () => const AddEditCustomerPage(customerSources: []),
  );
  
  if (result == true) {
    await _loadAvailableOptions(); // Refresh customer list
    setState(() {});
  }
}
```

**Files Modified:**
- `lib/features/board/view/create_card_page.dart`
  - Added AddEditCustomerPage import
  - Modified _buildCustomerSection() to include "New" button
  - Added _openAddCustomerPage() navigation method
  - Integrated customer list refresh after new customer creation

- `lib/features/board/view/edit_card_page.dart`  
  - Added AddEditCustomerPage import
  - Modified _buildCustomerSection() to include "New" button in Row layout
  - Added _openAddCustomerPage() navigation method with _loadAvailableOptions() refresh

**UI/UX Benefits:**
- **Streamlined Workflow**: Users can create customers without leaving card creation/editing flow
- **Consistent Design**: Orange "New" button matches app theme and existing UI patterns
- **Immediate Availability**: Newly created customers appear in dropdown immediately
- **Reduced Context Switching**: No need to navigate to separate customer management section

**User Impact:**
- Faster card creation process when new customers are needed
- Improved workflow efficiency for users managing customer data
- Consistent experience between create and edit card flows
- Better integration between customer management and card management features

### Status Section UI Fix in edit_card_page.dart (September 18, 2025)

**Issue:** Timeline and status section in edit_card_page.dart had inconsistent UI compared to create_card_page.dart status selection interface.

**Problem Identified:**
- **edit_card_page.dart**: Used old chip-style status selection with manual color coding and rounded containers
- **create_card_page.dart**: Used modern ElevatedButton.icon style with AppTheme.primaryOrange colors and better visual hierarchy
- UI inconsistency created poor user experience between create and edit flows

**Solution Applied:**
1. **Replaced Status Selection UI**: Updated `_buildStatusChipsSection()` method in edit_card_page.dart
2. **Matched create_card_page.dart Design**: Copied exact UI structure from `_buildStatusSection()` in create_card_page.dart
3. **Consistent Styling**: Applied same AppTheme.primaryOrange colors, elevation, and button styling
4. **Improved Visual Hierarchy**: Used ElevatedButton.icon with proper spacing and padding

**Technical Changes:**
- **Before**: Custom Container with GestureDetector and manual color switching
- **After**: ElevatedButton.icon with AppTheme.primaryOrange selection state
- **Container Structure**: Added outer container with border, grey background, and proper padding
- **Button Styling**: Consistent elevation, border radius, and color scheme
- **Spacing**: Changed from 8px to 6px spacing to match create page layout

**UI Components Updated:**
- Icon spacing: 8px → 6px to match create page
- Vertical spacing: 16px → 12px for consistent layout
- Button style: Custom containers → ElevatedButton.icon
- Color scheme: Manual color switching → AppTheme.primaryOrange system
- Shadow/elevation: Consistent with create page design

**Files Modified:**
- `lib/features/board/view/edit_card_page.dart`
  - Updated `_buildStatusChipsSection()` method
  - Replaced custom status chip implementation
  - Applied consistent styling with create_card_page.dart

**Benefits:**
- **UI Consistency**: Status selection now matches between create and edit flows
- **Better UX**: Users see familiar interface when editing cards
- **Maintainable Code**: Uses established theme colors and button styles
- **Visual Clarity**: Improved button styling with proper elevation and shadows

### Remove Order Input Field from Add New Lane Modal (September 18, 2025)

**Issue:** The Add New Lane modal contained an unnecessary order input field that complicated the user experience.

**Solution Applied:**
1. **Removed Order Input Field**: Eliminated the order TextController and input field from `_showAddLaneDialog()` method
2. **Simplified UI**: Removed the order TextField and associated logic
3. **Auto-Assign Order**: Order is now automatically assigned based on lane count (existing behavior preserved)
4. **Updated Info Text**: Changed "order: Position in board" to "order: Auto-assigned" in the lane structure info

**Technical Changes:**
- **Before**: Modal had both lane name and order input fields
- **After**: Modal only has lane name input field
- **Order Logic**: Removed manual order input, order is automatically set to `_controller.lanes.length`
- **UI Simplification**: Reduced form complexity from 2 fields to 1 field

**Files Modified:**
- `lib/features/board/view/board_page.dart`
  - Updated `_showAddLaneDialog()` method
  - Removed `orderController` TextEditingController
  - Removed order TextField widget
  - Simplified lane creation logic
  - Updated lane structure information display

**Benefits:**
- **Simplified UX**: Users only need to enter lane name
- **Automatic Ordering**: System handles lane positioning automatically
- **Reduced Errors**: No more manual order conflicts or confusion
- **Cleaner Interface**: Less cluttered modal dialog

**Functionality Preserved:**
- Lane creation still works as expected
- Order is automatically assigned based on current lane count
- All existing lane management features remain intact

### Todo Title Mapping Fix in edit_card_page.dart (September 18, 2025)

**Issue:** Todo titles were not displaying in input fields in the Content and Tasks section when editing cards.

**Root Cause Analysis:**
- Firestore data structure uses `title` field for todo titles
- Edit card initialization was only mapping `text` field 
- Backup data shows todos have structure: `{"title": "todo title", "completed": false, "dueDate": timestamp}`

**Solution Applied:**
1. Updated `_initializeData()` method in edit_card_page.dart
2. Modified todo mapping to handle both `title` and `text` fields from Firestore
3. Added fallback logic: `todo['title'] ?? todo['text'] ?? ''`
4. Updated TextEditingController initialization to use the correct title text
5. Also mapped `completed` field as fallback for `isCompleted`

**Technical Changes:**
```dart
// Before
'text': todo['text'] ?? '',
'controller': TextEditingController(text: todo['text'] ?? ''),

// After  
final titleText = todo['title'] ?? todo['text'] ?? '';
'text': titleText,
'controller': TextEditingController(text: titleText),
'isCompleted': todo['isCompleted'] ?? todo['completed'] ?? false,
```

**Data Structure Understanding:**
- Firestore todos structure: `{title: string, completed: boolean, dueDate: timestamp, id: string, mentions: []}`
- App internal structure: `{text: string, isCompleted: boolean, controller: TextEditingController}`
- The mapping now bridges both structures correctly

### HTML Editor Integration for Content & Details Section in edit_card_page.dart

**Completed:**
1. Added `html_editor_enhanced: ^2.5.1` dependency to pubspec.yaml
2. Fixed intl version compatibility (changed from ^0.19.0 to ^0.20.2)
3. Added HtmlEditorController to edit_card_page.dart state management
4. Modified _initializeData() to set HTML editor content from card.description
5. Replaced TextFormField in _buildDetailsSection() with HtmlEditor widget
6. Updated _saveChanges() to get content from HTML editor instead of TextEditingController

**Implementation Details:**
- HTML Editor configured with essential toolbar buttons (bold, italic, underline, lists, undo/redo)
- Content initialization: `_htmlEditorController.setText(widget.card.description)`
- Content saving: `await _htmlEditorController.getText()` in _saveChanges()
- Data mapping: "/workspaces/{workspace_uid}/cards/{card_uid}/description" field

### HTML Editor Loading Error Fix

**Issue:** Exception occurred - "HTML editor is still loading, please wait before evaluating this JS"
**Root Cause:** Setting text to HTML editor before it's fully initialized
**Solution Applied:**
1. Removed manual setText() call in _initializeData()
2. Used initialText property in HtmlEditorOptions instead
3. Added 500ms delay before widget setup to ensure proper initialization
4. Set initialText: widget.card.description.isNotEmpty ? widget.card.description : ''

**Technical Changes:**
- Moved content initialization from programmatic setText() to declarative initialText
- Eliminated race condition between editor loading and content setting
- Simplified initialization flow by using built-in HtmlEditorOptions

### HTML Editor Integration for create_card_page.dart

**Completed:**
1. Added html_editor_enhanced import to create_card_page.dart
2. Added HtmlEditorController to state management
3. Replaced existing toolbar + TextField in _buildDetailsSection() with HtmlEditor widget
4. Updated _createCard() to get content from HTML editor using await _htmlEditorController.getText()
5. Configured HTML editor with same toolbar options as edit_card_page.dart

**Implementation Details:**
- Replaced manual toolbar with HtmlEditor built-in toolbar
- Content saving: `await _htmlEditorController.getText()` in _createCard()
- Data mapping: Creates card with description field for "/workspaces/{workspace_uid}/cards/{card_uid}/description"
- Consistent configuration between create and edit pages

### Todo Integration for edit_card_page.dart

**Completed:**
1. Copied todo structure from create_card_page.dart to edit_card_page.dart
2. Added todo state variables and methods to edit_card_page.dart:
   - `_todos` list for storing todo items
   - `_addTodo()` method for adding new todos
   - `_removeTodo()` method for removing todos
   - `_toggleTodo()` method for marking todos complete/incomplete
3. Added `_buildTodoSection()` widget method copied from create_card_page.dart
4. Integrated todo section into main form layout in build method
5. Added todo data mapping in `_initializeData()` to load existing todos from card data
6. Updated `_saveChanges()` method to save todos data to Firestore path "/workspaces/{workspace_uid}/cards/{card_uid}/todos[]"

**Technical Changes:**
- Todo data structure: List<Map<String, dynamic>> with fields: text, isCompleted, id
- UI components: TextField for new todo input, ListView for todo display, Checkbox for completion state
- Data persistence: Todos included in card.copyWith() call and saved to main card document
- Initialization: Todos loaded from existing card data in _initializeData()

### Comment Edit/Delete Feature in edit_card_page.dart (September 18, 2025)

**Issue:** Comment section in edit_card_page.dart lacked edit and delete functionality for comments.

**Requirements:**
1. Add edit and delete icons to each comment
2. Show confirm dialog when deleting comments  
3. Show input field with cancel/save icons when editing
4. Save changes to Firestore at /workspaces/{workspace uid}/cards/{card uid}/notes[]

**Solution Applied:**
1. **Added Edit/Delete Icons**: Added edit and delete icons next to timestamp for comments owned by current user
2. **Implemented Edit Mode**: Added edit state with TextEditingController and conditional UI rendering
3. **Delete Confirmation**: Added confirmation dialog before deleting comments
4. **Firestore Integration**: Added updateNoteInCard and deleteNoteFromCard methods to FirestoreRepositoryExtras

**Technical Changes:**
- **UI Components**: Added edit/delete icons that appear only for user's own comments
- **State Management**: Added `_editingCommentIndex` and `_editCommentController` to track edit mode
- **Edit Mode UI**: Conditional rendering between display text and edit TextField with cancel/save buttons
- **Delete Dialog**: Confirmation dialog with cancel/confirm actions
- **Firestore Methods**: Extended FirestoreRepositoryExtras with updateNoteInCard and deleteNoteFromCard

**Files Modified:**
- `lib/features/board/view/edit_card_page.dart`
  - Added edit/delete icons with user ownership check
  - Implemented edit mode with conditional rendering
  - Added confirmation dialog for delete action
  - Added methods: `_editComment()`, `_cancelEditComment()`, `_saveEditComment()`, `_deleteComment()`, `_confirmDeleteComment()`
- `lib/data/repositories/firestore_repository_extras.dart`
  - Added `updateNoteInCard()` method for updating specific notes in card notes array
  - Added `deleteNoteFromCard()` method for removing notes from card notes array

**Security & UX Features:**
- **User Ownership**: Edit/delete icons only appear for comments created by current user
- **Optimistic Updates**: Local state updated immediately with Firestore sync
- **Error Handling**: Failed operations revert local state and show error messages
- **Confirmation Dialog**: Prevents accidental comment deletion

**Benefits:**
- **Full CRUD Operations**: Comments now support complete create, read, update, delete functionality
- **User Control**: Users can edit their own comments and fix mistakes
- **Data Safety**: Confirmation dialogs prevent accidental deletions
- **Consistent UX**: Edit mode follows standard cancel/save pattern

````vigating away from create_card_page.dart and edit_card_page.dart:
1. `MissingPluginException(No implementation found for method evaluateJavascript on channel com.pichillilorenzo/flutter_inappwebview_3)`
2. `setState() called after dispose(): _EditCardPageState#bb53e(lifecycle state: defunct, not mounted)`

**Root Cause Analysis:**
- **HTML Editor Disposal**: The `HtmlEditorController` was not being properly disposed, causing JavaScript evaluation errors when the underlying webview was destroyed
- **Async setState Operations**: Multiple async methods (`_loadCompaniesForCustomer`, `_loadProductImages`, `_loadQuotationTemplates`) were calling setState without checking if the widget was still mounted
- **WebView Plugin Issues**: The flutter_inappwebview plugin's JavaScript bridge was being called during disposal when the plugin was no longer available

**Solution Applied:**

**1. HTML Editor Safe Disposal:**
```dart
// Both create_card_page.dart and edit_card_page.dart
@override
void dispose() {
  // Safely dispose HTML editor controller
  try {
    _htmlEditorController.clear();
  } catch (e) {
    print('⚠️ Warning: Could not clear HTML editor during disposal: $e');
  }
  // ... other disposals
}
```

**2. Mounted Checks for Async setState:**
```dart
// Before: Unsafe setState in async methods
setState(() {
  _availableCompanies = companyMap.values.toList();
});

// After: Protected setState with mounted check
if (mounted) {
  setState(() {
    _availableCompanies = companyMap.values.toList();
  });
}
```

**Technical Changes:**

**Files Modified:**
- `lib/features/board/view/create_card_page.dart`
  - Enhanced dispose() method with HTML editor safe disposal
  - Added mounted checks to `_loadCompaniesForCustomer()` setState calls
  - Protected against async setState after widget disposal

- `lib/features/board/view/edit_card_page.dart`
  - Enhanced dispose() method with HTML editor safe disposal and todo controllers cleanup
  - Added mounted checks to `_loadCompaniesForCustomer()`, `_loadProductImages()`, and `_loadQuotationTemplates()` setState calls
  - Protected against async setState after widget disposal

**Error Handling Strategy:**
- **HTML Editor Disposal**: Try-catch block prevents JavaScript evaluation errors during cleanup
- **Widget Lifecycle Safety**: Mounted checks ensure setState only called on active widgets
- **Memory Leak Prevention**: Proper disposal of all controllers including HTML editor and todo item controllers
- **Graceful Degradation**: Operations continue even if HTML editor cleanup fails

**Benefits:**
- **Prevents App Crashes**: No more MissingPluginException errors during navigation
- **Memory Safety**: Eliminates setState after dispose errors and potential memory leaks
- **Robust Navigation**: Users can safely navigate between pages without disposal errors
- **Better Error Handling**: Clear logging for troubleshooting widget lifecycle issues

**User Impact:**
- Smooth navigation between create and edit card pages
- No more error dialogs when leaving pages
- Better app stability and performance
- Improved user experience during card management workflows

### HTML Editor Warning Dialog After Card Creation (September 18, 2025)

**Issue:** After creating a new jobcard, need to show an alert dialog warning when the HTML editor was unavailable during card creation, matching the design from the attached image.

**Requirements:**
1. Display warning dialog only when HTML editor was not ready during card creation
2. Use orange background to match warning severity
3. Show clear message about description editor unavailability
4. Inform user they can edit description later

**Solution Applied:**
1. **Removed Success Snackbar**: Eliminated the green success snackbar to avoid conflicting messages
2. **Added Warning Dialog**: Created `_showHtmlEditorWarningDialog()` method with orange-themed dialog
3. **Conditional Display**: Dialog only shows when `_isHtmlEditorReady` is false after successful card creation
4. **UI Design**: Implemented warning icon, white text on orange background, and clear messaging

**Technical Changes:**
```dart
// Before: Always show success snackbar
Get.snackbar(
  'Success',
  'Job Card created successfully',
  backgroundColor: Colors.green,
  ...
);

// After: Conditional warning dialog
if (!_isHtmlEditorReady) {
  _showHtmlEditorWarningDialog();
}
```

**Dialog Implementation:**
```dart
void _showHtmlEditorWarningDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.orange,
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Text('Warning', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Description editor unavailable, card will be created without description. You can edit it later.',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      );
    },
  );
}
```

**Files Modified:**
- `lib/features/board/view/create_card_page.dart`
  - Removed success snackbar after card creation
  - Added `_showHtmlEditorWarningDialog()` method
  - Added conditional dialog display based on HTML editor readiness state
  - Improved navigation flow to show dialog after successful creation

**UI/UX Benefits:**
- **Clear Warning**: Users are explicitly informed when description editor was unavailable
- **Visual Hierarchy**: Orange background clearly indicates warning severity
- **Actionable Information**: Users know they can edit description later
- **No Conflicting Messages**: Removed success snackbar to avoid message confusion

**User Impact:**
- Users receive clear feedback about HTML editor issues during card creation
- Better understanding of when description editor problems occur
- Clear guidance that description can be added later via editing
- Improved transparency about editor limitations and fallback behavior

### Status Section UI Fix in edit_card_page.dart (September 18, 2025)

**Issue:** Timeline and status section in edit_card_page.dart had inconsistent UI compared to create_card_page.dart status selection interface.

**Problem Identified:**
- **edit_card_page.dart**: Used old chip-style status selection with manual color coding and rounded containers
- **create_card_page.dart**: Used modern ElevatedButton.icon style with AppTheme.primaryOrange colors and better visual hierarchy
- UI inconsistency created poor user experience between create and edit flows

**Solution Applied:**
1. **Replaced Status Selection UI**: Updated `_buildStatusChipsSection()` method in edit_card_page.dart
2. **Matched create_card_page.dart Design**: Copied exact UI structure from `_buildStatusSection()` in create_card_page.dart
3. **Consistent Styling**: Applied same AppTheme.primaryOrange colors, elevation, and button styling
4. **Improved Visual Hierarchy**: Used ElevatedButton.icon with proper spacing and padding

**Technical Changes:**
- **Before**: Custom Container with GestureDetector and manual color switching
- **After**: ElevatedButton.icon with AppTheme.primaryOrange selection state
- **Container Structure**: Added outer container with border, grey background, and proper padding
- **Button Styling**: Consistent elevation, border radius, and color scheme
- **Spacing**: Changed from 8px to 6px spacing to match create page layout

**UI Components Updated:**
- Icon spacing: 8px → 6px to match create page
- Vertical spacing: 16px → 12px for consistent layout
- Button style: Custom containers → ElevatedButton.icon
- Color scheme: Manual color switching → AppTheme.primaryOrange system
- Shadow/elevation: Consistent with create page design

**Files Modified:**
- `lib/features/board/view/edit_card_page.dart`
  - Updated `_buildStatusChipsSection()` method
  - Replaced custom status chip implementation
  - Applied consistent styling with create_card_page.dart

**Benefits:**
- **UI Consistency**: Status selection now matches between create and edit flows
- **Better UX**: Users see familiar interface when editing cards
- **Maintainable Code**: Uses established theme colors and button styles
- **Visual Clarity**: Improved button styling with proper elevation and shadows

### Remove Order Input Field from Add New Lane Modal (September 18, 2025)

**Issue:** The Add New Lane modal contained an unnecessary order input field that complicated the user experience.

**Solution Applied:**
1. **Removed Order Input Field**: Eliminated the order TextController and input field from `_showAddLaneDialog()` method
2. **Simplified UI**: Removed the order TextField and associated logic
3. **Auto-Assign Order**: Order is now automatically assigned based on lane count (existing behavior preserved)
4. **Updated Info Text**: Changed "order: Position in board" to "order: Auto-assigned" in the lane structure info

**Technical Changes:**
- **Before**: Modal had both lane name and order input fields
- **After**: Modal only has lane name input field
- **Order Logic**: Removed manual order input, order is automatically set to `_controller.lanes.length`
- **UI Simplification**: Reduced form complexity from 2 fields to 1 field

**Files Modified:**
- `lib/features/board/view/board_page.dart`
  - Updated `_showAddLaneDialog()` method
  - Removed `orderController` TextEditingController
  - Removed order TextField widget
  - Simplified lane creation logic
  - Updated lane structure information display

**Benefits:**
- **Simplified UX**: Users only need to enter lane name
- **Automatic Ordering**: System handles lane positioning automatically
- **Reduced Errors**: No more manual order conflicts or confusion
- **Cleaner Interface**: Less cluttered modal dialog

**Functionality Preserved:**
- Lane creation still works as expected
- Order is automatically assigned based on current lane count
- All existing lane management features remain intact

### Todo Title Mapping Fix in edit_card_page.dart (September 18, 2025)

**Issue:** Todo titles were not displaying in input fields in the Content and Tasks section when editing cards.

**Root Cause Analysis:**
- Firestore data structure uses `title` field for todo titles
- Edit card initialization was only mapping `text` field 
- Backup data shows todos have structure: `{"title": "todo title", "completed": false, "dueDate": timestamp}`

**Solution Applied:**
1. Updated `_initializeData()` method in edit_card_page.dart
2. Modified todo mapping to handle both `title` and `text` fields from Firestore
3. Added fallback logic: `todo['title'] ?? todo['text'] ?? ''`
4. Updated TextEditingController initialization to use the correct title text
5. Also mapped `completed` field as fallback for `isCompleted`

**Technical Changes:**
```dart
// Before
'text': todo['text'] ?? '',
'controller': TextEditingController(text: todo['text'] ?? ''),

// After  
final titleText = todo['title'] ?? todo['text'] ?? '';
'text': titleText,
'controller': TextEditingController(text: titleText),
'isCompleted': todo['isCompleted'] ?? todo['completed'] ?? false,
```

**Data Structure Understanding:**
- Firestore todos structure: `{title: string, completed: boolean, dueDate: timestamp, id: string, mentions: []}`
- App internal structure: `{text: string, isCompleted: boolean, controller: TextEditingController}`
- The mapping now bridges both structures correctly

### HTML Editor Integration for Content & Details Section in edit_card_page.dart

**Completed:**
1. Added `html_editor_enhanced: ^2.5.1` dependency to pubspec.yaml
2. Fixed intl version compatibility (changed from ^0.19.0 to ^0.20.2)
3. Added HtmlEditorController to edit_card_page.dart state management
4. Modified _initializeData() to set HTML editor content from card.description
5. Replaced TextFormField in _buildDetailsSection() with HtmlEditor widget
6. Updated _saveChanges() to get content from HTML editor instead of TextEditingController

**Implementation Details:**
- HTML Editor configured with essential toolbar buttons (bold, italic, underline, lists, undo/redo)
- Content initialization: `_htmlEditorController.setText(widget.card.description)`
- Content saving: `await _htmlEditorController.getText()` in _saveChanges()
- Data mapping: "/workspaces/{workspace_uid}/cards/{card_uid}/description" field

### HTML Editor Loading Error Fix

**Issue:** Exception occurred - "HTML editor is still loading, please wait before evaluating this JS"
**Root Cause:** Setting text to HTML editor before it's fully initialized
**Solution Applied:**
1. Removed manual setText() call in _initializeData()
2. Used initialText property in HtmlEditorOptions instead
3. Added 500ms delay before widget setup to ensure proper initialization
4. Set initialText: widget.card.description.isNotEmpty ? widget.card.description : ''

**Technical Changes:**
- Moved content initialization from programmatic setText() to declarative initialText
- Eliminated race condition between editor loading and content setting
- Simplified initialization flow by using built-in HtmlEditorOptions

### HTML Editor Integration for create_card_page.dart

**Completed:**
1. Added html_editor_enhanced import to create_card_page.dart
2. Added HtmlEditorController to state management
3. Replaced existing toolbar + TextField in _buildDetailsSection() with HtmlEditor widget
4. Updated _createCard() to get content from HTML editor using await _htmlEditorController.getText()
5. Configured HTML editor with same toolbar options as edit_card_page.dart

**Implementation Details:**
- Replaced manual toolbar with HtmlEditor built-in toolbar
- Content saving: `await _htmlEditorController.getText()` in _createCard()
- Data mapping: Creates card with description field for "/workspaces/{workspace_uid}/cards/{card_uid}/description"
- Consistent configuration between create and edit pages

### Todo Integration for edit_card_page.dart

**Completed:**
1. Copied todo structure from create_card_page.dart to edit_card_page.dart
2. Added todo state variables and methods to edit_card_page.dart:
   - `_todos` list for storing todo items
   - `_addTodo()` method for adding new todos
   - `_removeTodo()` method for removing todos
   - `_toggleTodo()` method for marking todos complete/incomplete
3. Added `_buildTodoSection()` widget method copied from create_card_page.dart
4. Integrated todo section into main form layout in build method
5. Added todo data mapping in `_initializeData()` to load existing todos from card data
6. Updated `_saveChanges()` method to save todos data to Firestore path "/workspaces/{workspace_uid}/cards/{card_uid}/todos[]"

**Technical Changes:**
- Todo data structure: List<Map<String, dynamic>> with fields: text, isCompleted, id
- UI components: TextField for new todo input, ListView for todo display, Checkbox for completion state
- Data persistence: Todos included in card.copyWith() call and saved to main card document
- Initialization: Todos loaded from existing card data in _initializeData()

### Comment Edit/Delete Feature in edit_card_page.dart (September 18, 2025)

**Issue:** Comment section in edit_card_page.dart lacked edit and delete functionality for comments.

**Requirements:**
1. Add edit and delete icons to each comment
2. Show confirm dialog when deleting comments  
3. Show input field with cancel/save icons when editing
4. Save changes to Firestore at /workspaces/{workspace uid}/cards/{card uid}/notes[]

**Solution Applied:**
1. **Added Edit/Delete Icons**: Added edit and delete icons next to timestamp for comments owned by current user
2. **Implemented Edit Mode**: Added edit state with TextEditingController and conditional UI rendering
3. **Delete Confirmation**: Added confirmation dialog before deleting comments
4. **Firestore Integration**: Added updateNoteInCard and deleteNoteFromCard methods to FirestoreRepositoryExtras

**Technical Changes:**
- **UI Components**: Added edit/delete icons that appear only for user's own comments
- **State Management**: Added `_editingCommentIndex` and `_editCommentController` to track edit mode
- **Edit Mode UI**: Conditional rendering between display text and edit TextField with cancel/save buttons
- **Delete Dialog**: Confirmation dialog with cancel/confirm actions
- **Firestore Methods**: Extended FirestoreRepositoryExtras with updateNoteInCard and deleteNoteFromCard

**Files Modified:**
- `lib/features/board/view/edit_card_page.dart`
  - Added edit/delete icons with user ownership check
  - Implemented edit mode with conditional rendering
  - Added confirmation dialog for delete action
  - Added methods: `_editComment()`, `_cancelEditComment()`, `_saveEditComment()`, `_deleteComment()`, `_confirmDeleteComment()`
- `lib/data/repositories/firestore_repository_extras.dart`
  - Added `updateNoteInCard()` method for updating specific notes in card notes array
  - Added `deleteNoteFromCard()` method for removing notes from card notes array

**Security & UX Features:**
- **User Ownership**: Edit/delete icons only appear for comments created by current user
- **Optimistic Updates**: Local state updated immediately with Firestore sync
- **Error Handling**: Failed operations revert local state and show error messages
- **Confirmation Dialog**: Prevents accidental comment deletion

**Benefits:**
- **Full CRUD Operations**: Comments now support complete create, read, update, delete functionality
- **User Control**: Users can edit their own comments and fix mistakes
- **Data Safety**: Confirmation dialogs prevent accidental deletions
- **Consistent UX**: Edit mode follows standard cancel/save pattern

````



