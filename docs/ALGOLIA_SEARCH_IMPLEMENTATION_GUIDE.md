# Algolia Search Implementation Guide

## Overview

This guide documents the implementation pattern for converting features from local/real-time search to **Algolia-only search**. This pattern was successfully implemented in the Companies and Customers features to provide better search performance and consistency.

## Problem Statement

### Before Implementation
- **Real-time filtering**: Search results updated while typing, causing performance issues
- **Mixed search logic**: Combination of local filtering and Algolia search was confusing
- **Inconsistent UX**: Different search behaviors across features
- **Resource intensive**: Constant filtering during typing consumed resources

### After Implementation
- **Explicit search**: Search only triggers when user explicitly requests it
- **Algolia-only**: Single source of truth for search functionality
- **Consistent UX**: Same search pattern across all features
- **Better performance**: No unnecessary operations while typing

## Implementation Pattern

### 🔧 Controller Changes

#### 1. Remove Automatic Search Triggers
```dart
// ❌ OLD: Auto-triggering search while typing
ever(searchQuery, (_) => _filterCompanies()); // Remove this

// ✅ NEW: Only reset when data changes
ever(companies, (_) => _resetFilteredCompanies());
```

#### 2. Update onSearchChanged Method
```dart
void onSearchChanged(String query) {
  // Only update the search query for display purposes in UI
  // No search or filtering should happen while typing
  searchQuery.value = query;
  
  // If query becomes empty, immediately reset to show all items
  if (query.trim().isEmpty) {
    isSearching.value = false;
    filteredItems.value = allItems.toList();
  }
  // Note: For non-empty queries, do nothing - wait for user to click search button
}
```

#### 3. Implement Algolia-Only Search Method
```dart
/// Trigger Algolia search (only when search button is clicked)
Future<void> triggerAlgoliaSearch([String? query]) async {
  final searchText = query ?? searchController.text.trim();
  
  if (searchText.isEmpty) {
    // If query is empty, reset to show all items
    isSearching.value = false;
    filteredItems.value = allItems.toList();
    return;
  }
  
  isSearching.value = true;
  _searchWithAlgolia(searchText);
}
```

#### 4. Implement Algolia Search Logic
```dart
Future<void> _searchWithAlgolia(String query) async {
  try {
    if (currentWorkspaceId.value.isEmpty) {
      isSearching.value = false;
      return;
    }
    
    final searchStream = AlgoliaSearchService.searchItems(
      query: query,
      workspaceId: currentWorkspaceId.value,
      hitsPerPage: 50,
    );
    
    // Listen to search results
    searchStream.listen(
      (response) {
        final hits = response.hits;
        final algoliaResults = <ItemType>[];
        
        // Convert Algolia results to Item objects
        for (final hit in hits) {
          try {
            // Find the item in our local list by ID
            final itemId = hit['objectID'] as String?;
            if (itemId != null) {
              final item = allItems.firstWhere(
                (i) => i.id == itemId,
                orElse: () => throw StateError('Item not found'),
              );
              algoliaResults.add(item);
            }
          } catch (e) {
            print('⚠️ Failed to convert Algolia hit to Item: $e');
          }
        }
        
        // Update the filtered items with search results
        filteredItems.value = algoliaResults;
        isSearching.value = false;
        print('🔍 Algolia search results: ${algoliaResults.length} items found');
      },
      onError: (error) {
        print('❌ Algolia search error: $error');
        // Don't fallback to local search - just show empty results
        isSearching.value = false;
        filteredItems.value = [];
      },
    );
    
  } catch (e) {
    print('❌ Failed to search with Algolia: $e');
    isSearching.value = false;
    // Show empty results on search error instead of fallback
    filteredItems.value = [];
  }
}
```

#### 5. Remove Local Filtering Methods
```dart
// ❌ REMOVE: Local filtering methods
void _filterItems() { ... } // Delete this method completely

// ❌ REMOVE: setSearchQuery method if it exists
void setSearchQuery(String query) { ... } // Delete this method
```

#### 6. Update Clear Search Method
```dart
void clearSearch() {
  searchQuery.value = '';
  searchController.clear();
  isSearching.value = false;
  filteredItems.value = allItems.toList(); // Direct assignment instead of calling removed filter method
}
```

#### 7. Add Reset Method for Data Changes
```dart
/// Reset filtered items to show all items (used when items list changes)
void _resetFilteredItems() {
  // Only reset if we're not currently searching with Algolia
  if (!isSearching.value) {
    filteredItems.value = allItems.toList();
  }
}
```

### 🎨 UI Changes

#### 1. Add Search Button Trigger
```dart
// Search button that triggers Algolia search
Material(
  color: AppTheme.primaryOrange,
  borderRadius: BorderRadius.circular(10),
  child: InkWell(
    borderRadius: BorderRadius.circular(10),
    onTap: () => _triggerSearch(), // Triggers Algolia search
    child: const SizedBox(
      height: 44,
      width: 44,
      child: Icon(Icons.search, color: Colors.white),
    ),
  ),
),
```

#### 2. Add Enter Key Support
```dart
TextField(
  controller: _controller.searchController,
  focusNode: _searchFocus,
  onChanged: _controller.onSearchChanged,
  onSubmitted: (_) => _triggerSearch(), // Trigger search when Enter is pressed
  textInputAction: TextInputAction.search,
  // ... other properties
)
```

#### 3. Add Searching State UI
```dart
Widget _buildItemList() {
  return Obx(() {
    if (_controller.isLoading.value) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryOrange),
      );
    }

    if (_controller.errorMessage.value.isNotEmpty) {
      return _ErrorState(/* ... */);
    }

    // Show searching state when Algolia search is in progress
    if (_controller.isSearching.value) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryOrange),
            SizedBox(height: 16),
            Text(
              'กำลังค้นหา...', // Customize message per feature
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // Rest of the list building logic...
  });
}
```

#### 4. Update Search Trigger Function
```dart
void _triggerSearch() {
  final query = _controller.searchController.text.trim();
  // Always trigger Algolia search when button is clicked, even if empty
  _controller.triggerAlgoliaSearch(query);
  _searchFocus.unfocus();
}
```

## Implementation Checklist

### ✅ Controller Updates
- [ ] Remove `ever(searchQuery, (_) => _filterItems())` listener
- [ ] Update `onSearchChanged()` to only update display text
- [ ] Implement `triggerAlgoliaSearch()` method
- [ ] Implement `_searchWithAlgolia()` method with proper error handling
- [ ] Remove local filtering methods (`_filterItems`, `setSearchQuery`)
- [ ] Update `clearSearch()` method
- [ ] Add `_resetFilteredItems()` method
- [ ] Update `ever(items, (_) => _resetFilteredItems())` listener

### ✅ UI Updates
- [ ] Add search button with `_triggerSearch()` callback
- [ ] Add `onSubmitted: (_) => _triggerSearch()` to TextField
- [ ] Add searching state UI in list builder
- [ ] Update `_triggerSearch()` to always call Algolia search
- [ ] Ensure clear button calls `controller.clearSearch()`

### ✅ Testing
- [ ] Verify typing in search bar doesn't change list
- [ ] Verify search button triggers Algolia search
- [ ] Verify Enter key triggers search
- [ ] Verify clear button resets to all items
- [ ] Verify searching state shows loading UI
- [ ] Verify error handling shows empty results (no local fallback)

## Key Principles

### 🎯 Search Behavior
1. **Typing = No Action**: Only updates display text, no filtering
2. **Explicit Triggers**: Search only happens on button click or Enter key
3. **Algolia Only**: No local filtering or fallback to local search
4. **Error Graceful**: Show empty results on error, don't fallback

### 🎨 User Experience
1. **Visual Feedback**: Show loading state during search
2. **Clear Actions**: Obvious search and clear buttons
3. **Keyboard Support**: Enter key triggers search
4. **Consistent Messages**: Standardized loading and error messages

### 🔧 Code Structure
1. **Single Responsibility**: Each method has one clear purpose
2. **Error Handling**: Graceful error handling without fallbacks
3. **State Management**: Clear separation of loading, searching, and error states
4. **Performance**: No unnecessary operations while typing

## Benefits Achieved

### 🚀 Performance
- No real-time filtering during typing
- Reduced API calls and local processing
- Better app responsiveness

### 🎯 User Experience
- Predictable search behavior
- Clear visual feedback during search
- Consistent experience across features

### 🛠️ Maintainability
- Single search implementation pattern
- Clear separation of concerns
- Easier debugging and testing

### 📊 Scalability
- Algolia handles complex search requirements
- Easy to add new search features
- Better search analytics and insights

## Usage Example

When implementing this pattern for a new feature (e.g., Products):

1. **Copy the controller pattern** from `companies_controller.dart`
2. **Replace entity types** (Company → Product)
3. **Update Algolia service calls** (`searchCompanies` → `searchProducts`)
4. **Copy UI pattern** from `company_center_page.dart`
5. **Update search messages** ("กำลังค้นหาบริษัท" → "กำลังค้นหาสินค้า")
6. **Test thoroughly** using the checklist above

## Files Modified

### Companies Feature
- `lib/features/companies/controller/companies_controller.dart`
- `lib/features/companies/view/company_center_page.dart`

### Customers Feature
- `lib/features/customers/controller/customers_controller.dart`
- `lib/features/customers/view/customers_page.dart`

## Next Steps

This pattern can be applied to any feature that requires search functionality:
- Products/Inventory
- Orders/Invoices
- Documents
- Contacts
- And any other searchable entities

Each implementation should follow this exact pattern for consistency and maintainability.