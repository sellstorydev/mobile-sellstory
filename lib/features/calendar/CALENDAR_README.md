# Calendar System

## Overview
Calendar is about track todo of user or track jobcard on the board
focus track todo of each jobcard

## FEATURE:
- have 3 view mode
    - month
    - week
    - day
- have 3 view filter type
    - all
    - jobcard only
    - todo only
- have filter
    - filter from Assignees
- list of event in that day

## UI Guide
- calendar is full page
- in calendar page order ui from top to bottom
    - view type filter
    - Assignees filter
    - calendar for choose date
    - events list on that choose date

**remark**
events list show jobcard detail and todo in that date

**EVENT CARD FEATURES:**
- **Jobcard Events**: Show all associated todos within the event card
  - Displays todos list with completion status, priority, and status indicators
  - Each todo shows checkbox, title, priority chip, and status chip
  - Completed todos show strikethrough text and filled checkbox
- **Todo Events**: Show individual todo details with parent jobcard reference
- **Navigation**: Click jobcard events to view full jobcard details
- **Visual Indicators**: Color-coded priority and status for easy identification

## PROJECT STRUCTURE:
- main folder of product system is `lib\features\calendar`

## DOCUMENTATION:
- `get: ^4.6.6` - State management and dependency injection
- `flutter` - UI framework
- `firebase_core`: ^3.4.0
- `firebase_auth`: ^5.3.0
- `cloud_firestore`: ^5.4.0
- `dio`

## RELATED DATABASE
#### workspaces/{workspace UIDs}/cards{Card UIDs}
example data: can read file `lib\domain\entities\job_card.dart`

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
- First read `lib\features\calendar\CALENDAR_SUMMARY.md` file for review your memory and brainstrom your self. 
- For better answer me please read your mememory inside file `lib\features\calendar\CALENDAR_SUMMARY.md`
- To give me better answers, please write a summary or review or document of each response to a file named `lib\features\calendar\CALENDAR_SUMMARY.md`, so AI can remember and improve my prompts next time.
- *important* I'm giving you the Product functionality, so try not to mess with the other features.