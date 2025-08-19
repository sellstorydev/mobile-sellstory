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

### Planned Features
- 🔄 Drag & drop lane reordering
- 🔄 Edit lane functionality
- 🔄 Delete lane functionality
- 🔄 Edit card functionality
- 🔄 Delete card functionality
- 🔄 Card filtering and search
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
