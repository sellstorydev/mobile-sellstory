# Document System

## Overview
document system is about ใบเสนอราคา, ใบแจ้งหนี้, ใบเสร็จรับเงิน

## FEATURE:
- have center page that can go from main application footer menu "เอกสาร" that have 3 menu inside Quotations, Invoices, Receipts
- list of Quotations (ใบเสนอราคา)
- list of Invoices (ใบแจ้งหนี้)
- list of Receipts (ใบเสร็จรับเงิน)
- in ecah list have feature search and filter
- filter have 3 field
    - เซล (use this picker `lib\core\widgets\assignees_input_field.dart`)
    - วันที่ (date-picker)
    - สถานะเอกสาร (list of checkbox can select multiple)
        - Quotation status is 'DRAFT' | 'SENT' | 'PENDING_APPROVAL' | 'APPROVED' | 'REJECTED' | 'VOID' | 'INVOICED' | 'FULLY_PAID'
        - Invoices status is 'DRAFT' | 'SENT' | 'PARTIAL_PAID' | 'PAID' | 'OVERDUE' | 'VOID'
        - Receipt status is 'COMPLETED' | 'VOID'
- all about DEP(Deposit) is coming soon is hide or don't do anything about Deposit but data have it

## PROJECT STRUCTURE:
- main folder of document system is `lib\features\document`

## DOCUMENTATION:
- `get: ^4.6.6` - State management and dependency injection
- `flutter` - UI framework
- `firebase_core`: ^3.4.0
- `firebase_auth`: ^5.3.0
- `cloud_firestore`: ^5.4.0
- `dio`

## DATA MODEL
```
BusinessDocument {
  id: string;
  docNo: string;
  type: 'QT' | 'INV' | 'RT' | 'DEP'; // Added DEP for Deposit
  status: string;
  customer: Customer;
  seller: AppUser;
  items: LineItem[];
  subtotal: number;
  discount: number;
  vatAmount: number;
  grandTotal: number;
  notes?: string;
  createdAt: number;
  updatedAt: number;
  createdBy?: string;
  updatedBy?: string;
  workspaceId: string;
  activityLog?: DocActivityLog[];
  paymentMethod?: ('bank' | 'qr')[];
  includeSignature?: boolean;
  relatedDocuments?: RelatedDocInfo[]; // Centralized linking
  jobCardId?: string;
}
```
```
interface Quotation extends BusinessDocument {
  type: 'QT';
  status: 'DRAFT' | 'SENT' | 'PENDING_APPROVAL' | 'APPROVED' | 'REJECTED' | 'VOID' | 'INVOICED' | 'FULLY_PAID';
  validUntil: number;
  approvers?: { userId: string, approvedAt: number, roleId: string }[];
  jobName: string;
  sellerName: string;
  customerName: string;
  project?: {
    name: string;
    refId: string;
    company?: ContactInfo;
  };
  whtAmount: number;
  withholdingTaxPercentage?: number;
  netTotal: number;
  isVatEnabled?: boolean;
  // New fields for deposit and invoicing plan
  depositInfo?: DepositInfo;
  invoicingPlan?: InvoicingPlan[];
  depositDeducted?: boolean;
  approval?: ApprovalState;
}
```
```
interface Invoice extends BusinessDocument {
  type: 'INV';
  status: 'DRAFT' | 'SENT' | 'PARTIAL_PAID' | 'PAID' | 'OVERDUE' | 'VOID';
  invoiceType: 'full' | 'installment' | 'deposit'; // To handle deposit invoices as well
  relatedQuotationId?: string;
  dueDate: number;
  paymentStatus: 'unpaid' | 'partially_paid' | 'paid';
  // Fields for installment tracking
  installmentNumber?: number;
  totalInstallments?: number;
  totalAmountFromQuotation?: number;
  deductedDeposit?: number;
}
```
```
interface Receipt extends BusinessDocument {
  type: 'RT';
  status: 'COMPLETED' | 'VOID';
  relatedInvoiceId?: string;
  paymentDate: number;
  paymentMethod: ('cash' | 'transfer' | 'credit_card' | 'cheque')[];
  receiptFor: 'invoice' | 'deposit';
}
```

## RELATED DATABASE

#### workspaces/{workspace UIDs}/documents/{Document UIDs}
example data:
```{
  "status": "PARTIAL_PAID",
  "items": [
    {
      "id": "1756362643770",
      "name": "C",
      "description": "D",
      "quantity": 2,
      "unit": "หน่วย",
      "pricePerUnit": 3,
      "discount": 4
    }
  ],
  "discount": 5,
  "withholdingTaxPercentage": 7,
  "shippingCost": 8,
  "depositAmount": 0,
  "isVatEnabled": true,
  "seller": {
    "email": "minimark@sellstory.me",
    "workspaces": [
      {
        "role": "owner",
        "name": "Mini Mark's Workspace",
        "id": "5hMae0Og3XYVtM0T9XQR"
      }
    ],
    "viewSettings": {
      "customerProfileCardsConfig_P8b7ATcEzYlePEJwT1Zl": {
        "lane": {
          "isVisible": true,
          "order": 4
        },
        "totalAmountBeforeVat": {
          "isVisible": true,
          "order": 16
        },
        "grandTotal": {
          "isVisible": true,
          "order": 12
        },
        "totalAmountAfterDiscount": {
          "isVisible": true,
          "order": 15
        },
        "customerInterest": {
          "isVisible": true,
          "order": 7
        },
        "priority": {
          "order": 11,
          "isVisible": true
        },
        "status": {
          "isVisible": true,
          "order": 3
        },
        "assignee": {
          "isVisible": true,
          "order": 6
        },
        "dueDate": {
          "isVisible": true,
          "order": 5
        },
        "customId": {
          "order": 0,
          "isVisible": true
        },
        "todos": {
          "isVisible": true,
          "order": 18
        },
        "title": {
          "isVisible": true,
          "order": 1
        },
        "boardName": {
          "isVisible": true,
          "order": 2
        },
        "totalAmountBeforeDiscount": {
          "isVisible": true,
          "order": 14
        },
        "customer": {
          "isVisible": true,
          "order": 8
        },
        "netTotal": {
          "isVisible": true,
          "order": 13
        },
        "hashtags": {
          "isVisible": true,
          "order": 10
        },
        "description": {
          "isVisible": true,
          "order": 17
        },
        "company": {
          "order": 9,
          "isVisible": true
        }
      },
      "customerProfileCardsConfig_MijlE4UzniaR3qtk4oAx": {
        "priority": {
          "order": 10,
          "isVisible": true
        },
        "customId": {
          "order": 0,
          "isVisible": true
        },
        "hashtags": {
          "order": 9,
          "isVisible": true
        },
        "status": {
          "order": 3,
          "isVisible": true
        },
        "dueDate": {
          "order": 5,
          "isVisible": true
        },
        "lane": {
          "isVisible": true,
          "order": 4
        },
        "todos": {
          "isVisible": true,
          "order": 17
        },
        "totalAmountBeforeDiscount": {
          "order": 13,
          "isVisible": true
        },
        "totalAmountAfterDiscount": {
          "order": 14,
          "isVisible": true
        },
        "grandTotal": {
          "order": 11,
          "isVisible": true
        },
        "title": {
          "isVisible": true,
          "order": 1
        },
        "company": {
          "isVisible": true,
          "order": 8
        },
        "description": {
          "order": 16,
          "isVisible": true
        },
        "customer": {
          "order": 7,
          "isVisible": true
        },
        "totalAmountBeforeVat": {
          "isVisible": true,
          "order": 15
        },
        "assignee": {
          "order": 6,
          "isVisible": true
        },
        "netTotal": {
          "isVisible": true,
          "order": 12
        },
        "boardName": {
          "isVisible": true,
          "order": 2
        }
      },
      "customerProfileCardsConfig_YRYXfnlhznwxIY4GcPHg": {
        "totalAmountAfterDiscount": {
          "order": 15,
          "isVisible": true
        },
        "lane": {
          "isVisible": true,
          "order": 4
        },
        "priority": {
          "isVisible": true,
          "order": 11
        },
        "netTotal": {
          "order": 13,
          "isVisible": true
        },
        "customer": {
          "order": 8,
          "isVisible": true
        },
        "boardName": {
          "order": 2,
          "isVisible": true
        },
        "assignee": {
          "order": 6,
          "isVisible": true
        },
        "grandTotal": {
          "order": 12,
          "isVisible": true
        },
        "todos": {
          "order": 18,
          "isVisible": true
        },
        "title": {
          "isVisible": true,
          "order": 1
        },
        "description": {
          "order": 17,
          "isVisible": true
        },
        "status": {
          "order": 3,
          "isVisible": true
        },
        "company": {
          "isVisible": true,
          "order": 9
        },
        "totalAmountBeforeVat": {
          "isVisible": true,
          "order": 16
        },
        "customId": {
          "isVisible": true,
          "order": 0
        },
        "customerInterest": {
          "isVisible": true,
          "order": 7
        },
        "dueDate": {
          "order": 5,
          "isVisible": true
        },
        "hashtags": {
          "isVisible": true,
          "order": 10
        },
        "totalAmountBeforeDiscount": {
          "isVisible": true,
          "order": 14
        }
      },
      "customerProfileCardsConfig_xsv2WkW3P0gny7INLuj4": {
        "assignee": {
          "order": 6,
          "isVisible": true
        },
        "boardName": {
          "order": 2,
          "isVisible": true
        },
        "totalAmountAfterDiscount": {
          "isVisible": true,
          "order": 14
        },
        "netTotal": {
          "isVisible": true,
          "order": 12
        },
        "customId": {
          "order": 0,
          "isVisible": true
        },
        "description": {
          "isVisible": true,
          "order": 16
        },
        "totalAmountBeforeVat": {
          "order": 15,
          "isVisible": true
        },
        "lane": {
          "isVisible": true,
          "order": 4
        },
        "dueDate": {
          "order": 5,
          "isVisible": true
        },
        "totalAmountBeforeDiscount": {
          "order": 13,
          "isVisible": true
        },
        "priority": {
          "isVisible": true,
          "order": 10
        },
        "customer": {
          "order": 7,
          "isVisible": true
        },
        "grandTotal": {
          "order": 11,
          "isVisible": true
        },
        "title": {
          "order": 1,
          "isVisible": true
        },
        "company": {
          "isVisible": true,
          "order": 8
        },
        "todos": {
          "order": 17,
          "isVisible": true
        },
        "status": {
          "order": 3,
          "isVisible": true
        },
        "hashtags": {
          "order": 9,
          "isVisible": true
        }
      }
    },
    "displayName": "Mini Mark",
    "language": "en",
    "fcmToken": "cqr2IvJ8Sn6JsOGMSeVVnj:APA91bHXOgoA50L2fiS2tC7POA6ea_YyZnDUys4CjMIPZiwEC7y2oW3XS72mVzhniR9poyJuH6vykSpaY52Kgz6kkJdVe2NQ_FYLfgm243s3NkwekYwRWJQ",
    "uid": "0CaMzG4MyZdO0boiP2kaQYHTbSl1",
    "lastPlatform": "android",
    "lastDeviceId": "BE2A.250530.026.F3",
    "fcmTokenUpdatedAt": {
      "seconds": 1756359257,
      "nanoseconds": 199000000
    },
    "phoneNumber": "A"
  },
  "notes": "E",
  "paymentMethod": [],
  "includeSignature": true,
  "jobCardId": "JB-250828-0001",
  "customer": {
    "id": "xt8oSJKDsTeU7HMCM0VC",
    "address": "",
    "updatedBy": "0CaMzG4MyZdO0boiP2kaQYHTbSl1",
    "createdAt": 1756120569602,
    "gender": "Male",
    "source": "",
    "age": "25",
    "customId": "CUST-250825-0017",
    "prefix": "",
    "createdBy": "0CaMzG4MyZdO0boiP2kaQYHTbSl1",
    "companyNames": [
      {
        "associatedCustomerIds": [],
        "branch": "",
        "emails": [],
        "website": "",
        "district": "",
        "postalCode": "",
        "hashtags": [],
        "workspaceId": "5hMae0Og3XYVtM0T9XQR",
        "phones": [],
        "taxId": "",
        "updatedAt": 1756190143127,
        "createdAt": 1756190143126,
        "subdistrict": "",
        "province": "",
        "customId": "COMP-250826-0005",
        "updatedBy": "0CaMzG4MyZdO0boiP2kaQYHTbSl1",
        "country": "",
        "createdBy": "0CaMzG4MyZdO0boiP2kaQYHTbSl1",
        "id": "L10xar6dnI0uWYy3w3tt",
        "addressLine1": "",
        "name": "testCompAddd"
      },
      {
        "associatedCustomerIds": [],
        "hashtags": [],
        "workspaceId": "5hMae0Og3XYVtM0T9XQR",
        "id": "LIcZzcyOUIKVQ0aSkSH5",
        "province": "",
        "branch": "",
        "customId": "COM-250826-0003",
        "subdistrict": "",
        "website": "",
        "updatedAt": 1756190052942,
        "country": "",
        "district": "",
        "addressLine1": "",
        "postalCode": "",
        "updatedBy": "0CaMzG4MyZdO0boiP2kaQYHTbSl1",
        "phones": [],
        "createdBy": "0CaMzG4MyZdO0boiP2kaQYHTbSl1",
        "name": "testCompID",
        "taxId": "",
        "createdAt": 1756190052942,
        "emails": []
      },
      {
        "postalCode": "12345",
        "id": "RAPE70w1bpGOcp5YWP9k",
        "province": "g",
        "website": "c",
        "branch": "b",
        "country": "h",
        "name": "test company",
        "phones": [],
        "emails": [],
        "workspaceId": "5hMae0Og3XYVtM0T9XQR",
        "hashtags": [
          {
            "color": "#3b82f6",
            "text": "✅tests@🌚",
            "id": "tests"
          },
          {
            "color": "#d946ef",
            "text": "more",
            "id": "more"
          }
        ],
        "subdistrict": "e",
        "customId": "COM-1756189308888",
        "createdBy": "0CaMzG4MyZdO0boiP2kaQYHTbSl1",
        "district": "f",
        "createdAt": 1756189308889,
        "addressLine1": "d",
        "taxId": "a",
        "associatedCustomerIds": [],
        "updatedBy": "0CaMzG4MyZdO0boiP2kaQYHTbSl1",
        "updatedAt": 1756189308889
      },
      {
        "updatedBy": "0CaMzG4MyZdO0boiP2kaQYHTbSl1",
        "province": "pro",
        "phones": [
          {
            "value": "Phone 1",
            "id": "phone-initial",
            "label": "Main"
          },
          {
            "value": "Phone 2",
            "label": "Work",
            "id": "contact-1756109857368"
          }
        ],
        "createdBy": "0CaMzG4MyZdO0boiP2kaQYHTbSl1",
        "associatedCustomerIds": [
          "xsv2WkW3P0gny7INLuj4",
          "QnJaW3PPNnoKX5RgSYNH",
          "bxlIoMQUkoBwirtSNj0W"
        ],
        "name": "Company For test",
        "branch": "Test",
        "taxId": "12341234",
        "customId": "COM-250825-0001",
        "district": "dis",
        "hashtags": [
          {
            "id": "test",
            "color": "#eab308",
            "text": "test"
          }
        ],
        "updatedAt": 1756110384392,
        "emails": [
          {
            "value": "Mail 1",
            "label": "Main",
            "id": "email-initial"
          },
          {
            "value": "Mail 2",
            "label": "Work",
            "id": "contact-1756109859807"
          }
        ],
        "postalCode": "12345",
        "subdistrict": "sub",
        "createdAt": 1756110384392,
        "addressLine1": "address",
        "id": "dSle4ZvvJIwDsBdKLkA8",
        "website": "site",
        "country": "coun",
        "workspaceId": "5hMae0Og3XYVtM0T9XQR"
      }
    ],
    "hashtags": [
      {
        "text": "test",
        "id": "test",
        "color": "#eab308"
      },
      {
        "text": "more",
        "id": "more",
        "color": "#d946ef"
      }
    ],
    "name": "GGG",
    "nationalId": "",
    "workspaceId": "5hMae0Og3XYVtM0T9XQR",
    "customerType": "Customer",
    "updatedAt": 1756192882899
  },
  "project": {
    "refId": "1",
    "name": "B"
  },
  "dueDate": 1756659600000,
  "deductedDeposit": 6,
  "subtotal": 0,
  "grandTotal": 0,
  "netTotal": 0,
  "type": "INV",
  "docNo": "INV-250828-0001",
  "workspaceId": "5hMae0Og3XYVtM0T9XQR",
  "createdAt": 1756362668125,
  "updatedAt": 1756362668125,
  "createdBy": "0CaMzG4MyZdO0boiP2kaQYHTbSl1",
  "updatedBy": "0CaMzG4MyZdO0boiP2kaQYHTbSl1",
  "activityLog": [
    {
      "timestamp": 1756362668125,
      "userId": "0CaMzG4MyZdO0boiP2kaQYHTbSl1",
      "userDisplayName": "minimark@sellstory.me",
      "action": "Created",
      "details": "Created invoice INV-250828-0001"
    }
  ],
  "validUntil": 1756918800000,
  "vatAmount": 0.35000000000000003,
  "whtAmount": 0.15,
  "sellerName": "Mini Mark",
  "sellerPhone": "",
  "signatureAssignments": {},
  "company": null,
  "id": "qb4RydsSdwcKmd77ND2w",
  "jobName": "workworkwork"
}```


#### customer data is from: workspaces/{workspace UIDs}/customers/{CustomerUIDs}
example data:
```
{
  "address": "",
  "updatedBy": "0CaMzG4MyZdO0boiP2kaQYHTbSl1",
  "gender": "Male",
  "hashtags": [],
  "prefix": "",
  "phones": [],
  "assignees": [
    "0CaMzG4MyZdO0boiP2kaQYHTbSl1"
  ],
  "customId": "CUST-250826-0027",
  "emails": [],
  "createdAt": 1756195038595,
  "customerType": "Customer",
  "nationalId": "",
  "createdBy": "0CaMzG4MyZdO0boiP2kaQYHTbSl1",
  "name": "test add company cust",
  "age": "25",
  "workspaceId": "5hMae0Og3XYVtM0T9XQR",
  "source": "",
  "companyNames": [
    {
      "id": "LIcZzcyOUIKVQ0aSkSH5",
      "label": "Main",
      "value": "testCompID"
    },
    {
      "id": "L10xar6dnI0uWYy3w3tt",
      "label": "Main",
      "value": "testCompAddd"
    },
    {
      "id": "Vwtn4OmU5BzD531eBG1H",
      "label": "Main",
      "value": "testFromWeb"
    },
    {
      "id": "RAPE70w1bpGOcp5YWP9k",
      "label": "Main",
      "value": "test company"
    },
    {
      "id": "SdXOLHJWKkeldSc7bs18",
      "label": "Main",
      "value": "testMoreComp"
    },
    {
      "id": "lY7iOcQ97lo6dr6T8dLT",
      "label": "Main",
      "value": "g"
    }
  ],
  "updatedAt": 1756200107190,
  "customFields": [],
  "id": "coHYxgD7M3U41nqGcfV2"
}
```

#### seller data is from: users/{sellerUIDs}
example data:
```
{
  "uid": "0CaMzG4MyZdO0boiP2kaQYHTbSl1",
  "email": "minimark@sellstory.me",
  "photoURL": null,
  "language": "en",
  "workspaces": [
    {
      "id": "5hMae0Og3XYVtM0T9XQR",
      "name": "Mini Mark's Workspace",
      "role": "owner"
    }
  ],
  "viewSettings": {
    "customerProfileCardsConfig_MijlE4UzniaR3qtk4oAx": {
      "dueDate": {
        "order": 5,
        "style": {},
        "isVisible": true
      },
      "totalAmountAfterDiscount": {
        "style": {},
        "isVisible": true,
        "order": 14
      },
      "boardName": {
        "isVisible": true,
        "order": 2,
        "style": {}
      },
      "netTotal": {
        "style": {},
        "order": 12,
        "isVisible": true
      },
      "title": {
        "isVisible": true,
        "style": {},
        "order": 1
      },
      "todos": {
        "order": 17,
        "style": {},
        "isVisible": true
      },
      "customId": {
        "style": {},
        "isVisible": true,
        "order": 0
      },
      "assignee": {
        "style": {},
        "order": 6,
        "isVisible": true
      },
      "lane": {
        "style": {},
        "isVisible": true,
        "order": 4
      },
      "status": {
        "isVisible": true,
        "style": {},
        "order": 3
      },
      "customer": {
        "style": {},
        "order": 7,
        "isVisible": true
      },
      "totalAmountBeforeDiscount": {
        "isVisible": true,
        "style": {},
        "order": 13
      },
      "totalAmountBeforeVat": {
        "isVisible": true,
        "style": {},
        "order": 15
      },
      "grandTotal": {
        "style": {},
        "order": 11,
        "isVisible": true
      },
      "description": {
        "isVisible": true,
        "style": {},
        "order": 16
      },
      "hashtags": {
        "isVisible": true,
        "style": {},
        "order": 9
      },
      "company": {
        "style": {},
        "isVisible": true,
        "order": 8
      },
      "priority": {
        "order": 10,
        "style": {},
        "isVisible": true
      }
    },
    "customerProfileCardsConfig_xsv2WkW3P0gny7INLuj4": {
      "hashtags": {
        "style": {},
        "isVisible": true,
        "order": 9
      },
      "customer": {
        "order": 7,
        "style": {},
        "isVisible": true
      },
      "totalAmountBeforeVat": {
        "isVisible": true,
        "style": {},
        "order": 15
      },
      "title": {
        "style": {},
        "order": 1,
        "isVisible": true
      },
      "totalAmountAfterDiscount": {
        "isVisible": true,
        "style": {},
        "order": 14
      },
      "netTotal": {
        "style": {},
        "isVisible": true,
        "order": 12
      },
      "description": {
        "style": {},
        "order": 16,
        "isVisible": true
      },
      "lane": {
        "order": 4,
        "style": {},
        "isVisible": true
      },
      "company": {
        "isVisible": true,
        "style": {},
        "order": 8
      },
      "grandTotal": {
        "order": 11,
        "style": {},
        "isVisible": true
      },
      "status": {
        "isVisible": true,
        "order": 3,
        "style": {}
      },
      "todos": {
        "isVisible": true,
        "order": 17,
        "style": {}
      },
      "totalAmountBeforeDiscount": {
        "style": {},
        "order": 13,
        "isVisible": true
      },
      "boardName": {
        "isVisible": true,
        "style": {},
        "order": 2
      },
      "assignee": {
        "style": {},
        "isVisible": true,
        "order": 6
      },
      "priority": {
        "isVisible": true,
        "style": {},
        "order": 10
      },
      "dueDate": {
        "isVisible": true,
        "order": 5,
        "style": {}
      },
      "customId": {
        "isVisible": true,
        "order": 0,
        "style": {}
      }
    },
    "customerProfileCardsConfig_P8b7ATcEzYlePEJwT1Zl": {
      "customId": {
        "isVisible": true,
        "order": 0,
        "style": {}
      },
      "title": {
        "isVisible": true,
        "order": 1,
        "style": {}
      },
      "boardName": {
        "isVisible": true,
        "order": 2,
        "style": {}
      },
      "status": {
        "isVisible": true,
        "order": 3,
        "style": {}
      },
      "lane": {
        "isVisible": true,
        "order": 4,
        "style": {}
      },
      "dueDate": {
        "isVisible": true,
        "order": 5,
        "style": {}
      },
      "assignee": {
        "isVisible": true,
        "order": 6,
        "style": {}
      },
      "customerInterest": {
        "isVisible": true,
        "order": 7,
        "style": {}
      },
      "customer": {
        "isVisible": true,
        "order": 8,
        "style": {}
      },
      "company": {
        "isVisible": true,
        "order": 9,
        "style": {}
      },
      "hashtags": {
        "isVisible": true,
        "order": 10,
        "style": {}
      },
      "priority": {
        "isVisible": true,
        "order": 11,
        "style": {}
      },
      "grandTotal": {
        "isVisible": true,
        "order": 12,
        "style": {}
      },
      "netTotal": {
        "isVisible": true,
        "order": 13,
        "style": {}
      },
      "totalAmountBeforeDiscount": {
        "isVisible": true,
        "order": 14,
        "style": {}
      },
      "totalAmountAfterDiscount": {
        "isVisible": true,
        "order": 15,
        "style": {}
      },
      "totalAmountBeforeVat": {
        "isVisible": true,
        "order": 16,
        "style": {}
      },
      "description": {
        "isVisible": true,
        "order": 17,
        "style": {}
      },
      "todos": {
        "isVisible": true,
        "order": 18,
        "style": {}
      }
    },
    "customerProfileCardsConfig_YRYXfnlhznwxIY4GcPHg": {
      "customId": {
        "isVisible": true,
        "order": 0,
        "style": {}
      },
      "title": {
        "isVisible": true,
        "order": 1,
        "style": {}
      },
      "boardName": {
        "isVisible": true,
        "order": 2,
        "style": {}
      },
      "status": {
        "isVisible": true,
        "order": 3,
        "style": {}
      },
      "lane": {
        "isVisible": true,
        "order": 4,
        "style": {}
      },
      "dueDate": {
        "isVisible": true,
        "order": 5,
        "style": {}
      },
      "assignee": {
        "isVisible": true,
        "order": 6,
        "style": {}
      },
      "customerInterest": {
        "isVisible": true,
        "order": 7,
        "style": {}
      },
      "customer": {
        "isVisible": true,
        "order": 8,
        "style": {}
      },
      "company": {
        "isVisible": true,
        "order": 9,
        "style": {}
      },
      "hashtags": {
        "isVisible": true,
        "order": 10,
        "style": {}
      },
      "priority": {
        "isVisible": true,
        "order": 11,
        "style": {}
      },
      "grandTotal": {
        "isVisible": true,
        "order": 12,
        "style": {}
      },
      "netTotal": {
        "isVisible": true,
        "order": 13,
        "style": {}
      },
      "totalAmountBeforeDiscount": {
        "isVisible": true,
        "order": 14,
        "style": {}
      },
      "totalAmountAfterDiscount": {
        "isVisible": true,
        "order": 15,
        "style": {}
      },
      "totalAmountBeforeVat": {
        "isVisible": true,
        "order": 16,
        "style": {}
      },
      "description": {
        "isVisible": true,
        "order": 17,
        "style": {}
      },
      "todos": {
        "isVisible": true,
        "order": 18,
        "style": {}
      }
    }
  },
  "displayName": "Mini Mark",
  "lastDeviceId": "BE2A.250530.026.F3",
  "lastPlatform": "android",
  "fcmToken": "fKDy4rmaS5W1oWnNCSxJWs:APA91bGfUkGdNvaFghAD29QvE16mKuQVV0ZxeoSS--DwXzQPynwhisI9C7y1KV5ckc_l43S18uLg5Q0EzWJIKZKjIl7SXpsALIoLFSb4Stk5-brDZmKkMt0",
  "fcmTokenUpdatedAt": "2025-09-02T02:46:08.815Z",
  "customId": "",
  "lastActiveWorkspaceId": "JhHrtfsq5OvHZAowukfh",
  "phoneNumber": "",
  "docPhoneNumber": "0891108590",
  "docDisplayName": "ธานินทร์",
  "notificationSettings": {
    "quietHours": {
      "enabled": true,
      "startTime": "10:00",
      "endTime": "17:00",
      "days": [
        3
      ]
    },
    "onComment": {
      "enabled": true,
      "web": true,
      "mobilePush": true,
      "email": "off"
    },
    "onStatusChange": {
      "enabled": true,
      "email": "off",
      "mobilePush": true,
      "web": true
    },
    "onDueDateReminder": {
      "enabled": true,
      "notifyAtTime": "09:00",
      "email": "off",
      "web": true,
      "mobilePush": true
    },
    "onTodoReminder": {
      "enabled": true,
      "remindBeforeMinutes": 15,
      "mobilePush": true,
      "web": true,
      "email": "off"
    },
    "onCardAssignment": {
      "enabled": true,
      "mobilePush": false,
      "web": true,
      "email": "off"
    },
    "onTagged": {
      "enabled": true,
      "web": true,
      "mobilePush": true,
      "email": "off"
    },
    "onApprovalRequest": {
      "enabled": true,
      "mobilePush": true,
      "web": true,
      "email": "off"
    },
    "onApprovalDecision": {
      "enabled": true,
      "web": true,
      "mobilePush": true,
      "email": "off"
    },
    "onNewChatReceived": {
      "enabled": true,
      "email": "off",
      "web": true,
      "mobilePush": true
    },
    "onChatAssigned": {
      "enabled": true,
      "email": "off",
      "web": true,
      "mobilePush": true
    },
    "onAddedToWorkspace": {
      "enabled": true,
      "web": true,
      "mobilePush": true,
      "email": "off"
    },
    "digestSettings": {
      "frequency": "daily"
    }
  },
  "role": "editor",
  "updatedAt": "2025-09-01T10:36:03.929Z"
}
```

#### workspaces/{WorkspaceId}/quotationTemplates/{Quotation template uids}
example data:
```
{
  "headers": [
    {
      "id": "header-ms-1",
      "height": 100,
      "displayOn": "all_pages",
      "components": [
        {
          "id": "comp-ms-bg",
          "type": "shape",
          "x": 0,
          "y": 0,
          "width": 800,
          "height": 100,
          "content": "",
          "style": {
            "zIndex": 0,
            "backgroundColor": "#4f46e5"
          }
        },
        {
          "id": "comp-ms-logo",
          "type": "image",
          "x": 40,
          "y": 30,
          "width": 120,
          "height": 40,
          "content": "{company.logoUrl}",
          "style": {
            "zIndex": 1,
            "objectFit": "contain"
          }
        }
      ]
    }
  ],
  "footers": [
    {
      "id": "footer-ms-1",
      "height": 80,
      "displayOn": "all_pages",
      "components": [
        {
          "id": "comp-ms-footer-bg",
          "type": "shape",
          "x": 0,
          "y": 0,
          "width": 800,
          "height": 80,
          "content": "",
          "style": {
            "zIndex": 0,
            "backgroundColor": "#f3f4f6"
          }
        },
        {
          "id": "comp-ms-footer-text",
          "type": "text",
          "x": 40,
          "y": 20,
          "width": 710,
          "height": 40,
          "content": "<p style=\"font-size:12px; color:#555; text-align:center;\">ขอบคุณที่ให้ความไว้วางใจ | Thank you for your business!<br/>{company.name} | {company.phone}</p>",
          "style": {
            "zIndex": 1
          }
        }
      ]
    }
  ],
  "name": "Modern Standard Quotation",
  "createdAt": 1756883171344,
  "page": {
    "width": "210mm",
    "height": "297mm",
    "fontFamily": "Kanit",
    "pageNumbering": {
      "enabled": true,
      "format": "Page {page} of {total}",
      "position": "bottom_right"
    }
  },
  "body": {
    "components": [
      {
        "id": "comp-ms-customer",
        "type": "text",
        "x": 40,
        "y": 120,
        "width": 300,
        "height": 60,
        "content": "<p style=\"color:#666;\">Prepared for:</p><h2 style=\"font-size: 16px; font-weight: bold;\">{customer.name}</h2>",
        "style": {
          "zIndex": 1
        }
      },
      {
        "id": "comp-ms-table",
        "type": "table",
        "x": 32,
        "y": 172.99996948242188,
        "width": 725,
        "height": 575,
        "columns": [
          {
            "id": "zPaHS",
            "label": "สินค้า/บริการ",
            "type": "product_field",
            "sourceField": "name",
            "isVisible": true,
            "isEditable": true,
            "order": 0,
            "width": "50%",
            "style": {
              "isBold": true,
              "fontSize": 13
            }
          },
          {
            "id": "W_g5e",
            "label": "จำนวน",
            "type": "predefined",
            "predefinedField": "quantity",
            "isVisible": true,
            "isEditable": true,
            "order": 1,
            "width": "15%",
            "align": "center",
            "style": {
              "fontSize": 13
            }
          },
          {
            "id": "Ymno3",
            "label": "ราคาต่อหน่วย",
            "type": "product_field",
            "sourceField": "pricePerUnit",
            "isVisible": true,
            "isEditable": true,
            "order": 2,
            "width": "15%",
            "align": "right",
            "style": {
              "fontSize": 13
            }
          },
          {
            "id": "ydgIX",
            "label": "รวม",
            "type": "predefined",
            "predefinedField": "line_total",
            "isVisible": true,
            "isEditable": false,
            "order": 3,
            "width": "20%",
            "align": "right",
            "style": {
              "fontSize": 13
            }
          },
          {
            "id": "yijiNdwuqjPqoM468sq_W",
            "label": "New Column",
            "type": "user_input",
            "isVisible": true,
            "isEditable": true,
            "order": 4
          }
        ],
        "style": {
          "zIndex": 1,
          "headerColor": "#4f46e5",
          "textColor": "#ffffff",
          "headerHeight": 40
        },
        "content": ""
      },
      {
        "id": "comp-ms-summary",
        "type": "summary",
        "x": 450,
        "y": 720,
        "width": 300,
        "height": 150,
        "content": "",
        "style": {
          "zIndex": 1
        },
        "summaryFields": {
          "subtotal": true,
          "discount": true,
          "vat": true,
          "grandTotal": true
        }
      },
      {
        "id": "comp-LX-QH6m7CFDce-G5DTfLR",
        "type": "summary",
        "x": 59.782470703125,
        "y": 696.6296081542969,
        "width": 251,
        "height": 200,
        "content": "",
        "style": {
          "zIndex": 7
        },
        "summaryFields": {
          "subtotal": true,
          "discount": true,
          "totalAfterDiscount": false,
          "vat": true,
          "grandTotal": true,
          "wht": false,
          "netTotal": false,
          "deposit": false,
          "shipping": false,
          "amountDue": false
        }
      }
    ]
  },
  "updatedAt": 1756883423992
}
```
### workspaces/{Workspace Id}/quotationTemplates/{templateIds}
example data:
```
{
  "page": {
    "width": "210mm",
    "height": "297mm",
    "fontFamily": "Sarabun",
    "pageNumbering": {
      "enabled": true,
      "format": "Page {page} of {total}",
      "position": "bottom_right"
    }
  },
  "headers": [
    {
      "id": "header-MrTVY-f21rRbaXQXc42Kl",
      "height": 140,
      "displayOn": "all_pages",
      "components": [
        {
          "id": "comp-eSTmpkGb7bMTUdId3Oxvv",
          "type": "image",
          "x": 40,
          "y": 30,
          "width": 120,
          "height": 80,
          "content": "{company.logoUrl}",
          "style": {
            "zIndex": 1,
            "objectFit": "contain"
          }
        }
      ]
    },
    {
      "id": "header-3UUno2DcjQTTlvFtUP_HA",
      "height": 120,
      "displayOn": "first_page_only",
      "components": [
        {
          "id": "comp-nIcCGfCZNh222I72wCYWj",
          "type": "text",
          "x": 40,
          "y": 10,
          "width": 350,
          "height": 100,
          "content": "<p style=\"font-size: 14px; font-weight: bold;\">{company.name}</p><p style=\"font-size: 12px; color: #4b5563;\">{company.address}</p><p style=\"font-size: 12px; color: #4b5563;\">เลขประจำตัวผู้เสียภาษี: {company.taxId}</p>",
          "style": {
            "zIndex": 1,
            "lineHeight": "1.5"
          }
        },
        {
          "id": "comp-zmxwU7Uh0eWcQX1nq0kVN",
          "type": "shape",
          "x": 40,
          "y": 118,
          "width": 710,
          "height": 2,
          "style": {
            "zIndex": 0,
            "backgroundColor": "#e5e7eb"
          },
          "content": ""
        },
        {
          "id": "comp-cpq-title",
          "type": "text",
          "x": 450,
          "y": 40,
          "width": 300,
          "height": 80,
          "content": "<h1 style=\"font-size: 28px; font-weight: bold; color: #111827;\">ใบเสนอราคา</h1><p style=\"font-size: 14px; color: #4b5563;\">QUOTATION</p>",
          "style": {
            "zIndex": 1,
            "textAlign": "right"
          }
        },
        {
          "id": "comp-cpq-docinfo",
          "type": "text",
          "x": 450,
          "y": 120,
          "width": 300,
          "height": 100,
          "content": "<table style=\"font-size: 12px; width: 100%;\"><tr><td style=\"font-weight: bold; text-align: right; padding: 2px 8px;\">เลขที่:</td><td style=\"text-align: right; padding: 2px;\">{quotation.docNo}</td></tr><tr><td style=\"font-weight: bold; text-align: right; padding: 2px 8px;\">วันที่:</td><td style=\"text-align: right; padding: 2px;\">{quotation.createdAt}</td></tr><tr><td style=\"font-weight: bold; text-align: right; padding: 2px 8px;\">ยืนราคาถึง:</td><td style=\"text-align: right; padding: 2px;\">{quotation.validUntil}</td></tr></table>",
          "style": {
            "zIndex": 1
          }
        }
      ]
    }
  ],
  "footers": [
    {
      "id": "footer-lF5tHZ5UM0cdgbdk-Ad2N",
      "height": 150,
      "displayOn": "last_page_only",
      "components": [
        {
          "id": "comp-P05USKavcBHzGW8AOsS_3",
          "type": "text",
          "x": 40,
          "y": 20,
          "width": 350,
          "height": 100,
          "content": "<p style=\"font-weight: bold;\">การชำระเงิน:</p><p>{payment.bankName}</p><p>ชื่อบัญชี: {payment.accountName}</p><p>เลขที่บัญชี: {payment.accountNumber}</p>",
          "style": {
            "zIndex": 1,
            "fontSize": 12,
            "lineHeight": "1.6"
          }
        },
        {
          "id": "comp-Zc9L0oi9VDw8qmTyX_vtZ",
          "type": "text",
          "x": 40,
          "y": 100,
          "width": 350,
          "height": 40,
          "content": "<p style=\"font-weight: bold;\">หมายเหตุ:</p><p style=\"color: #4b5563;\">{document.notes}</p>",
          "style": {
            "zIndex": 1,
            "fontSize": 12,
            "lineHeight": "1.6"
          }
        },
        {
          "id": "comp-Tikiaj8UYyJHCYmpbqkMs",
          "type": "signature",
          "x": 500,
          "y": 30,
          "width": 200,
          "height": 80,
          "signatureRoleName": "ผู้อนุมัติ",
          "style": {
            "zIndex": 1
          },
          "content": ""
        }
      ]
    }
  ],
  "name": "Classic Professional Quotation",
  "createdAt": 1756810137895,
  "body": {
    "components": [
      {
        "id": "comp-AfSgUm9gqmAxQB5YlfxPe",
        "type": "text",
        "x": 40,
        "y": 10,
        "width": 350,
        "height": 80,
        "content": "<p style=\"font-size: 12px; color: #4b5563;\">เรียน:</p><p style=\"font-size: 14px; font-weight: bold;\">{customer.name}</p><p style=\"font-size: 12px; color: #4b5563;\">{customer.address}</p><p style=\"font-size: 12px; color: #4b5563;\">เลขประจำตัวผู้เสียภาษี: {customer.nationalId}</p>",
        "style": {
          "zIndex": 1,
          "lineHeight": "1.5"
        }
      },
      {
        "id": "comp-z8C-UtlynKfzHSghFP0rG",
        "type": "table",
        "x": 40,
        "y": 100,
        "width": 710,
        "height": 500,
        "columns": [
          {
            "id": "J6A6z",
            "label": "รายการ",
            "type": "product_field",
            "sourceField": "name",
            "isVisible": true,
            "isEditable": false,
            "order": 0,
            "width": "40%",
            "style": {
              "isBold": true
            }
          },
          {
            "id": "n6BTF",
            "label": "จำนวน",
            "type": "predefined",
            "predefinedField": "quantity",
            "isVisible": true,
            "isEditable": true,
            "order": 1,
            "width": "15%",
            "align": "center"
          },
          {
            "id": "MdCPU",
            "label": "ราคา/หน่วย",
            "type": "product_field",
            "sourceField": "pricePerUnit",
            "isVisible": true,
            "isEditable": true,
            "order": 2,
            "width": "20%",
            "align": "right"
          },
          {
            "id": "3bVWP",
            "label": "ยอดรวม",
            "type": "predefined",
            "predefinedField": "line_total",
            "isVisible": true,
            "isEditable": false,
            "order": 3,
            "formula": "{quantity} * {pricePerUnit}",
            "width": "25%",
            "align": "right"
          }
        ],
        "style": {
          "zIndex": 1,
          "headerColor": "#f3f4f6",
          "headerHeight": 35,
          "borderColor": "#d1d5db",
          "headerStyle": {
            "isBold": true
          }
        },
        "content": ""
      },
      {
        "id": "comp-cpq-summary",
        "type": "summary",
        "x": 450,
        "y": 599,
        "width": 300,
        "height": 150,
        "content": "",
        "style": {
          "zIndex": 1
        },
        "summaryFields": {
          "subtotal": true,
          "discount": true,
          "vat": true,
          "grandTotal": true,
          "wht": true,
          "netTotal": true
        }
      }
    ]
  },
  "updatedAt": 1756810146574
}
```

**remark**
- rule of generate "docNo" you can watch file `lib\core\services\id_generation_service.dart` example rule of this docNo
```
"quotation": {
  "prefix": "EST",
  "dateFormat": "YYMMDD",
  "separator": "-",
  "minLength": 4,
  "generationMode": "auto-editable"
}
```
```
"invoice": {
  "prefix": "INV",
  "minLength": 4,
  "separator": "-",
  "generationMode": "auto-editable",
  "dateFormat": "YYMMDD"
}
```
```
"receipt": {
    "generationMode": "auto-editable"
    "minLength": 4
    "separator": "-"
    "dateFormat": "YYMMDD"
    "prefix": "RE"
}
```

**how to find workspaceId?**
this is example code how to get workspaceId
```
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/repositories/firestore_repository.dart'; //file path lib\data\repositories\firestore_repository.dart

Future<void> _initializeUserAndWorkspace() async {
    try {
      // Get current user ID from Firebase Auth
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ No authenticated user found');
        return;
      }
      
      _currentUserId = currentUser.uid;
      print('👤 Initializing company page with user: $_currentUserId');
      
      // Get user's workspaces
      print('📋 Fetching user workspaces...');
      final workspaces = await _repository.getUserWorkspaces(_currentUserId);
      
      print('📋 User workspaces loaded: ${workspaces.length} workspaces');
      
      if (workspaces.isNotEmpty) {
        // Use the first workspace as default
        final firstWorkspace = workspaces.first;
        _currentWorkspaceId = firstWorkspace['id'] as String;
        
        print('✅ Company page initialized with workspace: ${firstWorkspace['name']}');
        
        // Initialize form and load hashtags
        _initializeForm();
        await _loadHashtags();
      } else {
        print('⚠️ No workspaces found for user: $_currentUserId');
      }
    } catch (e) {
      print('❌ Failed to initialize user and workspace: $e');
    }
  }
  ```

## CONSIDERATIONS:
- *important* You don't need to explain what you did. I don't want to know, it's a waste of time. Focus on editing the file to meet the task I gave you.
- First read `lib\features\document\DOCUMENT_SUMMARY.md` file for review your memory and brainstrom your self. 
- For better answer me please read your mememory inside file `lib\features\document\DOCUMENT_SUMMARY.md`
- To give me better answers, please write a summary or review or document of each response to a file named `lib\features\document\DOCUMENT_SUMMARY.md`, so AI can remember and improve my prompts next time.
- *important* I'm giving you the Document functionality, so try not to mess with the other features.