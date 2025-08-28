# Product System

## Overview
product is about product that have is in this system that can use for reference data in another page

## FEATURE:
- list of product card
- add product
- edit product
- delete product
- preview product
- upload product image and preview have cover image and set of images

# PROJECT STRUCTURE:
- main folder of product system is `lib\features\products`

## DOCUMENTATION:
- `get: ^4.6.6` - State management and dependency injection
- `flutter` - UI framework
- `firebase_core`: ^3.4.0
- `firebase_auth`: ^5.3.0
- `cloud_firestore`: ^5.4.0
- `dio`

## RELATED DATABASE
#### workspaces/{workspace UIDs}/products/{Product UIDs}
example data:
```{
  "status": "active", //data have 3 types draft,active,discontinued //require field
  "showInCatalog": true,
  "price": 50, //require field
  "customFields": [],
  "imageUrl": "https://firebasestorage.googleapis.com/v0/b/kanbanflow-iq93h.firebasestorage.app/o/products%2Fnew_product%2F1756197318295-480829658_3775969812713125_2471259005229540379_n.jpg%2F1756197318295-480829658_3775969812713125_2471259005229540379_n.jpg?alt=media&token=60b6499c-d94c-478b-a1bc-9e0d43f713bd", //CoverImage
  "name": "Tests product1", //require field
  "imageSet": [
    "https://firebasestorage.googleapis.com/v0/b/kanbanflow-iq93h.firebasestorage.app/o/product..."
    "https://firebasestorage.googleapis.com/v0/b/kanbanflow-iq93h.firebasestorage.app/o/product..."
    "https://firebasestorage.googleapis.com/v0/b/kanbanflow-iq93h.firebasestorage.app/o/product..."
  ], //other image
  "unit": "ชิ้น",
  "description": "Description Here",
  "hashtags": [
    {
      "id": "more",
      "text": "more",
      "color": "#d946ef"
    },
    {
      "id": "tests",
      "text": "✅tests@🌚",
      "color": "#3b82f6"
    }
  ],
  "barcode": "UPC",
  "costPrice": 500,
  "initialStock": 0,
  "reorderLevel": 0,
  "targetStockLevel": 0,
  "features": [],
  "sku": "P-250826-0001",
  "workspaceId": "5hMae0Og3XYVtM0T9XQR",
  "createdAt": 1756197393646,
  "updatedAt": 1756197393646,
  "searchableKeywords": [
    "tests",
    "product1",
    "p-250826-0001",
    "description here",
    "more",
    "✅tests@🌚"
  ]
}```

**remark**
- rule of generate "sku" you can watch file `lib\core\services\id_generation_service.dart`

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