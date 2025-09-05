# Document System Summary

## Recent Changes - Enhanced Input Type Handling for Dynamic Product Fields

### Issue Addressed
Added proper input type conditions for product section fields based on template configuration, ensuring number-only inputs for numeric fields and text inputs for text fields.

### Changes Made

#### 1. Enhanced Input Type Detection Logic

**Added helper method `_getKeyboardTypeForField`:**
```dart
TextInputType _getKeyboardTypeForField(Map<String, dynamic> field, String controllerKey) {
  // Check if field has explicit inputType - this takes priority
  final inputType = field['inputType']?.toString();
  if (inputType != null) {
    return inputType == 'number' ? TextInputType.number : TextInputType.text;
  }
  
  // Apply default rules based on field type and sourceField
  final fieldType = field['type']?.toString() ?? '';
  
  if (fieldType == 'predefined') {
    // All predefined fields are numeric
    return TextInputType.number;
  } else if (fieldType == 'product_field') {
    // For product_field, only pricePerUnit is numeric, others are text
    final sourceField = field['sourceField']?.toString() ?? '';
    return sourceField == 'pricePerUnit' ? TextInputType.number : TextInputType.text;
  } else if (fieldType == 'user_input') {
    // Default to text for user_input unless specified otherwise
    return TextInputType.text;
  }
  
  // Default fallback
  return TextInputType.text;
}
```

#### 2. Input Type Priority Rules

**Implemented priority system:**
1. **Highest Priority:** If `inputType` is explicitly defined in template → use that value
2. **Medium Priority:** If `type = "predefined"` → all fields are numeric
3. **Medium Priority:** If `type = "product_field"` → only `sourceField = "pricePerUnit"` is numeric, others are text
4. **Lowest Priority:** If `type = "user_input"` → default to text unless `inputType` specified

#### 3. Additional Helper Methods

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
