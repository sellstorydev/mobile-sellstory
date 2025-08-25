# Firestore Database Structure

This document outlines the Firestore database structure used in the SellStory mobile application, based on the backup data from `firestore/backup-2025-08-25T02-47-08.json`.

## Overview

The database follows a hierarchical structure with the following main collections:
- **users** - User profiles and authentication data
- **presences** - User online status and activity tracking
- **workspaces** - Organization/team workspaces with nested subcollections

## Root Collections

### 1. `users` Collection
Stores user profile information and workspace memberships.

```json
{
  "uid": "string",                    // Firebase Auth UID (document ID)
  "email": "string",                  // User email address
  "displayName": "string",            // Display name
  "photoURL": "string | null",        // Profile photo URL
  "language": "string",               // Preferred language (e.g., "en", "th")
  "customId": "string",               // Custom user identifier
  "workspaces": [                     // Array of workspace memberships
    {
      "id": "string",                 // Workspace ID
      "name": "string",               // Workspace name
      "role": "string"                // User role: "owner", "admin", "member"
    }
  ],
  "viewSettings": {                   // UI configuration per board
    "kanbanCardDisplayFieldsConfig_[boardId]": {
      "fieldName": {
        "isVisible": "boolean",
        "order": "number",
        "style": "object"
      }
    },
    "customerProfileCardsConfig_[boardId]": {
      // Similar structure for customer profile cards
    }
  }
}
```

### 2. `presences` Collection
Tracks user online status and current board activity.

```json
{
  "uid": "string",                    // Firebase Auth UID (document ID)
  "lastSeen": "number",               // Timestamp of last activity
  "activeBoardId": "string | null"    // Currently active board ID
}
```

## Workspace Subcollections

Each workspace has the following subcollections under `workspaces/{workspaceId}/`:

### 1. `boards` Subcollection
Stores board configuration and metadata.

```json
{
  "name": "string",                   // Board name (e.g., "My First Board")
  "workspaceId": "string",            // Parent workspace ID
  "createdBy": "string",              // Creator user ID
  "members": [                        // Board members with full user data
    {
      "uid": "string",
      "email": "string",
      "displayName": "string",
      "photoURL": "string | null",
      "customId": "string",
      "role": "string",               // "owner", "admin", "member"
      "language": "string",
      "workspaces": "array"
    }
  ],
  "memberUids": ["string"],           // Array of member UIDs for quick lookup
  "lanes": "array"                    // Board lanes configuration
}
```

### 2. `lanes` Subcollection
Defines the Kanban board lanes/columns.

```json
{
  "boardId": "string",                // Parent board ID
  "workspaceId": "string",            // Parent workspace ID
  "name": "string",                   // Lane name (e.g., "To Do", "In Progress", "Done")
  "order": "number",                  // Display order (0, 1, 2, ...)
  "cards": "array",                   // Card IDs in this lane (may be empty if using separate cards collection)
  "hasMoreCards": "boolean"           // Pagination flag for large card sets
}
```

### 3. `cards` Subcollection
Stores job cards/tasks with detailed information.

```json
{
  "title": "string",                  // Card title
  "description": "string",            // Rich text description (HTML format)
  "assignedTo": "string",             // Assigned user UID (Firebase Auth UID)
  "status": "string",                 // Current status (e.g., "Pending", "In Progress", "Done")
  "customId": "string",               // Custom job ID (e.g., "JB-220825-0009")
  "boardId": "string",                // Parent board ID
  "workspaceId": "string",            // Parent workspace ID
  "laneId": "string",                 // Current lane ID
  "customer": "string",               // Customer name
  "customerId": "string | null",      // Customer document ID reference
  "createdBy": "string",              // Creator user ID
  "updatedBy": "string",              // Last updater user ID
  "updatedByDisplayName": "string",   // Last updater display name
  "createdAt": "timestamp",           // Creation timestamp (Firestore Timestamp format)
  "updatedAt": "timestamp | number",  // Last update timestamp
  "order": "number",                  // Position within lane
  "amount": "number",                 // Card amount/value (default: 0)
  "dueDate": "timestamp | null",      // Due date
  "badges": ["string"],               // Array of badge labels
  "watchers": ["string"],             // Array of user IDs watching this card
  "todos": [                          // Todo items within the card
    {
      "id": "string",
      "text": "string",
      "completed": "boolean",
      "createdAt": "number"
    }
  ],
  "notes": [                          // Notes/comments on the card
    {
      "id": "string",
      "text": "string",
      "createdBy": "string",
      "createdAt": "number"
    }
  ],
  "customFields": [                   // Custom field values
    {
      "id": "string",
      "name": "string",
      "value": "any",
      "type": "string"
    }
  ],
  "expenses": [                       // Expense tracking
    {
      "id": "string",
      "description": "string",
      "amount": "number",
      "date": "timestamp",
      "category": "string"
    }
  ],
  "hashtag": "string | null",         // Single hashtag field
  "company": "string | null"          // Associated company name
}
```

### 4. `logs` Subcollection
System and integration logs for debugging and audit trails.

```json
{
  "level": "string",                  // Log level: "DEBUG", "INFO", "WARN", "ERROR"
  "context": "string",                // Context category (e.g., "LINE_CONNECTION", "SEND_MESSAGE")
  "message": "string",                // Log message
  "workspaceId": "string",            // Associated workspace
  "timestamp": "number",              // When the log was created
  "data": "object | null",            // Additional structured data
  "chatroomId": "string | null",      // Associated chatroom if applicable
  "userId": "string | null"           // Associated user if applicable
}
```

### 5. `customers` Subcollection
Customer profile information and contact details.

```json
{
  "name": "string",                   // Customer name
  "email": "string | null",           // Customer email
  "phone": "string | null",           // Customer phone
  "company": "string | null",         // Customer company
  "address": "string | null",         // Customer address
  "notes": "string",                  // Additional notes
  "createdBy": "string",              // Creator user ID
  "createdAt": "number",              // Creation timestamp
  "updatedAt": "number",              // Last update timestamp
  "tags": ["string"],                 // Customer tags
  "customFields": [                   // Custom customer fields
    {
      "id": "string",
      "name": "string",
      "value": "any",
      "type": "string"
    }
  ]
}
```

### 6. `companies` Subcollection
Company/organization profiles associated with customers.

```json
{
  "name": "string",                   // Company name
  "description": "string",            // Company description
  "industry": "string | null",        // Industry type
  "website": "string | null",         // Company website
  "logo": "string | null",            // Logo URL
  "address": "string | null",         // Company address
  "createdBy": "string",              // Creator user ID
  "createdAt": "number",              // Creation timestamp
  "updatedAt": "number"               // Last update timestamp
}
```

## Data Relationships

### Hierarchy
```
users/
├── {userId} (user profile)

presences/
├── {userId} (user presence)

workspaces/
├── {workspaceId}/
    ├── boards/
    │   ├── {boardId} (board config)
    ├── lanes/
    │   ├── {laneId} (lane config)
    ├── cards/
    │   ├── {cardId} (job card details)
    ├── customers/
    │   ├── {customerId} (customer profile)
    ├── companies/
    │   ├── {companyId} (company profile)
    └── logs/
        ├── {logId} (system logs)
```

### Key Relationships
- **User ↔ Workspace**: Many-to-many via `users.workspaces` array
- **Workspace → Board**: One-to-many
- **Board → Lane**: One-to-many via `lanes.boardId`
- **Lane → Card**: One-to-many via `cards.laneId`
- **User → Card**: One-to-many via `cards.assignedTo`
- **Customer → Card**: One-to-many via `cards.customer`
- **Company → Customer**: One-to-many relationship

## Search and Filter Fields

Based on the search and filter implementation, the following fields are used:

### Search Fields (searchable in job cards):
- `title` - Job title
- `description` - Job description  
- `customId` - Custom job ID (e.g., "JB-220825-0009")
- `customer` - Customer name
- `assignee` - Assigned user UID (maps to `assignedTo` in Firestore)
- `status` - Current status
- `updatedByDisplayName` - Last updater display name
- `company` - Associated company name
- `hashtag` - Single hashtag field

### Filter Fields:
- `assignee` - Filter by assigned user UID (multi-select)
- `customer` - Filter by customer name (multi-select, partial matching)

### Display Name Mapping:
- `assignedTo` (UID) → `displayName` via board.members array
- Board members contain: `uid`, `displayName`, `email`, `role`

## Security Considerations

- Users can only access workspaces they are members of
- Role-based permissions: `owner` > `admin` > `member`
- All operations should be validated against user workspace membership
- Sensitive data like customer information requires appropriate access controls

## Performance Notes

- Large card collections use pagination (`hasMoreCards` flag)
- User display configurations are stored per board for customization
- Logs are separated into their own subcollection to avoid performance impact
- Consider implementing data archiving for old logs and completed cards

## Migration Notes

When updating this database structure:
1. Always maintain backward compatibility
2. Use database migrations for schema changes
3. Update both read/write operations simultaneously
4. Test with production data backup before deployment
5. Consider impact on mobile app offline capabilities
