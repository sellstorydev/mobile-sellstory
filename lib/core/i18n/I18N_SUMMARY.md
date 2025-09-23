# I18N Translation Summary

## Overview
This document tracks the internationalization (i18n) work done on the SellStory mobile application to ensure proper Thai-English translation support.

## Translation Work Done

### Document Controllers i18n (2025-09-23)
Files:
- `lib/features/document/controller/add_edit_document_controller.dart`
- `lib/features/document/controller/invoice_creation_controller.dart`
- `lib/features/document/controller/create_document_from_card_controller.dart`
- `lib/features/document/controller/invoice_list_controller.dart`
- `lib/features/document/controller/quotations_list_controller.dart`
- `lib/features/document/controller/receipt_list_controller.dart`

Changes:
- Replaced hardcoded Thai/English strings in all listed controllers with `.tr/.trParams`.
- Standardized snackbar titles to use `error`/`success`/`warning` keys.
- Parameterized error messages to include error details via `{error}`.

New translation keys added to `lib/core/i18n/app_translations.dart` (EN/TH):
- Common/Init: `please_login_first`, `please_login_again`, `no_workspaces_for_user`, `initialize_failed_details`, `failed_to_initialize_details`
- Loading/Init form: `load_customers_failed_details`, `init_form_failed_details`
- Changes: `change_customer_failed_details`, `change_company_failed_details`, `change_seller_failed_details`, `change_document_date_failed_details`, `change_valid_until_failed_details`, `change_template_failed_details`, `change_document_status_failed_details`, `toggle_include_signature_failed_details`
- Resources: `load_products_failed_details`, `load_templates_failed_details`, `load_signatures_failed_details`, `load_company_seals_failed_details`
- Document: `document_not_found`, `load_document_failed_details`, `save_document_failed_details`, `select_complete_customer_required`
- Products: `add_product_failed_details`, `products_added_count`, `add_products_from_database_failed_details`, `delete_product_failed_details`
- Invoice creation: `create_invoice_full_success`, `create_invoice_installment_success`, `create_invoice_item_installment_success`, `create_invoice_failed_details`, `max_quantity_title`, `max_quantity_message`
- Create-from-card: `workspace_not_found_check_access`, `quotation_created_success_with_no`, `error_occurred_details`
- Lists loading: `load_invoices_failed_details`, `load_more_invoices_failed_details`, `load_quotations_failed_details`, `load_more_quotations_failed_details`, `load_receipts_failed_details`, `load_more_receipts_failed_details`

Status:
- ✅ Controllers updated to use i18n consistently
- ✅ Keys present in both locales (EN/TH)
- ✅ Meaningful, user-friendly phrasing with parameters where appropriate

### Login & Forgot Password i18n touch-ups (2025-09-23)
Files:
- `lib/features/login/controller/login_controller.dart`
- `lib/features/login/view/login_page.dart`
- `lib/features/login/presenter/login_presenter.dart`
- Verified existing keys used by Forgot Password flow controllers/pages

Changes:
- Localized hardcoded error strings and link-open messages.
- Standardized snackbar titles to `error` and reused consistent login error keys.
- Removed an unused import in `login_page.dart`.

New translation keys added (EN/TH) in `app_translations.dart`:
- `login_failed`, `invalid_email_or_password`, `an_error_occurred_please_try_again`, `cannot_open_link`, `failed_to_open_link`

Status:
- ✅ Login presenter/controller/page now use i18n keys
- ✅ Keys exist in both locales
- ✅ Lint clean-up applied

### Thai phrasing refinements (2025-09-23)
- Updated `user_not_found` → `ไม่พบผู้ใช้` for clarity and consistency.

### Company Tile i18n (2025-09-23)
File: `lib/features/companies/widgets/company_tile.dart`

- Replaced hardcoded Thai strings with i18n keys using GetX `.tr`/`.trParams`:
   - 'รหัส: {customId}' → `code_with_value`
   - 'เลขประจำตัวผู้เสียภาษี: {taxId}' → `tax_id_with_value`
   - 'ไม่มีข้อมูลติดต่อ' → `no_contact_info`
- Added new keys to `app_translations.dart` (EN/TH):
   - `code_with_value`: 'Code: {code}' / 'รหัส: {code}'
   - `tax_id_with_value`: 'Tax ID: {taxId}' / 'เลขประจำตัวผู้เสียภาษี: {taxId}'
   - `no_contact_info`: 'No contact information' / 'ไม่มีข้อมูลติดต่อ'

Status:
- ✅ Widget now fully localized
- ✅ Keys exist in both en_US and th

### CompaniesController i18n (2025-09-23)
File: `lib/features/companies/controller/companies_controller.dart`

- Localized error and permission messages; replaced hardcoded Thai/English strings with `.tr/.trParams`.
- Added EN/TH keys in `app_translations.dart`:
   - `load_companies_failed_details`, `create_company_failed_details`, `update_company_failed_details`, `delete_company_failed_details`
   - `link_customer_company_failed_details`, `unlink_customer_company_failed_details`
   - `permission_denied_action`, `user_not_found`
- Reused existing: `workspace_not_found`

Status:
- ✅ Controller messages localized and parameterized
- ✅ Keys present in both locales

### Chat Screen Controller + Companies pages (2025-09-23)
Files:
- `lib/features/chat/controller/chat_screen_controller.dart`
- `lib/features/companies/view/company_center_page.dart`
- `lib/features/companies/view/company_detail_page.dart`
- `lib/features/companies/view/add_edit_company_page.dart`

Changes:
- Replaced hardcoded strings with i18n keys across the controller and company views.
- Added new keys (EN/TH) in `app_translations.dart`:
   - Chat controller: `missing_conversation_or_workspace_id`, `load_messages_failed_details`, `send_message_failed_details`, `image_sending_coming_soon`, `file_sending_coming_soon`, `unknown_user`, `you`, `notifications`.
   - Companies module: `no_permission_view_companies`, `search_placeholder_companies`, `companies`, `quota_full`, `add_company`, `no_companies_found_matching`, `no_companies`, `start_adding_first_company`, `company_detail_title`, `basic_information`, `branch_hint_example`, `primary`, `thailand`, `associated_customers`, `total_jobs`, `total_sales`.
- Localized default labels and hints in Add/Edit Company.
- Localized Company Center permission fallback, search placeholder, count label, clear tooltip, and empty states.
- Localized Company Detail default title and summary bar.

Notes:
- Removed a duplicate Thai `notifications` key to resolve a map duplicate error.

### Chat Filter Chips (2025-09-23)
File: `lib/features/chat/widgets/chat_filter_chips.dart`

- Replaced hardcoded Thai labels with i18n keys using GetX `.tr`:
   - 'รอดำเนินการ' → `status_todo`
   - 'กำลังดำเนินการ' → `status_in_progress`
   - 'เสร็จสิ้น' → `status_completed`
   - 'ยังไม่ได้อ่าน' → `unread`
- Added `get` import for `.tr` usage.
- All referenced keys already exist in `app_translations.dart` (EN/TH).

### MoreController Translation (2025-09-23)
File: `lib/features/more/controller/more_controller.dart`

- Replaced hardcoded texts with i18n keys using GetX `.tr`/`.trParams()`:
   - Logout dialog title/button/content now use: `logout`, `confirm_logout_question`, `cancel`
   - Snackbar errors standardized: `error`, `logout_failed_details`
   - Guest/user/email fallbacks: `guest`, `user`, `no_email`
   - Webview titles use existing menu keys: `company_settings`, `board_settings`, `notification_settings`, `welcome_message`, `chatbot_settings`, `id_generation_rules`, `roles_permissions`, `approval_conditions`, `document_settings`, `catalog_settings`, plus new: `hashtag_settings`

- Added missing keys to `app_translations.dart` (EN/TH):
   - Webview titles/messages: `hashtag_settings`, `failed_load_*`, `failed_open_*` for all settings pages
   - Company settings Dio error variants: `server_problem_try_again`, `page_not_found`, `connection_slow_check_internet`, `response_slow_try_again`, `cannot_open_company_settings`
   - Logout flow and fallbacks: `confirm_logout_question`, `logout_failed_details`, `guest`, `user`, `no_email`
   - Corrected Thai value for `logout` → `ออกจากระบบ`

- Cleanup:
   - Resolved duplicate key warnings in Thai map by removing repeated keys present earlier in the file.

Status:
- ✅ Controller now fully localized
- ✅ Keys exist in both en_US and th
- ✅ Consistent error handling and titles across webview openings

### Chat Center Page Keys (2025-09-23)
File: `lib/features/chat/view/chat_center_page.dart`

- Verified keys used by the page and ensured Thai translations exist:
   - Toolbar and actions: `chat_center`, `refresh`, `notification`
   - Empty state: `no_chats_found`
   - Permissions: `chat_center_no_permission` (already present)
   - Status updates and assignment: `chat_status_updated`, `chat_status_update_failed`,
      `chat_confirm_assign_sale`, `chat_confirm_assign_sale_message`, `chat_assign_sale_success`,
      `chat_assign_sale_failed`, `chat_workspace_or_chatroom_not_found`

- Added missing Thai strings and aligned wording for consistency.

### Chat Widgets Translation (2025-01-15)
**Files**: Multiple chat widget files including `chat_filter_sheet.dart` and others

#### Analysis:
- Most chat widgets were already well-translated with proper .tr keys
- Found one hardcoded "Hashtag" text in chat_filter_sheet.dart that needed translation
- Added missing translation keys for chat filter functionality

#### Changes Made:
1. **Hardcoded Text**: Replaced 'Hashtag' with 'hashtag'.tr in chat_filter_sheet.dart
2. **Missing Translation Keys**: Added new translation keys for chat filter functionality:
   - 'channel': 'Channel' / 'ช่องทาง'
   - 'facebook_channel': 'Facebook' / 'Facebook'
   - 'instagram_channel': 'Instagram' / 'Instagram'
   - 'line_channel': 'LINE' / 'LINE'
   - 'select_hashtag': 'Select Hashtag' / 'เลือกแฮชแท็ก'
   - 'search_customer_name_or_id': 'Search customer name / ID' / 'ค้นหาชื่อลูกค้า / รหัส'

#### Status:
- ✅ All chat widget files use proper .tr translation keys
- ✅ All translation keys exist in both English and Thai
- ✅ Files use consistent i18n pattern with GetX
- ✅ Chat filter functionality fully translated

### Chat Center Page Translation (2025-01-15)
**File**: `lib/features/chat/view/chat_center_page.dart`

#### Analysis:
- The chat center page was already mostly translated with proper .tr keys
- Found missing Thai translation for 'chat_center_no_permission' key

#### Changes Made:
1. **Missing Thai Translation**: Added Thai translation for 'chat_center_no_permission': 'คุณไม่มีสิทธิ์เข้าถึงศูนย์การสนทนา'

#### Status:
- ✅ All text in chat_center_page.dart is properly translated using .tr keys
- ✅ All translation keys exist in both English and Thai
- ✅ File uses consistent i18n pattern with GetX

### Login Page Translation (2024-12-19)
**File**: `lib/features/login/view/login_page.dart`

#### Changes Made:
1. **Email Field**: Replaced hardcoded Thai text 'อีเมล' with translation key 'email_field_label'.tr
2. **Email Hint**: Replaced 'กรอกอีเมล' with 'enter_email_hint'.tr
3. **Password Field**: Replaced 'รหัสผ่าน' with 'password_field_label'.tr
4. **Password Hint**: Replaced 'กรอกรหัสผ่าน' with 'enter_password_hint'.tr
5. **Forgot Password**: Replaced 'ลืมรหัสผ่าน' with existing 'forgot_password'.tr
6. **Login Button**: Replaced 'เข้าสู่ระบบ' with existing 'login'.tr
7. **Or Divider**: Replaced 'หรือ' with 'or_divider'.tr
8. **Google Sign-in**: Replaced 'เข้าสู่ระบบด้วย Google' with 'sign_in_with_google'.tr
9. **Apple Sign-in**: Replaced 'เข้าสู่ระบบด้วย Apple' with 'sign_in_with_apple'.tr
10. **Information Text**: Replaced 'สอบถามข้อมูลเพิ่มเติม' with 'for_more_information'.tr

### Forgot Password Pages Translation (2024-12-19)
**Files**: 
- `lib/features/login/view/forgot_password_email_page.dart`
- `lib/features/login/view/forgot_password_otp_page.dart`
- `lib/features/login/view/forgot_password_reset_page.dart`

#### Changes Made:
1. **Email Page**:
   - App bar title: 'ลืมรหัสผ่าน' → 'forgot_password_title'.tr
   - Email label: 'กรอกอีเมลที่ใช้สมัคร' → 'enter_registered_email'.tr
   - Button text: 'ขอรหัส OTP' → 'request_otp'.tr

2. **OTP Page**:
   - Instructions: Dynamic text with phone number → 'enter_6_digit_code_with_phone'.trParams() and 'enter_6_digit_code'.tr
   - Resend button: 'ส่งใหม่' and countdown → 'resend'.tr and 'resend_in_seconds'.trParams()

3. **Reset Password Page**:
   - New password label: 'รหัสผ่านใหม่' → 'new_password'.tr
   - Password hint: 'อย่างน้อย 8 ตัวอักษร' → 'new_password_hint'.tr
   - Confirm hint: 'พิมพ์ซ้ำอีกครั้ง' → 'confirm_password_hint'.tr
   - Password match status: 'รหัสผ่านตรงกัน'/'รหัสผ่านไม่ตรงกัน' → 'passwords_match'.tr/'passwords_do_not_match'.tr

### Forgot Password UI & Error Handling Improvements (2024-12-19)
**File**: `lib/features/login/controller/forgot_password_controller.dart`

#### Improvements Made:
1. **Error Message Translation**: All error messages now use translation keys
2. **User-Friendly Error Messages**: Added specific error handling for common scenarios:
   - Email not found errors
   - Network connection errors  
   - Invalid/expired OTP errors
   - Password validation errors
3. **Snackbar Titles**: Toast notification titles now use translation keys
4. **UI Enhancements**: Improved forgot password email page layout with better spacing and descriptions

#### Translation Keys Added to `app_translations.dart`:
```dart
// English (en_US) - Login Page
'email_field_label': 'Email',
'password_field_label': 'Password', 
'enter_email_hint': 'Enter email',
'enter_password_hint': 'Enter password',
'sign_in_with_google': 'Sign in with Google',
'sign_in_with_apple': 'Sign in with Apple',
'or_divider': 'or',
'for_more_information': 'For more information',

// English (en_US) - Forgot Password Pages
'forgot_password_title': 'Forgot Password',
'enter_registered_email': 'Enter registered email',
'request_otp': 'Request OTP',
'enter_6_digit_code': 'Please enter the 6-digit code',
'enter_6_digit_code_with_phone': 'Please enter the 6-digit code sent to ••••{last4}',
'resend': 'Resend',
'resend_in_seconds': 'Resend in {seconds}s',
'reset_password_title': 'Reset Password',
'new_password': 'New Password',
'new_password_hint': 'At least 8 characters',
'confirm_password_hint': 'Type again',
'passwords_match': 'Passwords match',
'passwords_do_not_match': 'Passwords do not match',

// Error Handling & UI Improvements
'request_failed': 'Request failed',
'email_not_found': 'Email not found in system',
'network_error': 'Network connection error',
'invalid_otp': 'Invalid OTP code',
'otp_expired': 'OTP code has expired',
'verification_failed': 'Verification failed',
'password_too_weak': 'Password is too weak',
'password_reset_failed': 'Password reset failed',
'forgot_password_description': 'We will send a verification code to your email address',

// Thai (th) - Forgot Password Pages

// Thai (th) - Login Page
'email_field_label': 'อีเมล',
'password_field_label': 'รหัสผ่าน',
'enter_email_hint': 'กรอกอีเมล', 
'enter_password_hint': 'กรอกรหัสผ่าน',
'sign_in_with_google': 'เข้าสู่ระบบด้วย Google',
'sign_in_with_apple': 'เข้าสู่ระบบด้วย Apple',
'or_divider': 'หรือ',
'for_more_information': 'สอบถามข้อมูลเพิ่มเติม',

// Thai (th) - Forgot Password Pages
'forgot_password_title': 'ลืมรหัสผ่าน',
'enter_registered_email': 'กรอกอีเมลที่ใช้สมัคร',
'request_otp': 'ขอรหัส OTP',
'enter_6_digit_code': 'กรุณากรอกรหัส 6 หลัก',
'enter_6_digit_code_with_phone': 'กรุณากรอกรหัส 6 หลักที่ส่งไปยัง ••••{last4}',
'resend': 'ส่งใหม่',
'resend_in_seconds': 'ส่งใหม่ใน {seconds}s',
'reset_password_title': 'รีเซ็ตรหัสผ่าน',
'new_password': 'รหัสผ่านใหม่',
'new_password_hint': 'อย่างน้อย 8 ตัวอักษร',
'confirm_password_hint': 'พิมพ์ซ้ำอีกครั้ง',
'passwords_match': 'รหัสผ่านตรงกัน',
'passwords_do_not_match': 'รหัสผ่านไม่ตรงกัน',

// Error Handling & UI Improvements
'request_failed': 'การขอข้อมูลไม่สำเร็จ',
'email_not_found': 'ไม่พบอีเมลในระบบ',
'network_error': 'ปัญหาการเชื่อมต่อเครือข่าย',
'invalid_otp': 'รหัส OTP ไม่ถูกต้อง',
'otp_expired': 'รหัส OTP หมดอายุแล้ว',
'verification_failed': 'การยืนยันไม่สำเร็จ',
'password_too_weak': 'รหัสผ่านไม่ปลอดภัยเพียงพอ',
'password_reset_failed': 'การรีเซ็ตรหัสผ่านไม่สำเร็จ',
'forgot_password_description': 'เราจะส่งรหัสยืนยันไปยังที่อยู่อีเมลของคุณ',
```

#### Existing Keys Used:
- 'forgot_password' (already existed in translations)
- 'login' (already existed in translations)
- 'confirm_otp' (already existed in translations)
- 'confirm' (already existed in translations)
- 'confirm_new_password' (already existed in translations)
- 'confirm_password_change' (already existed in translations)
- 'reset_password_title' (already existed in translations)

### Chat Message & Notes Localization (2025-09-23)
Files:
- `lib/features/chat/widgets/message_bubble.dart`
- `lib/features/chat/widgets/note_viewers.dart`
- `lib/features/chat/widgets/notes_sheet.dart`

Changes:
- Replaced hardcoded Thai/English labels in message bubble with i18n keys (image_message, video_message, audio_message, file_message, sticker_message, empty_message, no_name).
- Localized viewer titles and error messages in note viewers; ensured `failed_load_pdf` and `cannot_open_file` keys exist.
- Converted SnackBar Thai strings in notes sheet to parameterized translation keys: `save_failed_details`, `upload_failed_details`, `delete_failed_details`.
- Added missing translation keys in `app_translations.dart` for EN/TH, including `cannot_open_file`, `viewer_*_title`, and the error detail keys.

Status:
- All attached files now use `.tr` consistently and required keys are present in both locales.

### Chat widgets (round 2) – i18n updates (2025-09-23)
Files: chat_status_button.dart, chat_unread_button.dart, conversation_tile.dart, customer_picker_sheet.dart, hashtag_picker_sheet.dart, jobcard_picker_sheet.dart
- Replaced remaining hardcoded labels and fallbacks with i18n keys:
  - Unknown names → no_name
  - Job Card picker titles, hints, errors → link_job_card, search_job_card, load_failed_details, no_jobcards_found
  - Hashtag picker search and empty/error states → search_hashtag_hint, no_hashtag_list, load_list_failed
  - reply prefix in message_bubble uses reply
- Added missing keys to app_translations.dart (EN/TH) for the above.
- Verified tooltips and titles use .tr.

### Chat input & Canned Responses – i18n updates (2025-09-23)
Files: `chat_input.dart`, `canned_responses_sheet.dart`
- Localized Chat Input error dialog title/button to use `error` and `ok` keys; reply label uses `reply`.
- Added new keys to `app_translations.dart`:
   - Status/filter: `in_progress`
   - Multi-image errors: `upload_images_failed_details` (EN/TH)
- Verified existing keys cover canned responses UI: group CRUD, search, preview, send-selected, and error messages.
