# Customer System

## Overview
Customer is about company have customer for sale manage and create new customer

## FEATURE:
- CRUD about customer
- Customer system sync database with sale, hashtag, company, customfrom (some database was not created), sometime not sync

# PROJECT STRUCTURE:
- main file is in folder `lib\features\customers`
- firebase database structure is in file `lib\features\customers\DATABASE.md`

## DOCUMENTATION:
- `get: ^4.6.6` - State management and dependency injection
- `flutter` - UI framework
- `firebase_core`: ^3.4.0
- `firebase_auth`: ^5.3.0
- `cloud_firestore`: ^5.4.0
- `dio`

## FORM FIELDS:
- **Assignees**: Multi-select dropdown for workspace members
- **Customer Type**: Dropdown (Customer/Lead)
- **Hashtags**: Multi-select with search functionality
- **Source**: Dropdown (dynamic from database)
- **National ID**: Text input
- **Custom ID**: Text input (auto-generated for new customers, editable for existing)
- **Prefix**: Text input
- **Name**: Text input (required)
- **Gender**: Dropdown (Male/Female/Other)
- **Emails**: Multiple entries with add/edit/delete
- **Phones**: Multiple entries with add/edit/delete
- **Address**: Text area
- **Location Fields**: All text inputs (no dropdowns):
  - ตำบล/แขวง (Subdistrict)
  - อำเภอ/เขต (District)
  - จังหวัด (Province)
  - รหัสไปรษณีย์ (Postal Code)
  - ประเทศ (Country)
- **Company**: Multi-select company picker with search functionality

## CONSIDERATIONS:
- *important* You don't need to explain what you did. I don't want to know, it's a waste of time. Focus on editing the file to meet the task I gave you.
- First read `lib\features\customers\SUMMARY.md` file for review your memory and brainstrom your self. 
- For better answer me please read your mememory inside file `lib\features\customers\SUMMARY.md`
- To give me better answers, please write a summary of each response to a file named `lib\features\customers\SUMMARY.md`, so AI can remember and improve my prompts next time.
- *important* I'm giving you the Customer functionality, so try not to mess with the other features.