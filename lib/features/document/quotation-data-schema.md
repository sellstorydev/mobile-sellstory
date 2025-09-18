êìáDA®Ö]ªú¿Ì/ÖIå˝©^ÍÊb†ÿ document outlines the data structure for a Quotation object as it is stored in Firestore and the payload required to create a new quotation.

## I. Saved Data Structure

This is the complete data structure of a quotation document as stored in the database.

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | `string` | The unique identifier for the document. |
| `docNo` | `string` | The user-facing document number (e.g., QT-202408-001). |
| `type` | `string` | The document type, always "QT" for quotations. |
| `workspaceId` | `string` | The ID of the workspace this document belongs to. |
| `status` | `string` | The current status of the quotation (e.g., DRAFT, SENT, APPROVED, REJECTED, VOID, INVOICED, FULLY_PAID). |
| `customer` | `object` | An object containing a snapshot of customer details. |
| `customer.id` | `string` | The customer's unique ID. |
| `customer.name` | `string` | The customer's name. |
| `customer.address`| `string` | The customer's full address. |
| `customer.nationalId`|`string`| The customer's Tax ID or National ID. |
| `seller` | `object` | An object containing a snapshot of the seller's (user) details. |
| `seller.uid` | `string` | The seller's user ID. |
| `seller.displayName`| `string` | The seller's display name. |
| `sellerName` | `string` | The display name of the seller at the time of creation. |
| `jobName` | `string` | The name or title of the job/project. |
| `jobCardId` | `string` | (Optional) The ID of the associated Job Card. |
| `items` | `array` | An array of `LineItem` objects. |
| `items[].id` | `string` | A unique ID for the line item. |
| `items[].name` | `string` | The name of the product or service. |
| `items[].description`| `string` | A detailed description. |
| `items[].quantity` | `number` | The quantity for this line item. |
| `items[].unit` | `string` | The unit of measurement (e.g., "piece", "hour"). |
| `items[].pricePerUnit`| `number` | The price for a single unit. |
| `items[].discount` | `number` | A discount amount for the line item. |
| `items[].discountType`| `string` | Either 'percentage' or 'amount'. |
| `subtotal` | `number` | The calculated sum of all line items before discounts and taxes. |
| `discount` | `number` | The final discount amount applied to the subtotal. |
| `vatAmount` | `number` | The calculated VAT amount. |
| `grandTotal` | `number` | The final total including VAT. |
| `whtAmount` | `number` | The calculated Withholding Tax amount. |
| `withholdingTaxPercentage` | `number` | The percentage used for WHT calculation. |
| `netTotal` | `number` | The final amount due after all deductions (grandTotal - whtAmount). |
| `isVatEnabled` | `boolean` | Flag to indicate if VAT is applied. |
| `validUntil` | `number` | Timestamp for when the quotation expires. |
| `createdAt` | `number` | Timestamp of when the document was created. |
| `updatedAt` | `number` | Timestamp of the last update. |
| `createdBy` | `string` | UID of the user who created the document. |
| `updatedBy` | `string` | UID of the user who last updated the document. |
| `activityLog` | `array` | An array of activity log objects. |
| `templateId` | `string` | The ID of the `QuotationTemplate` used. |

---

## II. Creation Payload

This section describes the data payload required to create a new quotation document via an API call or function. The server will automatically generate fields like `id`, `docNo`, `createdAt`, etc.

### Required Fields

| Field | Type | Description | Example |
| :--- | :--- | :--- | :--- |
| `customer` | `object` | An object with customer details. At minimum, `id` and `name` are required. | `{"id": "cust_123", "name": "John Doe", "address": "123 Main St"}` |
| `seller` | `object` | An object with the seller's (user) details. At minimum, `uid` and `displayName` are required. | `{"uid": "user_abc", "displayName": "Jane Smith"}` |
| `items` | `array` | An array of `LineItem` objects. | `[{"name": "Web Design", "quantity": 1, "pricePerUnit": 50000}]` |
| `jobName` | `string` | A descriptive name for the project or quotation. | `"Website Redesign Project"` |
| `isVatEnabled` | `boolean`| `true` if VAT should be applied to the total. | `true` |

### Optional Fields

| Field | Type | Description | Example |
| :--- | :--- | :--- | :--- |
| `status` | `string` | Initial status. Defaults to 'DRAFT' if not provided. | `"SENT"` |
| `templateId` | `string` | The ID of the document template to use. Recommended. | `"template_xyz"` |
| `jobCardId` | `string` | The ID of an associated Job Card. | `"card_789"` |
| `validUntil` | `number` | A timestamp indicating when the quote expires. | `1724783491000` |
| `discount` | `number` | A final discount amount to be applied after the subtotal. | `500` |
| `withholdingTaxPercentage` | `number`| The WHT percentage to apply (e.g., 3 for 3%). | `3` |
| `notes` | `string` | Any additional notes or terms for the quotation. | `"Payment due within 30 days."` |

### LineItem Structure (within `items` array)

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | `string` | **Required.** A unique identifier for the line item (can be client-generated). |
| `name` | `string` | **Required.** The name of the product or service. |
| `description` | `string` | Optional description of the item. |
| `quantity` | `number` | **Required.** The quantity of the item. |
| `unit` | `string` | The unit of measurement (e.g., "piece", "hour", "sq.m."). |
| `pricePerUnit`| `number` | **Required.** The price for a single unit. |
| `discount` | `number` | A discount for this specific line item. |
| `discountType`| `string` | `'percentage'` or `'amount'`. Defaults to `'amount'`. |
