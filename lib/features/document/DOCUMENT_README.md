# Product System

## Overview
document system is about ใบเสนอราคา, ใบวางบิล, ใบแจ้งหนี้

## FEATURE:
- have center page that can go from main application footer menu "เอกสาร" that have 3 menu inside Quotations, Invoices, Receipts
- list of Quotations (ใบเสนอราคา)
- list of Invoices (ใบวางบิล)
- list of Receipts (ใบแจ้งหนี้)
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
- main folder of product system is `lib\features\document`

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
  "type": "INV", //'QT' | 'INV' | 'RT' | 'DEP'
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
  "validUntil": 1756573200000,
  "vatAmount": 0.8400000000000001,
  "whtAmount": 0.96
}```

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
- First read `lib\features\products\PRODUCT_SUMMARY.md` file for review your memory and brainstrom your self. 
- For better answer me please read your mememory inside file `lib\features\products\PRODUCT_SUMMARY.md`
- To give me better answers, please write a summary or review or document of each response to a file named `lib\features\products\PRODUCT_SUMMARY.md`, so AI can remember and improve my prompts next time.
- *important* I'm giving you the Product functionality, so try not to mess with the other features.