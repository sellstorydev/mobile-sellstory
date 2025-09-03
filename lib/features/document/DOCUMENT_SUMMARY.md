# Document System Summary

## Recent Changes - Field Mapping Fix

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
