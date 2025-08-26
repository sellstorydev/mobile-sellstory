# Board Feature - Kanban Job Card Dashboard

## Overview
This feature implements a Kanban-style job card dashboard with horizontal scrolling lanes and vertical scrolling cards within each lane. The implementation follows the MVP + GetX architecture pattern.

## Architecture

### MVP Pattern
- **View**: `BoardPage` - UI layer that displays the board
- **Presenter**: `BoardPresenter` - Business logic orchestrator
- **Controller**: `BoardController` - GetX controller managing reactive state

### GetX Integration
- Dependency injection through `Get.put()` and `Get.find()`
- Reactive state management with `RxList<Lane>` and `RxBool`
- Automatic UI updates through `Obx()` widgets

## Drag & Drop Implementation

### Current Implementation
The current version uses `DragAndDropLists` with horizontal scrolling for lanes and vertical scrolling for cards within each lane. This provides full drag and drop functionality for the Kanban board.

### Auto-Scroll Enhancement
The board now includes custom auto-scroll functionality that triggers when dragging cards near the edges of the viewport:

#### Auto-Scroll Features
- **Edge Detection**: Triggers when pointer is within 56px of any edge
- **Smooth Scrolling**: Uses velocity-based scrolling with configurable speed
- **Dual Axis Support**: Handles both horizontal (lane scrolling) and vertical (card scrolling)
- **Configurable**: Customizable edge extent, velocity, and timing

#### Auto-Scroll Configuration
```dart
const DragAutoScrollConfig(
  edgeExtent: 56.0,        // px from edge to trigger scroll
  velocityScalar: 120.0,   // scroll speed multiplier
  maxStep: 48.0,           // max pixels per scroll step
  tick: Duration(milliseconds: 16), // ~60fps scrolling
)
```

### Drag & Drop Integration
The drag & drop functionality is implemented using the `drag_and_drop_lists` package with the following handlers:

#### DragAndDropLists Handlers (Implemented)
```dart
onItemReorder: (int oldItemIndex, int oldListIndex, int newItemIndex, int newListIndex) {
  // Maps to: presenter.onMoveCard()
  // Handles moving cards between lanes and reordering within lanes
}

onListReorder: (int oldListIndex, int newListIndex) {
  // Maps to: presenter.onReorderLanes()
  // Handles lane reordering (future enhancement)
}
```

## Data Flow

1. **Load**: `Controller.load()` → `Presenter.load()` → `Repository.getLanes()` → Update UI
2. **Move Card**: `Controller.onMoveCard()` → `Presenter.onMoveCard()` → `UseCase.execute()` → Optimistic UI update → Persist to repository
3. **Add Card**: `Controller.onAddCard()` → `Presenter.onAddCard()` → `UseCase.execute()` → Optimistic UI update → Persist to repository
4. **Add Lane**: `Controller.onAddLane()` → `Presenter.onAddLane()` → `UseCase.execute()` → Optimistic UI update → Persist to repository

## Search Implementation

### Search Features
The board now includes comprehensive search functionality that allows users to find cards and lanes efficiently:

#### Search Capabilities
- **Multi-field Search**: Searches across card title, description, custom ID, customer, assignee, status, and lane title
- **Real-time Filtering**: Immediate results as user types
- **Smart Lane Inclusion**: Shows lanes with matching cards OR lanes whose title matches the search
- **Case-insensitive**: Search is not case-sensitive for better user experience
- **Visual Indicators**: Clear search state indicators and result counts

#### Search UI Components
- **Search Button**: Located in AppBar, toggles between search and clear modes
- **Search Dialog**: Modal dialog with search input and helpful information
- **Search Indicator**: Shows current search query with option to clear
- **Empty States**: Different messages for "no results" vs "no lanes"

#### Search Flow
1. **Activate Search**: Click search icon in AppBar to open search dialog
2. **Enter Query**: Type search terms in the input field
3. **View Results**: See filtered lanes and cards instantly
4. **Clear Search**: Use "ล้าง" button or search icon to return to full view

### Search Technical Details
```dart
// Search state management
final RxString searchQuery = ''.obs;
final RxBool isSearching = false.obs;
final RxList<Lane> filteredLanes = <Lane>[].obs;

// Search methods
void updateSearchQuery(String query)
void clearSearch()
void _performSearch(String query)
bool _cardMatchesSearch(JobCard card, String searchLower)
```

## Filter Implementation

### Filter Features
The board now includes assignee filtering functionality that allows users to view cards assigned to specific people:

#### Filter Capabilities
- **Assignee Selection**: Choose from a list of available assignees in the system
- **Visual Indicators**: Clear filter state indicators with assignee name
- **Card Count Display**: Shows how many cards each assignee has
- **Combined with Search**: Works together with search functionality
- **Easy Clear**: Quick access to clear filter and return to full view

#### Filter UI Components
- **Filter Button**: Located in AppBar, toggles between filter and clear modes
- **Filter Dialog**: Modal dialog showing list of available assignees
- **Filter Indicator**: Shows current filter with assignee name and clear option
- **Empty States**: Specific messages for "no results for this assignee"

#### Filter Flow
1. **Activate Filter**: Click filter icon in AppBar to open assignee selection
2. **Select Assignee**: Choose from list of available assignees with card counts
3. **View Results**: See only cards assigned to selected person
4. **Clear Filter**: Use "ล้าง" button or filter icon to return to full view

### Filter Technical Details
```dart
// Filter state management
final RxString selectedAssignee = ''.obs;
final RxBool isFiltering = false.obs;
final RxList<String> availableAssignees = <String>[].obs;

// Filter methods
void updateAssigneeFilter(String assigneeId)
void clearFilter()
void _performFilter()
void _updateAvailableAssignees()
```

## Features

### Current Features
- ✅ Horizontal scrolling lanes
- ✅ Vertical scrolling cards within lanes
- ✅ Lane headers with title, card count, and total amount
- ✅ Job card tiles with badges, assignee, due date, and amount
- ✅ Add new lanes
- ✅ Add new cards to specific lanes
- ✅ Card details dialog
- ✅ Lane menu (placeholder for edit/delete)
- ✅ Loading and error states
- ✅ Optimistic UI updates
- ✅ **Drag & drop card reordering within lanes**
- ✅ **Drag & drop card movement between lanes**
- ✅ **Auto-scroll during drag operations** (edge-triggered scrolling)
- ✅ **Search functionality** (card and lane filtering with real-time results)
- ✅ **Filter by assignee** (filter cards by assigned person with UI selection)

### Planned Features
- 🔄 Drag & drop lane reordering
- 🔄 Edit lane functionality
- 🔄 Delete lane functionality
- 🔄 Edit card functionality
- 🔄 Delete card functionality
- ✅ Card filtering and search (COMPLETED)
- 🔄 Lane collapsing/expanding

## Dependencies

### Core Dependencies
- `get: ^4.6.6` - State management and dependency injection
- `flutter` - UI framework

### Drag & Drop Dependencies
- `drag_and_drop_lists: ^0.4.2` - Drag & drop functionality for cards and lanes

## Usage

The board feature is automatically integrated into the main app shell as the first tab (Job Card). Users can:

1. View job cards organized in lanes (New, Doing, Review, Done)
2. Add new lanes using the "+" button in the app bar
3. Add new cards using the floating action button or lane-specific "+" buttons
4. View card details by tapping on cards
5. Access lane options via the menu button in lane headers

## Testing

The feature includes unit tests for:
- Use cases (move card, reorder card, add card, add lane)
- Presenter business logic
- Repository operations
- Auto-scroll configuration

Run tests with: `flutter test test/features/board/`

Can read databas sturcture at firestore/backup-2025-08-25T02-47-08.json

For better answer, when you done all task note everything you want to file SUMMARY.md for better answer my prompt