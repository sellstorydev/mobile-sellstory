# Document System Development Summary

## Recent Developments (January 27, 2025)

### 1. Company Auto-fill Functionality Enhancement (Latest)
- **Issue**: When customers work for companies, user had to manually enter company data into customer fields
- **Solution**: Enhanced `AddEditDocumentController` with automatic company data population:
  - `_loadAndFillCompanyData()`: Fetches company data from Firestore and auto-fills customer fields
  - `_clearCompanyAutoFilledData()`: Clears auto-filled data when switching to individual selection
  - Enhanced `onCompanyChanged()`: Triggers auto-fill when company selected, clearing when individual selected
  - **Auto-filled Fields**:
    - Address: Combines `addressLine1 + subdistrict + district + province + country`
    - Postal Code: From company's `postalCode` field
    - National ID: From company's `taxId` field
    - Email: First email from company's `emails` array
    - Phone: First phone from company's `phones` array
- **Database Source**: `workspaces/{workspaceId}/companies/{companyId}`
- **Impact**: Reduces manual data entry, ensures consistency between company and customer data, improves user experience

### 2. Default Seller Assignment for New Documents (Latest)
- **Issue**: When creating new documents, users had to manually select a seller from the dropdown
- **Solution**: Enhanced `AddEditDocumentController` with automatic default seller assignment:
  - `_setDefaultSellerAsCurrentUser()`: Auto-selects current authenticated user as default seller
  - Called during `_initializeUserAndWorkspace()` after loading workspace members
  - Only applies to new documents (documentId == null), preserves existing seller for edits
  - Validates current user is a workspace member before assignment
- **Impact**: Improved user experience by eliminating redundant seller selection for most common use case

### 3. Payment Method Persistence Fix for Document Editing (Latest)
- **Issue**: When editing existing documents, payment method was not being loaded/assigned from database
- **Solution**: Enhanced `_loadDocumentBasicInfo()` method in `AddEditDocumentController`:
  - Improved payment method loading logic with better type handling
  - Added validation for payment method data existence
  - Enhanced logging for debugging payment method assignment
  - Preserves payment method data during document updates
- **Impact**: Fixed data loss issue, ensures payment method information persists correctly when editing documents

### 4. End-of-Bill Discount Validation Enhancement
- **Issue**: End-of-bill discount input lacked proper validation, allowing negative values and amounts exceeding subtotal
- **Solution**: Enhanced `AddEditDocumentController` with comprehensive discount validation:
  - `validateEndOfBillDiscount()`: Validates discount input against bounds (0 ≤ discount ≤ subtotal)
  - `getEndOfBillDiscountErrorMessage()`: Provides user-friendly error messages in Thai
  - Updated `endOfBillDiscountAmount` getter: Uses `clamp()` to enforce bounds automatically
  - Enhanced UI: Shows helper text with maximum amount, displays validation errors in real-time
  - **Save Validation**: Added end-of-bill discount validation during document save process
  - **Section Header Error Indicator**: Summary section header shows error state when discount validation fails
- **Validation Rules**:
  - Minimum: 0 (cannot be negative)
  - Maximum: Current subtotal amount
  - Shows "สูงสุด: ฿XX.XX" helper text
  - Real-time error messages in Thai
  - Blocks document save when discount is invalid
  - Visual error indicators on collapsed summary section header
- **Impact**: Prevents invalid discount amounts, improves data integrity, enhances user experience with clear feedback at input and save levels

### 5. Customer Company Selection Enhancement
- **Issue**: Customer company dropdown lacked a default "individual" option and required manual selection
- **Solution**: Enhanced customer company selection with automatic default selection:
  - Added translation keys: `select_individual` ("Select Individual" / "บุคคลธรรมดา")
  - Modified `onCustomerChanged()`: Auto-selects 'individual' when customer is chosen
  - Updated dropdown UI: Always shows when customer selected, includes individual option first
  - Backward compatible: Existing company selections remain functional
- **Impact**: Improved UX with sensible default selection for individual customers vs. companies

### 6. Auto-fill Default Notes Enhancement
- **Issue**: When creating new documents, the notes field was empty instead of using workspace-configured default notes
- **Solution**: Enhanced `AddEditDocumentController` with automatic default notes loading:
  - `loadDefaultNotes()`: Fetches workspace `docSettings.defaultNotes` and auto-fills based on document type
  - Document type mapping: QT→quotation, INV→invoice, RT→receipt notes
  - Only applies to new documents (documentId == null), preserves existing notes for edits
- **Database Source**: `workspaces/{workspaceId}/companyProfile.docSettings.defaultNotes`
- **Impact**: Improved user experience with pre-filled professional default terms/notes for each document type

### 7. Navigation Error Fix - GetX Controller Conflicts
- **Issue**: "AddEditDocumentController not found" error when navigating to edit page after creating documents
- **Solution**: Replaced `Get.to()` with `Navigator.push()` for all navigation to `AddEditDocumentPage` with existing document IDs
- **Files Updated**:
  - `AddEditDocumentController.saveDocument()`: Fixed post-creation navigation to edit page
  - `InvoiceListController.viewInvoice()`: Fixed viewing existing invoices
  - `QuotationsListController.viewQuotation()` & `reviseQuotationToInvoice()`: Fixed quotation operations
  - `InvoiceCreationController` (3 methods): Fixed all invoice creation scenarios
- **Impact**: Resolved GetX dependency injection conflicts, enabling smooth navigation throughout document workflows

### 8. Template-Aware Quantity Validation Enhancement
- **Issue**: Template quantity validation not working properly for documents with predefined quantity columns and remainingQuantity limits
- **Solution**: Enhanced `add_edit_document_controller.dart` with comprehensive template-aware validation methods:
  - `hasTemplateQuantityColumn`: Detects if template has predefined quantity fields
  - `validateQuantityForTemplate()`: Validates quantity input against template constraints
  - `getQuantityErrorMessage()`: Provides user-friendly error messages
- **Impact**: All document types (QT, INV, RT) now support template-based quantity validation with remainingQuantity constraints

### 9. Database-Level Type Filtering Implementation  
- **Issue**: Document pagination queries lacked proper `.where('type', isEqualTo: 'XX')` conditions
- **Solution**: Enhanced `firestore_repository.dart` with documentType parameter for database-level filtering
- **Controllers Updated**:
  - `quotations_list_controller.dart`: Added `documentType: 'QT'` filtering
  - `invoice_list_controller.dart`: Added `documentType: 'INV'` filtering  
  - `receipt_list_controller.dart`: Added `documentType: 'RT'` filtering
- **Impact**: Improved performance and accuracy of document list pagination

### 10. Invoice Creation Item Selection Fix
- **Issue**: When selecting items for "สร้างใบแจ้งหนี้ (แบ่งจ่ายแบบรายการ)", items were incorrectly setting quantity to 0 instead of minimum 1
- **Solution**: Fixed `invoice_creation_controller.dart` methods:
  - `toggleItemSelection()`: Now sets minimum quantity to 1 when item is selected, uses original quantity as default
  - `toggleAllItems()`: Ensures all selected items get appropriate default quantities (minimum 1, preferably original quantity)
  - `updateItemQuantity()`: Prevents setting quantity to 0 for selected items; unselects item if quantity is set to 0
- **Impact**: Improved user experience for item-based invoice creation with logical quantity defaults

## Technical Architecture

### Auto-fill and Data Integration System
- **Company Data Integration**: Seamless fetching from `workspaces/{workspaceId}/companies/{companyId}` collection
- **Cross-Collection Data Mapping**: Intelligent mapping between company fields and customer form fields
- **Data Consistency**: Ensures customer information matches company records when business relationship exists
- **Flexible Data Handling**: Supports both individual customers and company-associated customers
- **Error Handling**: Graceful fallback when company data is incomplete or unavailable

### Smart Default Assignment System
- **Context-Aware Defaults**: Different default behaviors for new vs. existing documents
- **User-Centric Design**: Auto-selects current user as seller for most common use case
- **Workspace Integration**: Validates user permissions and workspace membership before assignment
- **Data Preservation**: Maintains existing selections when editing documents

### Data Persistence and Loading Enhancement
- **Robust Data Loading**: Enhanced payment method and document data loading with comprehensive error handling
- **Type Safety**: Improved type checking and validation for document field assignment
- **State Management**: Consistent data state across document creation and editing workflows
- **Debugging Support**: Comprehensive logging for troubleshooting data assignment issues

### Customer Data Management Enhancement
- Smart default selection reduces user friction when creating documents for individual customers
- Maintains flexibility for business customers with company association options
- Translation system ensures proper localization for all customer types

### Document Creation UX Enhancement
- Default notes system provides professional templates automatically based on document type
- Workspace-level configuration allows customization of default terms for different document types
- Seamless integration with existing document creation workflow without disrupting edit functionality

### Navigation System Stability
- Resolved GetX controller dependency conflicts with standard Flutter navigation patterns
- Each `AddEditDocumentPage` instance manages its own controller lifecycle independently
- Consistent navigation behavior across all document operations (create, view, edit, convert)

### Template System Integration
- Templates now support smart field detection and validation
- Quantity constraints apply across all document types when template configuration requires it
- Enhanced error messaging provides clear feedback about quantity limits

### Database Optimization
- Type-specific document queries at database level reduce client-side filtering overhead
- Consistent pagination behavior across all document list controllers
- Improved query performance for large document collections

### Invoice Creation Workflow
- Robust item selection logic ensures sensible quantity defaults
- Maximum quantity validation prevents exceeding available inventory
- Intuitive quantity management prevents user confusion with 0-quantity selections

## Files Modified
- `lib/features/document/controller/add_edit_document_controller.dart`
- `lib/features/document/view/add_edit_document_page.dart`
- `lib/core/i18n/app_translations.dart`
- `lib/features/document/controller/invoice_creation_controller.dart`
- `lib/features/document/controller/invoice_list_controller.dart`
- `lib/features/document/controller/quotations_list_controller.dart`
- `lib/data/repositories/firestore_repository.dart`
- `lib/features/document/controller/quotations_list_controller.dart`
- `lib/features/document/controller/invoice_list_controller.dart`
- `lib/features/document/controller/receipt_list_controller.dart`

## Testing Status
- All changes compile successfully with Flutter analyze
- Template-aware validation system operational
- Database filtering implementation complete
- Item selection logic validated for edge cases

## Next Priorities
- User acceptance testing for template quantity validation
- Performance monitoring for enhanced database queries
- Cross-template compatibility validation for various field configurations

## Previous Development History

## Current Implementation Status

### Fixed Pagination Type Filtering Issue (Critical Fix - September 10, 2025)
- **CRITICAL FIX APPLIED**: Database-level type filtering for document pagination
- **Problem Resolved**: 
  - Pagination queries were fetching all document types and filtering client-side
  - This caused data inconsistencies (8 documents showing as 6 after filtering)
  - Inefficient data transfer and processing
- **Solution**:
  - Enhanced `FirestoreRepository.getDocumentsPaginated()` with `documentType` parameter
  - Added `.where('type', isEqualTo: documentType)` filter at database level
  - Updated all document list controllers to pass specific type filters:
    - QuotationsListController: `documentType: 'QT'`
    - InvoiceListController: `documentType: 'INV'`
    - ReceiptListController: `documentType: 'RT'`
  - Removed redundant client-side filtering
- **Benefits**: Improved performance, data consistency, and accurate pagination counts

### Quotation List Auto-refresh on Invoice Creation (UX Enhancement - September 10, 2025)
- **UX ENHANCEMENT ADDED**: Automatic quotation list refresh when invoice is successfully created
- **Problem Addressed**: 
  - After creating an invoice from a quotation, the quotation status was updated in database but not reflected in the UI
  - Users had to manually refresh the quotations list to see the updated "INVOICED" status
  - Created inconsistency between database state and UI display
- **Key Changes Made**:
  - Added import for `QuotationsListController` in `InvoiceCreationController`
  - Enhanced all three invoice creation methods with automatic list refresh
  - Added graceful error handling for cases when QuotationsListController is not available
- **Technical Implementation**:
  - Added `Get.find<QuotationsListController>()` to locate existing controller instance
  - Called `refreshData()` method to reload quotations from database
  - Wrapped in try-catch to handle cases where controller might not be initialized
  - Added specific logging for each invoice type (full, installment, item-based)
- **Affected Methods**:
  - `createFullInvoice()`: Refreshes list after full invoice creation
  - `createInstallmentInvoice()`: Refreshes list after installment invoice creation  
  - `createItemBasedInvoice()`: Refreshes list after item-based invoice creation
- **User Experience**: 
  - Quotation list now immediately shows updated "INVOICED" status after invoice creation
  - No manual refresh required - seamless workflow from quotation to invoice
  - Maintains UI consistency with database state
- **Error Handling**: Non-critical operation - if refresh fails, user can still navigate and list will refresh when they return to quotations page
- **Business Logic**: Ensures real-time status tracking without requiring full page reloads or manual user actions

### WHT Default Data Loading Implementation (Data Loading Enhancement - September 10, 2025)
- **DATA LOADING ENHANCEMENT**: Automatic WHT state determination based on `withholdingTaxPercentage` field when editing documents
- **Smart Logic Implemented**:
  - Primary Check: Examines `withholdingTaxPercentage` field value
  - If percentage > 0: WHT automatically enabled
  - If percentage = 0 or null: WHT disabled  
  - Fallback: Uses existing `isWhtEnabled` boolean flag for backward compatibility
- **File Modified**: `lib/features/document/controller/add_edit_document_controller.dart`
- **Technical Implementation**:
  - Type-safe parsing supporting both numeric and string values
  - Graceful fallback for legacy documents without percentage data
  - Maintains existing functionality while adding intelligent defaults
- **User Experience**: WHT checkbox automatically reflects correct state when editing documents with tax data
- **Business Logic**: 
  - WHT Enabled: When `withholdingTaxPercentage` > 0
  - WHT Disabled: When `withholdingTaxPercentage` == 0 or null
  - Backward Compatible: Falls back to `isWhtEnabled` flag when percentage unavailable

### WHT Data Duplication Fix for Invoice Creation (Critical Fix - September 10, 2025)
- **CRITICAL BUG FIXED**: Withholding Tax (WHT) data was not being properly duplicated when creating invoices from quotations
- **Root Cause Analysis**: 
  - Invoice creation was copying quotation data but not explicitly ensuring WHT fields were preserved
  - While general data copying occurred, specific tax fields needed explicit duplication for data integrity
  - Missing WHT data could lead to incorrect tax calculations in invoices
- **Key Changes Made**:
  - Enhanced `_createBaseInvoiceData()` method to explicitly copy all WHT-related fields
  - Added explicit duplication of `isWhtEnabled`, `withholdingTaxPercentage`, and `whtAmount`
  - Added explicit duplication of VAT fields for consistency: `isVatEnabled`, `vatPercentage`, `vatAmount`
  - Added `netTotal` field duplication to preserve original quotation calculations
- **Technical Implementation**:
  - WHT Fields: `isWhtEnabled`, `withholdingTaxPercentage`, `whtAmount`
  - VAT Fields: `isVatEnabled`, `vatPercentage`, `vatAmount` 
  - Net Total: `netTotal` with fallback to `grandTotal`
  - All fields use safe fallback values (false for booleans, 0.0 for numbers)
- **Data Integrity**: 
  - Ensures all tax settings from quotations are properly inherited by invoices
  - Maintains consistency between quotation and invoice tax calculations
  - Prevents loss of critical financial data during document conversion
- **Business Logic**: All three invoice types (full, installment, item-based) now properly inherit complete tax configuration from original quotations
- **Validation**: All invoice creation methods continue to work correctly with explicit tax data duplication

### Discount Input Fix for Item-based Invoices (Bug Fix - September 10, 2025)
- **CRITICAL BUG FIXED**: Item-based invoice discount input was incorrectly limited by quotation discount amount
- **Root Cause Analysis**: 
  - When quotations had no discount (discount = 0 or null), the discount input was limited to 0
  - Logic was checking quotation['discount'] as maximum allowed discount instead of allowing flexible discount up to subtotal
  - UI was showing quotation discount limit instead of actual subtotal limit
- **Key Changes Made**:
  - Updated `calculateItemBasedDiscount()` method to use `itemBasedSubtotal.value` as maximum discount limit
  - Removed dependency on quotation discount for validation logic
  - Updated UI to always show maximum discount as current subtotal amount
  - Added proper validation for negative discounts and amounts exceeding subtotal
- **Technical Implementation**:
  - Maximum discount allowed: current subtotal amount (not quotation discount)
  - Validation: discountInput >= 0 && discountInput <= itemBasedSubtotal.value
  - Automatic correction when exceeding limits with user feedback
  - Real-time maximum discount display updates with subtotal changes
- **UI Enhancements**:
  - Removed conditional display of maximum discount based on quotation
  - Always shows "สูงสุด ฿X.XX" where X.XX is current subtotal
  - Dynamic updates as user selects/deselects items
- **User Experience**: Users can now apply discounts to item-based invoices regardless of original quotation discount settings
- **Business Logic**: Maintains flexibility while preventing discount amounts from exceeding the actual invoice subtotal

### Quotation Status Update on Invoice Creation (Feature Enhancement - September 9, 2025)
- **NEW FEATURE ADDED**: Automatic quotation status update to "INVOICED" when invoice is successfully created
- **Feature Description**: 
  - When any type of invoice is successfully created from a quotation, the original quotation's status is automatically updated to "INVOICED"
  - This provides clear tracking of which quotations have been converted to invoices
  - Status update happens for all three invoice types: Full, Installment, and Item-based
- **Technical Implementation**:
  - Added `_updateQuotationStatus(String newStatus)` helper method in InvoiceCreationController
  - Method safely updates quotation status using FirestoreRepository.updateDocument()
  - Updates quotation fields: status, updatedAt, updatedBy
  - Non-blocking implementation - if status update fails, invoice creation still succeeds
  - Added status update call to all three invoice creation methods after successful invoice creation
- **Error Handling**:
  - Graceful error handling - status update failures don't affect invoice creation
  - Console logging for debugging and tracking
  - Validates workspace ID and quotation ID before attempting update
- **User Experience**: 
  - Users can now easily track which quotations have been invoiced
  - Quotation list will show "INVOICED" status for converted quotations
  - Clear workflow progression from quotation to invoice
- **Business Logic**: Maintains data consistency by automatically tracking the quotation-to-invoice conversion process

### Enhanced Save/Create Success Handling (UX Enhancement - September 17, 2025)

**Enhancement Details**: Improved user feedback and navigation flow when saving or creating documents with success dialogs and intelligent navigation.

**File Updated**: `lib/features/document/controller/add_edit_document_controller.dart`

**Changes Made**:

1. **Enhanced Success Dialog**:
   - **Replaced Snackbar** with professional success dialog featuring green checkmark icon
   - **Multi-language Support**: All dialog text uses translation system (.tr)
   - **Document-specific Icons**: Visual document representation in dialog
   - **Rich Content Layout**: Structured dialog with title, message, and styled document information
   - **Styled Success Card**: Green-themed container showing document type and number

2. **Intelligent Navigation Logic**:
   - **Create Flow**: After creating new document → Show success dialog → Navigate to edit page of newly created document
   - **Update Flow**: After updating existing document → Show success dialog → Stay on current edit page
   - **Smooth Transitions**: Added 300ms delay for better visual flow between navigation steps
   - **Error Handling**: Fallback navigation if document creation fails

3. **Translation Keys Added**:
   - **English**:
     - `'document_created_successfully': 'Document created successfully'`
     - `'document_updated_successfully': 'Document updated successfully'`
     - `'quotation': 'Quotation'`, `'invoice': 'Invoice'`, `'receipt': 'Receipt'`, `'document': 'Document'`
   - **Thai**:
     - `'document_created_successfully': 'สร้างเอกสารเรียบร้อยแล้ว'`
     - `'document_updated_successfully': 'อัปเดตเอกสารเรียบร้อยแล้ว'`
     - `'quotation': 'ใบเสนอราคา'`, `'invoice': 'ใบแจ้งหนี้'`, `'receipt': 'ใบเสร็จรับเงิน'`, `'document': 'เอกสาร'`

4. **Technical Implementation**:
   - **Success Dialog**: Modal dialog with barrierDismissible: false for controlled dismissal
   - **Navigation Flow**: Proper async/await handling for sequential navigation steps
   - **List Refresh**: Automatic refresh of appropriate list controller after successful operations
   - **Error Boundaries**: Graceful handling of navigation failures with fallback behavior

**User Experience Benefits**:
- **Clear Success Feedback**: Professional dialog provides clear confirmation of successful operations
- **Seamless Workflow**: Create → Edit flow allows immediate editing of newly created documents
- **Visual Consistency**: Green-themed success styling matches app design language
- **Intuitive Navigation**: Users automatically land on edit page after creating new documents
- **Multilingual Support**: Success messages properly localized for all supported languages

**Business Logic**:
- **Create Documents**: Success creates new document and opens edit mode for immediate modifications
- **Update Documents**: Success keeps user on same page for continued editing
- **List Synchronization**: Automatic refresh ensures list views show latest document states
- **Error Recovery**: Robust fallback navigation maintains usable application state

### Search Functionality and Translation in Product Selection Dialog (Enhancement - September 17, 2025)

**Enhancement Details**: Fixed search functionality and translated hardcoded Thai text in the product selection dialog for document creation.

**File Updated**: `lib/features/document/view/add_edit_document_page.dart`

**Changes Made**:

1. **Search Functionality Implementation**:
   - **Fixed Non-functional Search**: Replaced TODO comment with actual search implementation
   - **Search State Management**: Added `searchQuery` variable to track search input
   - **Real-time Filtering**: Products filter dynamically as user types
   - **Multi-field Search**: Searches across product name, SKU, and description fields
   - **Case-insensitive Search**: All searches converted to lowercase for better matching

2. **Translation System Integration**:
   - **Dialog Title**: Changed from hardcoded 'เลือกสินค้าจากฐานข้อมูล' to `'select_products_from_database'.tr`
   - **Search Placeholder**: Changed from hardcoded 'ค้นหาสินค้า...' to `'search_products'.tr`
   - **Error Messages**: Updated snackbar messages to use translation keys
   - **Action Buttons**: Changed 'เพิ่มสินค้า' to `'add_products'.tr`

3. **Translation Keys Added**:
   - **English (en_US)**:
     - `'warning': 'Warning'`
     - `'please_select_at_least_one_product': 'Please select at least one product'`
     - `'add_products': 'Add Products'`
   - **Thai (th)**:
     - `'warning': 'คำเตือน'`
     - `'please_select_at_least_one_product': 'กรุณาเลือกสินค้าอย่างน้อย 1 รายการ'`
     - `'add_products': 'เพิ่มสินค้า'`

**Technical Implementation**:
- **Search Algorithm**: Uses `String.contains()` with lowercase conversion for efficient searching
- **State Management**: Proper StatefulBuilder implementation for real-time UI updates
- **Performance**: Filtering happens in UI layer without backend calls
- **User Experience**: Instant search results with no loading delays

**Benefits**:
- **Working Search**: Users can now actually search and filter products effectively
- **Multilingual Support**: All text properly translated for English and Thai users
- **Better UX**: Real-time search results improve product selection efficiency
- **Maintainability**: All UI text centralized in translation system

### Invoice Quantity Validation (Security Enhancement - September 9, 2025)
- **SECURITY FEATURE ADDED**: Maximum quantity validation for item-based invoice creation
- **Feature Description**: 
  - Prevents users from entering quantities exceeding the original quotation amounts
  - Real-time validation with automatic correction and user feedback
  - Visual indicators showing maximum available quantities
- **Key Components**:
  - Enhanced `updateItemQuantity()` with comprehensive validation logic
  - Automatic quantity correction when exceeding maximum limits
  - User-friendly Thai warning messages via Get.snackbar()
  - Helper text showing maximum quantities in TextField inputs
- **Validation Rules**:
  - No negative quantities allowed (auto-corrected to 0)
  - No quantities exceeding original quotation amounts (auto-corrected to maximum)
  - Real-time validation as user types in quantity fields
  - Visual feedback through snackbar warnings
- **UI Enhancements**:
  - Added "สูงสุด: X" helper text below each quantity input field
  - Clear indication of quantity limits for each item
  - Consistent styling with app theme
- **Technical Implementation**:
  - Enhanced `updateItemQuantity()`, `toggleAllItems()`, and `toggleItemSelection()` methods
  - Proper TextEditingController synchronization with validation
  - State management updates after validation corrections
- **User Experience**: Users receive immediate feedback when attempting to exceed quantity limits, with automatic correction and clear visual guidance
- **Data Integrity**: Ensures invoice quantities never exceed original quotation amounts, maintaining business logic consistency

### Item-based Invoice Discount Feature (Enhancement - September 9, 2025)
- **NEW FEATURE ADDED**: Added end-of-bill discount input for Item-based Invoice creation (สร้างใบแจ้งหนี้ แบ่งจ่ายแบบรายการ)
- **Feature Description**: 
  - Added discount input field "ส่วนลดท้ายบิลสำหรับงวดนี้" in item selection dialog
  - Real-time calculation showing subtotal, discount amount, and final total
  - Visual calculation summary with color-coded amounts
- **Key Components Added**:
  - `itemBasedDiscountController` - TextEditingController for discount input
  - `itemBasedSubtotal`, `itemBasedDiscountAmount`, `itemBasedAfterDiscount` - Observable variables for calculations
  - `calculateItemBasedDiscount()` - Method to calculate discount and final totals
  - `_calculateItemBasedTotals()` - Method to recalculate all totals when items change
- **UI Enhancements**:
  - Added calculation section in item selection dialog showing:
    - Subtotal from selected items
    - Discount input field with ฿ prefix
    - Discount amount display (if applied)
    - Final total after discount in highlighted color
  - Real-time updates when items are selected/deselected or quantities change
- **Technical Implementation**:
  - Enhanced `createItemBasedInvoice()` to include discount in invoice data
  - Set `isEndOfBillDiscountEnabled = true` when discount is applied
  - Proper calculation: grandTotal = subtotal - discount, netTotal = grandTotal
  - Automatic recalculation when item selection changes
- **User Experience**: Users can now apply end-of-bill discounts to item-based invoices with real-time calculation preview before creating the invoice
- **Data Integrity**: Discount is properly saved to invoice document and calculations are accurate

### Invoice Creation Default Settings Fix (Critical Fix - September 9, 2025)
- **CRITICAL ISSUE RESOLVED**: Fixed invoice creation to start with disabled VAT and discount settings instead of inheriting from quotation
- **Root Cause Analysis**: 
  - When creating invoices from quotations, all settings (including VAT and discounts) were being copied directly
  - This caused new invoices to inherit tax and discount settings from the original quotation
  - Invoices should start with clean state for user to configure as needed
- **Key Changes Made**:
  - Modified `_createBaseInvoiceData()` method to reset tax and discount settings
  - Set `isVatEnabled = false`, `vatAmount = 0.0` for all new invoices
  - Set `isWhtEnabled = false`, `whtAmount = 0.0` for withholding tax
  - Set `isEndOfBillDiscountEnabled = false`, `discount = 0.0` for discounts
  - Updated total calculations to reflect no tax/discount state
- **Technical Implementation**:
  - Full Invoice: Uses base method with proper total recalculation
  - Installment Invoice: Explicitly sets VAT to 0 and calculates net amounts
  - Item-based Invoice: Removes VAT inheritance and calculates totals without tax
  - All invoice types now start with subtotal = grandTotal = netTotal (no tax/discount)
- **User Experience**: New invoices created from quotations now start with disabled VAT and discount settings, allowing users to configure tax and discounts as needed for the specific invoice
- **Data Integrity**: Maintains proper totals calculation while ensuring clean starting state for new invoices
- **CRITICAL ISSUE RESOLVED**: Fixed controller key duplication where multiple template fields with same ID caused controller sharing
- **Root Cause Analysis**: 
  - Template fields could have duplicate IDs across different field types
  - Using fieldId directly as controller key caused multiple fields to share the same TextEditingController
  - This led to synchronized field updates when editing one product field affected all products
- **Strategic Solution Implemented**:
  - **Standard Fields**: Keep using standard names (name, quantity, unit, pricePerUnit, description, discount) for validation compatibility
  - **Custom Fields**: Use field index prefix 'field_${i}_${fieldName}' for custom fields to ensure uniqueness
  - **User Input Fields**: Use field index prefix 'field_${i}_${fieldId}' to prevent ID duplication
  - **Template-specific Fields**: Apply smart prefixing only where duplication risk exists
- **Technical Implementation**:
  - Modified controller key generation logic in `_buildDynamicProductFields()`
  - Added `_extractFieldName()` helper method to parse actual field names from prefixed keys
  - Maintained backward compatibility with validation methods that expect standard field names
  - Applied prefixing selectively to avoid breaking existing functionality
- **Key Benefits**:
  - Prevents controller sharing between different template fields
  - Maintains validation method compatibility
  - Reduces memory overhead by not prefixing all fields unnecessarily
  - Ensures each product field gets a unique TextEditingController instance
- **Controller Key Strategy**:
  - `product_field` with standard sourceField: Use standard names (e.g., 'name', 'pricePerUnit')
  - `product_field` with customFields: Use prefixed names (e.g., 'field_0_customDescription')
  - `predefined` fields: Use standard names (e.g., 'quantity', 'unit')
  - `user_input` fields: Use prefixed names (e.g., 'field_1_userNote')
  - Unknown field types: Use prefixed names (e.g., 'field_2_unknownField')
- **User Experience**: Now editing product 17's custom fields won't affect other products' fields, while standard fields remain fully functional

### Edit Quotation Product Loading Fix (Completed - September 9, 2025)
- **Problem Solved**: Fixed issue where product section data doesn't load when editing quotations
- **Root Cause Analysis**: 
  - Template loading race condition where products load before template is fully processed
  - Controller key mismatch between `_initializeProductControllers` (using index) and `getProductController` (using product ID)
  - Missing fallback handling when template loading fails in edit mode
- **Key Changes Made**:
  - Enhanced `_loadDocumentProducts` method with delayed initialization and fallback to default fields
  - Improved `_initializeProductControllers` with better field mapping and debug logging
  - Fixed `getProductController` method with robust fallback mechanisms and auto-creation of missing controllers
  - Added proper handling for custom fields and template-specific field types
  - Used product ID as primary key for controller storage to match retrieval logic
- **Technical Implementation**:
  - Added 100ms delay in product loading to ensure template processing completion
  - Enhanced field mapping logic to handle `sourceField`, `predefinedField`, and custom fields properly
  - Implemented three-tier fallback for controller retrieval: product ID → index → auto-create
  - Added comprehensive logging for debugging controller initialization
  - Maintained backward compatibility with existing product data structures
- **User Experience**: Edit quotation now properly loads and displays all product data including custom fields from templates

### Invoice Creation Options Implementation (Completed - September 9, 2025)
- **New Feature**: Replaced simple "สร้างใบแจ้งหนี้" with comprehensive options page
- **Key Changes Made**:
  - Created `InvoiceCreationOptionsPage` with 3 invoice creation options
  - Created `InvoiceCreationController` to handle all invoice creation logic
  - Updated quotations list page to navigate to options instead of direct creation
- **Three Invoice Creation Options**:
  1. **Full Invoice (ยืนยันการสร้างใบแจ้งหนี้เต็มจำนวน)**: Creates complete invoice with all quotation data
  2. **Installment Invoice (แบ่งจ่ายตามงวด)**: 
     - Radio buttons for percent(%) or amount(บาท) calculation
     - Real-time calculation showing net amount after 3% withholding tax
     - Creates single line item "Partial Payment for Quotation {docNo}"
  3. **Item-based Invoice (แบ่งจ่ายแบบรายการ)**:
     - Checkbox list of all quotation items
     - Editable quantity (max = original quantity)
     - Creates invoice with selected items only
- **Technical Implementation**:
  - All options duplicate quotation data and set type='INV', status='DRAFT'
  - Auto-generates INV document numbers using ID generation service
  - Sets notes to "Invoice for Quotation {Quotation DocNo}"
  - Adds relatedDocuments reference linking back to quotation
  - Creates proper activity logs for audit trail
- **User Experience**: Clean interface with clear option descriptions and real-time calculations

### List Refresh Implementation (Completed - September 8, 2025)
- **Problem Solved**: Fixed issue where data is updated but list views aren't refreshed
- **Root Cause**: List pages were using `Get.off()` creating new controller instances without refreshing existing data
- **Key Changes Made**:
  - Updated all three list pages (Quotations, Invoices, Receipts) from StatelessWidget to StatefulWidget 
  - Added WidgetsBindingObserver for app lifecycle management
  - Implemented pull-to-refresh functionality with RefreshIndicator using AppTheme.primaryOrange
  - Added automatic refresh when app returns to foreground via didChangeAppLifecycleState
  - Updated AddEditDocumentController to handle different document types (QT, INV, RT)
  - Fixed document type handling in ID generation (quotation, invoice, receipt types)
  - Changed navigation from Get.off() to Get.back() to preserve existing controller instances
  - Added _refreshListController() method to automatically refresh appropriate list after saving
  - Updated success messages to display correct document type names in Thai language
  - Removed unused imports and methods to clean up code
- **Technical Implementation**:
  - Each list page now implements didChangeAppLifecycleState(AppLifecycleState.resumed)
  - RefreshIndicator wraps the NotificationListener for scroll-based pagination
  - Controller refresh is triggered immediately after successful document save
  - Document type passed from page to controller for proper handling
- **User Experience**: Users now see updated data immediately after creating/editing documents, and can pull-to-refresh or get automatic updates when returning to the app

### Pagination System (Completed - September 8, 2025)
- Implemented efficient infinite scroll pagination for all document lists
- Added FirestoreRepository.getDocumentsPaginated() with cursor-based pagination
- Updated all three controllers (Quotations, Invoices, Receipts) with pagination support
- Added smooth infinite scroll UI with loading indicators
- Prevents app crashes with 1000+ documents by loading only 20 items per page

### Context Menu Implementation (Completed - September 8, 2025)
- Successfully implemented context menu functionality for SENT quotations
- Added long-press gesture detection with GestureDetector
- Context menu displays modal bottom sheet with "แก้ไขเป็นใบแจ้งหนี้" option
- Added reviseQuotationToInvoice() method to copy quotation data and create invoice
- Fixed compilation errors and cleaned up unused imports

### Multiple Emails and Phones Implementation (Completed - September 8, 2025)
- Implemented multiple emails and phones functionality for customer section
- Updated data structure from single email/phone fields to arrays of contact objects
- Added _buildMultipleContactFields() widget for dynamic add/remove contact functionality
- Updated controller with multiple contact management methods (add/remove/update)
- Preserved backward compatibility with legacy single field controllers
- Updated save/load logic to handle arrays of contact data matching Firestore structure

### Document Update Preservation (Completed - September 8, 2025)
- Fixed issue where updating existing documents would change docNo unnecessarily
- Added _currentDocNo, _originalCreatedAt, _originalCreatedBy fields to preserve original data
- Updated save logic to preserve docNo, createdAt, and createdBy for existing documents
- Uses proper IdGenerationService.generateDocumentDocNo() for new documents with workspace rules
- Only generates new docNo for new documents (when documentId == null)
- For updates, preserves existing docNo completely without modification
- Ensures document integrity when updating existing quotations/invoices/receipts

### Page Loading Optimization (Completed - September 8, 2025)
- Fixed bad UX issue where add_edit_document_page was refreshing multiple times on load
- Moved controller initialization to State's initState() to prevent recreation on rebuilds
- Optimized data loading in AddEditDocumentController to reduce UI refresh calls
- Added skipUpdates parameter to loading methods (_loadCustomers, loadTemplates)
- Consolidated multiple update() calls into single update at end of initialization
- Improved page load performance and eliminated visual refresh flickers

### Template Dropdown Fix (Completed - September 8, 2025)
- Fixed critical dropdown assertion error in add_edit_document_page.dart
- Added _getValidTemplateValue() method to validate selected template ID
- Added _buildTemplateDropdownItems() method to prevent duplicate template values
- Ensures dropdown only shows valid, unique template options
- Removed unused imports to clean up code

## Key Features Implemented
1. **Document Lists**: Quotations, Invoices, Receipts with search and filter
2. **Pagination**: Infinite scroll with 20 items per page
3. **Status Management**: Different statuses for each document type
4. **Data Models**: Comprehensive BusinessDocument interfaces
5. **Context Menu**: Long-press to convert SENT quotations to invoices
6. **Template System**: Fixed dropdown validation for document templates

**Added field configuration helpers:**
```dart
bool _isFieldRequired(String controllerKey) {
  return ['name', 'quantity', 'unit', 'pricePerUnit'].contains(controllerKey);
}

String _getFieldHint(String controllerKey, TextInputType keyboardType) {
  // Returns appropriate hint based on field type
}

String? _getFieldPrefix(String controllerKey) {
  return ['pricePerUnit', 'discount'].contains(controllerKey) ? '฿' : null;
}

int _getFieldMaxLines(String controllerKey) {
  return controllerKey == 'description' ? 2 : 1;
}
```

#### 4. Simplified Field Building Logic

**Refactored `_buildDynamicProductFields`:**
- Removed individual field type handling (name, description, quantity, etc.)
- Unified logic using helper methods
- Consistent application of `isEditable` property from template
- Automatic keyboard type detection based on rules

#### 5. Template Field Examples

**Example configurations handled:**
```json
{
  "type": "product_field",
  "sourceField": "customFields.multiply",
  "inputType": "number",
  "isEditable": true,
  "label": "multiply"
}
```
→ Uses `inputType: "number"` (highest priority)

```json
{
  "type": "predefined",
  "predefinedField": "quantity",
  "isEditable": true,
  "label": "Qty"
}
```
→ Uses numeric input (predefined rule)

```json
{
  "type": "product_field",
  "sourceField": "description",
  "isEditable": true,
  "label": "Description"
}
```
→ Uses text input (product_field with non-pricePerUnit sourceField)

```json
{
  "type": "user_input",
  "id": "UlACu8ZEuQxwVk8fng9sW",
  "inputType": "number",
  "label": "Hello"
}
```
→ Uses numeric input (explicit inputType)

### Previous Implementation (Enhanced Summary Section with End-of-Bill Discount)

### Issue Addressed
Added "ส่วนลดท้ายบิล" (end-of-bill discount) functionality to the summary section with proper checkbox behavior and updated calculation logic to use dynamic line_total fields from templates.

### Changes Made

#### 1. Added End-of-Bill Discount Controller and State

**Added to AddEditDocumentController:**
```dart
bool _isEndOfBillDiscountEnabled = false;
bool get isEndOfBillDiscountEnabled => _isEndOfBillDiscountEnabled;
final TextEditingController endOfBillDiscountController = TextEditingController();
```

**Added callback method:**
```dart
void onEndOfBillDiscountEnabledChanged(bool? value) {
  if (value != null) {
    _isEndOfBillDiscountEnabled = value;
    if (!value) {
      endOfBillDiscountController.text = '';
    }
    update();
  }
}
```

#### 2. Updated Calculation Logic

**IMPORTANT CLARIFICATION:** "Total of product totals" refers to the sum of dynamic line_total fields from the template that have `predefinedField: "line_total"`. These fields can contain complex formulas like `{quantity} * {pricePerUnit} * {customFields.multiply}`.

**New calculation flow:** `(sum of all line_total fields) - ส่วนลดท้ายบิล + ภาษีมูลค่าเพิ่ม + หักภาษี ณ ที่จ่าย`

**Updated subtotal calculation to use template line_total fields:**
```dart
double get subtotal {
  try {
    return _products.fold(0.0, (sum, product) {
      final productIndex = _products.indexOf(product);
      
      // Use template-based calculation for line total
      final lineTotal = calculateProductTotal(productIndex);
      
      return sum + lineTotal;
    });
  } catch (e) {
    print('❌ Failed to calculate subtotal: $e');
    return 0.0;
  }
}
```

**Added new getter:**
```dart
double get endOfBillDiscountAmount {
  if (!_isEndOfBillDiscountEnabled) return 0.0;
  return double.tryParse(endOfBillDiscountController.text) ?? 0.0;
}
```

**Updated calculation methods:**
```dart
double get afterDiscount => subtotal - endOfBillDiscountAmount;
double get vatAmount => _isVatEnabled ? afterDiscount * 0.07 : 0.0;
double get afterVat => afterDiscount + vatAmount;
double get netTotal => afterVat - whtAmount;
```

#### 3. Auto-Detection of Existing Discount Data

**Enhanced document loading:**
```dart
// End-of-bill discount settings
final discountAmount = documentData['discount'];
if (discountAmount != null && discountAmount > 0) {
  _isEndOfBillDiscountEnabled = true;
  endOfBillDiscountController.text = discountAmount.toString();
}
```

#### 4. Updated Summary Section UI

**Enhanced _buildSummarySection:**
- Added checkbox for "ส่วนลดท้ายบิล"
- Added conditional input field for discount amount when checkbox is checked
- Shows "ยอดรวมหลังหักส่วนลด" only when discount is enabled
- Updated calculation display flow

**Key UI Features:**
- Checkbox automatically checks if existing discount data is found
- Input field appears only when checkbox is checked
- Real-time calculation updates with `onChanged: (value) => controller.update()`
- Proper validation with numeric keyboard type

#### 5. Database Integration

**Updated document saving:**
```dart
'discount': endOfBillDiscountAmount, // Changed from totalDiscount
```

### Technical Implementation Details

#### Field Mapping:
- Database field: `discount` (document-level)
- UI field: "ส่วนลดท้ายบิล" checkbox + input
- Controller: `endOfBillDiscountController`
- State: `_isEndOfBillDiscountEnabled`

#### Calculation Flow:
1. **Subtotal**: Sum of all product totals (based on template formulas)
2. **End-of-bill Discount**: User-entered amount (if enabled)
3. **After Discount**: Subtotal - End-of-bill discount
4. **VAT**: 7% of after-discount amount (if enabled)
5. **After VAT**: After discount + VAT
6. **WHT**: Percentage of after-VAT amount (if enabled)
7. **Net Total**: After VAT - WHT

#### Auto-Detection Logic:
- Checks `documentData['discount']` during document loading
- If discount > 0, automatically enables checkbox and populates field
- If discount = 0 or null, checkbox remains unchecked

#### Validation Features:
- Numeric input type for discount field
- Empty field handling (defaults to 0)
- Checkbox disables input when unchecked
- Real-time calculation updates

### Previous Implementation (Enhanced Dynamic Product Fields & Custom Field Support)

### Issue Addressed
Fixed dynamic product field handling to properly support all field types from templates, including custom fields with nested sourceField values like `"customFields.multiply"`.

### Changes Made

#### 1. Enhanced Controller Creation for Custom Fields

**Updated `_createProductControllersFromTemplate` Method:**
- Added support for `customFields.*` sourceField patterns
- Properly extracts controller keys from nested sourceField values
- Handles `user_input` field types correctly
- Sets appropriate default values for numeric custom fields

```dart
if (sourceField.startsWith('customFields.')) {
  controllerKey = sourceField.replaceFirst('customFields.', '');
} else {
  controllerKey = sourceField;
}
```

**Updated `_createProductControllersFromDatabase` Method:**
- Loads existing custom field values from database
- Maps `customFields` object to individual controllers
- Maintains backward compatibility with standard fields

#### 2. Enhanced Formula Calculation for Custom Fields

**Updated `calculateProductTotal` Method:**
- Dynamically replaces all available controller values in formulas
- Supports both standard variables `{quantity}` and custom field variables `{customFields.multiply}`
- Iterates through all product controllers to find matching formula variables

```dart
// Replace all possible formula variables with actual values
for (final entry in controllers.entries) {
  final fieldKey = entry.key;
  final controller = entry.value;
  final value = double.tryParse(controller.text) ?? 0;
  
  // Replace standard field variables
  formula = formula.replaceAll('{$fieldKey}', value.toString());
  
  // Replace custom field variables (e.g., {customFields.multiply})
  formula = formula.replaceAll('{customFields.$fieldKey}', value.toString());
}
```

#### 3. Enhanced UI Field Mapping

**Updated `_buildDynamicProductFields` Method:**
- Improved field type detection and controller key mapping
- Handles `customFields.*` sourceField patterns in UI
- Automatically detects numeric fields based on `inputType` property
- Adds `onChanged` callbacks to all custom fields for real-time calculation updates

```dart
if (sourceField.startsWith('customFields.')) {
  controllerKey = sourceField.replaceFirst('customFields.', '');
  isNumericField = field['inputType'] == 'number';
}
```

#### 4. Enhanced Data Saving for Custom Fields

**Updated Save Logic:**
- Separates `customFields` and `customInputs` in saved data structure
- Maps `product_field` types with `customFields.*` sourceField to `customFields` object
- Maps `user_input` types to `customInputs` object
- Automatically converts numeric custom fields to appropriate data types

```dart
if (fieldType == 'product_field' && sourceField.startsWith('customFields.')) {
  const customFieldKey = sourceField.replaceFirst('customFields.', '');
  if (field['inputType'] == 'number') {
    customFields[customFieldKey] = double.tryParse(controller.text) ?? controller.text;
  } else {
    customFields[customFieldKey] = controller.text;
  }
}
```

#### 5. Template Support Enhancements

**Added Support for Complex Templates:**
- `inputType` field detection for proper field rendering
- Nested `customFields` object structure in saved data
- Multiple custom field types in single template
- Complex formulas with mixed standard and custom field variables

**Example Template Field Support:**
```json
{
  "label": "multiply",
  "inputType": "number", 
  "type": "product_field",
  "sourceField": "customFields.multiply",
  "order": 5
}
```

**Example Formula Support:**
```json
{
  "formula": "{quantity} * {pricePerUnit} * {customFields.multiply}",
  "type": "predefined",
  "predefinedField": "line_total"
}
```

### Technical Implementation

**Field Type Mapping:**
- `product_field` with `sourceField: "customFields.x"` → saves to `item.customFields.x`
- `product_field` with standard `sourceField` → saves to `item[sourceField]`
- `predefined` fields → saves to standard item fields
- `user_input` fields → saves to `item.customInputs[fieldId]`

**Formula Variable Resolution:**
- `{quantity}`, `{pricePerUnit}`, etc. → standard field values
- `{customFields.multiply}` → custom field values
- `{fieldId}` → any available controller value

**Data Structure:**
```json
{
  "items": [
    {
      "id": "product-id",
      "name": "Product Name",
      "quantity": 2,
      "pricePerUnit": 100,
      "customFields": {
        "multiply": 1.5
      },
      "customInputs": {
        "user-field-id": "user input value"
      }
    }
  ]
}
```

### UI Improvements

**Dynamic Field Rendering:**
- Automatic numeric field detection based on `inputType`
- Proper placeholder values for different field types
- Real-time calculation updates for all custom fields
- Consistent field labeling and validation

**Template Integration:**
- Fully dynamic form generation based on template structure
- Support for any combination of field types
- Automatic field ordering based on template configuration
- Seamless switching between different templates

## Previous Changes - Product Total Calculation with Template Formula

### Issue Addressed
Added individual product total calculation functionality based on template formulas. Each product now shows a calculated total field that uses the formula defined in the quotation template.

### Changes Made

#### 1. Enhanced Template Field Extraction in `add_edit_document_controller.dart`

**Added Formula Field Support:**
```dart
final field = {
  'id': column['id']?.toString() ?? '',
  'label': column['label']?.toString() ?? '',
  'type': column['type']?.toString() ?? '',
  'sourceField': column['sourceField']?.toString() ?? '',
  'predefinedField': column['predefinedField']?.toString() ?? '',
  'formula': column['formula']?.toString() ?? '', // NEW: Added formula support
  'isVisible': column['isVisible'] ?? true,
  'isEditable': column['isEditable'] ?? true,
  // ... other fields
};
```

#### 2. Added Product Total Calculation Methods

**New Method: `calculateProductTotal(int productIndex)`**
- Finds formula field with `predefinedField == 'line_total'`
- Parses template formula (e.g., `"{quantity} * {pricePerUnit} - {discount}"`)
- Replaces variables with actual product values
- Evaluates formula using safe arithmetic operations
- Falls back to default calculation if no formula found

**New Method: `_evaluateFormula(String formula)`**
- Safe formula evaluator for basic arithmetic operations (+, -, *, /)
- Handles operator precedence (multiplication/division before addition/subtraction)
- Prevents code injection by only allowing basic math operations

**Helper Methods:**
- `_evaluateMultiplyDivide(String expression)` - Handles * and / operations
- `_splitByOperators(String expression, List<String> operators)` - Parses formula tokens

#### 3. Enhanced Product UI in `add_edit_document_page.dart`

**Updated `_buildDynamicProductFields` Method:**
- Detects calculated fields with formulas
- Shows calculated total as read-only field with formula display
- Added `onChanged` callbacks to quantity, pricePerUnit, and discount fields to trigger recalculation
- Real-time calculation updates when input values change

**New Method: `_buildCalculatedTotalField`**
- Displays calculated total with currency symbol (฿)
- Shows the formula used for calculation
- Styled as read-only field with calculation icon
- Orange color highlighting for calculated values

#### 4. Template Formula Support

**Supported Formula Variables:**
- `{quantity}` - Product quantity
- `{pricePerUnit}` - Price per unit
- `{discount}` - Discount amount
- `{customFields.multiply}` - Custom field values

**Example Formula:**
```
"{quantity} * {pricePerUnit} * {customFields.multiply}"
```

**Supported Operations:**
- Addition (+)
- Subtraction (-)
- Multiplication (*)
- Division (/)
- Operator precedence (*, / before +, -)

#### 5. UI Enhancements

**Calculated Total Field Features:**
- Currency prefix (฿)
- Orange color for calculated values
- Calculation icon indicator
- Formula display below the value
- Real-time updates when inputs change

**Input Field Updates:**
- Added `onChanged` callbacks for calculation-related fields
- Triggers controller update for real-time recalculation
- Maintains existing validation and formatting

### Technical Implementation

**Formula Evaluation Process:**
1. Extract formula from template field definition
2. Replace variable placeholders with actual values
3. Parse expression respecting operator precedence
4. Safely evaluate using custom arithmetic parser
5. Display result in read-only calculated field

**Safety Measures:**
- Only basic arithmetic operations allowed
- No eval() or dynamic code execution
- Input validation and null safety
- Error handling with fallback calculations

### Integration with Template System

**Template Data Structure:**
Templates now support `formula` field in column definitions:
```json
{
  "id": "amount-field",
  "label": "Amount",
  "type": "predefined",
  "predefinedField": "line_total",
  "formula": "{quantity} * {pricePerUnit} - {discount}",
  "isVisible": true,
  "isEditable": false
}
```

**Dynamic Behavior:**
- Different templates can have different formulas
- Formulas are applied per template configuration
- Falls back to default calculation if no formula specified
- Supports multiple calculated fields per template

## Previous Changes - Field Mapping Fix

### Issue Identified
The quotation data was being saved with incorrect field mappings, causing data structure mismatch between expected and actual saved data.

### Changes Made

#### 1. Updated Document Data Structure in `add_edit_document_controller.dart`

**Before (Wrong Structure):**
- Complex nested seller object with unnecessary fields
- Duplicate product data in both 'products' and 'items' arrays
- Extra fields not needed for quotation
- Incorrect field names and structure

**After (Correct Structure):**
```dart
final documentData = {
  'status': _documentStatus,
  'items': [...], // Only items array, no duplicate products
  'discount': totalDiscount,
  'withholdingTaxPercentage': whtPercentage,
  'isVatEnabled': _isVatEnabled,
  'project': {
    'name': jobNameController.text,
    'refId': refIdController.text,
  },
  'seller': {
    'lastDeviceId': 'BE2A.250530.026.F3',
    'fcmTokenUpdatedAt': {...},
    'displayName': sellerNameController.text,
    'fcmToken': '',
    'uid': _selectedSellerIds.first,
    'viewSettings': {...},
    'email': 'minimark@sellstory.me',
    'lastPlatform': 'android',
    'language': 'en',
    'workspaces': [...],
    'photoURL': null,
  },
  'sellerName': sellerNameController.text,
  'sellerPhone': sellerPhoneController.text,
  'notes': notesController.text,
  'signatureAssignments': {},
  'templateId': '',
  'customer': {...},
  'jobName': jobNameController.text,
  'validUntil': _validUntilDate?.millisecondsSinceEpoch,
  'company': {...},
  'subtotal': subtotal,
  'grandTotal': netTotal,
  'vatAmount': vatAmount,
  'netTotal': netTotal,
  'whtAmount': whtAmount,
  'docNo': docNo ?? 'EST-${DateTime.now().millisecondsSinceEpoch}',
  'type': 'QT',
  'workspaceId': _currentWorkspaceId!,
  'createdAt': DateTime.now().millisecondsSinceEpoch,
  'updatedAt': DateTime.now().millisecondsSinceEpoch,
  'createdBy': _currentUserId!,
  'updatedBy': _currentUserId!,
  'activityLog': [...],
};
```

#### 2. Key Field Mappings Fixed

**Items Structure:**
- ✅ `items` array with `customInputs: {}` field
- ✅ Removed duplicate `products` array
- ✅ Correct field names: `id`, `name`, `description`, `quantity`, `unit`, `pricePerUnit`, `discount`

**Seller Structure:**
- ✅ Simplified seller object with only required fields
- ✅ Correct `fcmTokenUpdatedAt` format with `seconds` and `nanoseconds`
- ✅ Proper `viewSettings` structure for customer profile cards

**Customer Structure:**
- ✅ Simplified customer object with essential fields only
- ✅ Correct email and phone structure with `label`, `value`, `id`

**Company Structure:**
- ✅ Simplified company object with `value`, `id`, `label` fields

**Document Numbers:**
- ✅ Updated fallback prefix from 'QT-' to 'EST-' for quotations
- ✅ Consistent document number generation

#### 3. Removed Unnecessary Fields

**Fields Removed:**
- `invoiceType`, `installmentNumber`, `totalInstallments`
- `totalAmountFromDocument`, `customerId`, `companyId`
- `customerAddress`, `customerPostalCode`, `customerNationalId`
- `customerPhone`, `customerEmail`
- `boardName`, `lane`, `priority`, `dueDate`, `todos`
- `description`, `title`, `customId`
- `paymentMethods`, `paymentStatus`, `receiptFor`
- `paymentDate`, `includeSignature`, `relatedDocuments`
- `isWhtEnabled`, `whtPercentage`
- `totalAmountBeforeDiscount`, `totalAmountAfterDiscount`
- `shippingCost`, `depositAmount`, `deductedDeposit`
- `afterVat`, `totalAmountBeforeVat`
- `approval`, `depositInfo`, `invoicingPlan`, `depositDeducted`, `approvers`

### Result
The quotation data now matches the expected structure with:
- Clean, focused field mapping
- Correct data types and formats
- No duplicate or unnecessary fields
- Proper nested object structures
- Consistent field naming conventions

### Template Functionality Added
- **Template Selection**: Dropdown at the top of the page to select quotation templates
- **Database Integration**: Fetches templates from `workspaces/{workspaceId}/quotationTemplates/{templateIds}`
- **Default Option**: "ไม่มี (None)" as default selection
- **Template Data**: Shows template name as label in dropdown options
- **Template ID Storage**: Saves selected template ID in document data
- **Dynamic Field Support**: Product fields now dynamically adapt based on template selection

### Dynamic Product Fields Implementation
- **Template Field Extraction**: Automatically extracts product fields from `body.components[table].columns` in template data
- **Field Type Support**: Supports `product_field`, `predefined`, and `user_input` field types
- **Dynamic Form Generation**: Product form fields are generated based on template configuration
- **Field Properties**: Respects template field properties like `isVisible`, `isEditable`, `order`, `width`, `align`
- **Smart Field Mapping**: Automatically maps template fields to appropriate input types (text, number, etc.)
- **Fallback Support**: Falls back to default fields if template parsing fails
- **Validation Integration**: Product validation now works with dynamic fields from templates
- **Template Requirement**: Users must select a template before adding products
- **Dynamic Controller Creation**: Product controllers are created based on template field configuration
- **Custom Inputs Support**: User input fields are properly saved to `customInputs` object in database
- **Flexible Product Addition**: No required field validation - users can add products freely once template is selected

### Success Flow Enhancement
- **Success Notification**: Shows success message with generated document ID in a snackbar
- **Document ID Display**: Includes the document number in the success message for easy reference
- **Navigation**: Uses `Get.off()` to navigate back to the document center page after successful save

### Template Signature Integration
- **Signature Field Extraction**: Automatically extracts signature fields from `body.components[signature]` in template data
- **Signature Loading**: Fetches available signatures from `workspaces/{WorkspaceId}/companyProfile.docSettings.signatures` as JSON field
- **Dynamic Signature UI**: Signature selection section is only shown when template contains signature components
- **Role-Based Selection**: Each signature role from template gets its own dropdown with available signatures
- **Signature Preview**: Shows signature image thumbnail, name, owner name, and position in dropdown options
- **Signature Management**: Tracks selected signatures by role name for each template signature field
- **Error Prevention**: Added safety checks and proper image constraints to prevent rendering issues
- **User Experience**: Provides clear feedback about operation result and generated document ID
- **Extended Duration**: Success notification stays visible for 4 seconds to ensure user sees the document ID

### Save Data Structure Enhancement
- **Dynamic Item Fields**: Product items now include only fields that exist in the selected template
- **Custom Inputs Mapping**: User input fields from template are saved with their field ID as key
- **Template-Aware Saving**: Save logic dynamically builds item data based on template configuration
- **Flexible Field Support**: Supports any combination of standard and custom fields from templates

### UI Improvements - Merged Status & Template Section
- **Combined Section**: Merged document status and template selection into a single, prominent section at the top
- **Collapsible Interface**: Section can be expanded/collapsed using the standard section header pattern
- **Default Expanded**: Set to be expanded by default since both status and template are important
- **Side-by-Side Layout**: Document status and template selection are displayed side by side for better UX
- **Unified Header**: Single header "สถานะเอกสาร & เทมเพลต" with settings icon
- **Cleaner Interface**: Reduced visual clutter by combining related functionality
- **Better Space Utilization**: More efficient use of screen real estate
- **Consistent UX**: Follows the same collapsible pattern as other sections

### Files Modified
1. `lib/features/document/controller/add_edit_document_controller.dart`
    - Updated `saveDocument()` method
    - Fixed document data structure
    - Corrected field mappings
    - Added template selection functionality
    - Added template loading from database
    - Added template change handler
    - Added dynamic product field extraction from templates
    - Added template field parsing and mapping logic

2. `lib/features/document/view/add_edit_document_page.dart`
    - Added template selection section at the top
    - Added template dropdown with database integration
    - Replaced static product fields with dynamic template-based fields
    - Added `_buildDynamicProductFields()` method for template-driven form generation
    - Updated product validation to work with dynamic fields
    - Enhanced product completion checking based on template requirements

### Testing Required
- Create new quotation
- Verify saved data structure matches expected format
- Check all required fields are present
- Validate data types and formats
- Ensure no duplicate or missing fields

### Notes
- The controller now generates cleaner, more focused document data
- Field mappings align with the expected database schema
- Removed complexity while maintaining functionality
- Document numbers use correct quotation prefix (EST-)
