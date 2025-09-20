# Translation System Guide (EN/TH)

This app uses GetX Translations with a small helper layer for fast, robust i18n (English/Thai). Default language is English. Switch languages at runtime without restarting the app.

- Core map: `lib/core/i18n/app_translations.dart`
- Controller: `lib/translation/translation_controller.dart`
- Helpers & widgets: `lib/translation/translation_system.dart`, `lib/translation/widgets/*`

---
## 1) How to use in widgets

- Basic: `'key'.tr`
- With string interpolation: `Text('hello'.tr)` or `Text('items_count'.tr.replaceFirst('{count}', '$n'))`
- Recommended helper for params: `'items_count'.trParams({'count': '$n'})`
- With fallback: `'missing_key'.trWith(fallback: 'Fallback text')`

Example:
- AppBar title in Chat Center: `Text('chat_center'.tr)`
- Tooltip: `tooltip: 'chat_center'.tr`

---
## 2) Add or update translations

Edit `lib/core/i18n/app_translations.dart` and add keys to both sections:
- English: `en_US`
- Thai: `th`

Example keys added for Chat Center:
- `chat_center`: "Chat Center" / "ศูนย์แชท"
- `notification`: "Notification" / "การแจ้งเตือน"

Guidelines:
- Use lowercase snake_case (e.g., `chat_status_in_progress`).
- Reuse existing keys where possible; avoid duplicates.
- Keep placeholders in `{curly_braces}` and the same across languages.

---
## 3) Parameters and formatting

- Use placeholders in the value: `'items_count': '{count} items'`
- Replace with the helper: `'items_count'.trParams({'count': '5'})`
- Date/currency helpers in controller:
  - `TranslationController.to.formatDate(date)` (Thai uses Buddhist year)
  - `TranslationController.to.formatCurrency(123.45)`

---
## 4) Switching language (runtime)

- Toggle: `TranslationController.to.toggleLanguage()`
- Explicit: `TranslationController.to.switchLanguage('en' | 'th')`
- Current locale (reactive): `TranslationController.to.currentLocale`
- Widgets for UI: `LanguageSwitcherWidget`, `LanguageToggleButton`, `LanguageSelectionSheet`

App wiring (already configured):
- In `lib/app/app.dart`, `GetMaterialApp` uses `translations: AppTranslations()` and `locale` from `TranslationController`.

---
## 5) Quick checks & troubleshooting

- Text didn’t translate? Ensure the key exists in both `en_US` and `th`, and the widget isn’t `const` where `.tr` is used.
- Wrong language at startup? The controller persists and synchronizes language on ready.
- Missing key visible? Use `'key'.trWith(fallback: '...')` during development and add the key properly later.
- Tooling: run a quick static check and open the app. No special build steps for i18n.

---
## 6) Conventions

- Organize keys by feature (comments), keep names consistent.
- Prefer single, reusable keys; avoid hardcoding text in Dart files.
- For lists or status labels, keep parallel structure in EN/TH to stay maintainable.

---
## 7) Recent example changes

- Localized Chat Center title and tooltip using `chat_center` key.
- Added `notification` (singular) for snackbars.

See summary in `lib/translation/TRANSLATION_SUMMARY.md` for more details.

---
## คู่มือระบบแปลภาษา (ภาษาไทย)

แอปนี้ใช้ระบบแปลของ GetX พร้อมตัวช่วยเพิ่มเติม รองรับอังกฤษ/ไทย เปลี่ยนภาษาได้ทันทีโดยไม่ต้องรีสตาร์ทแอป

- ไฟล์แปลหลัก: `lib/core/i18n/app_translations.dart`
- คอนโทรลเลอร์: `lib/translation/translation_controller.dart`
- ฮีลเปอร์/วิดเจ็ต: `lib/translation/translation_system.dart`, `lib/translation/widgets/*`

การใช้งานพื้นฐาน:
- แปลข้อความ: `'key'.tr`
- มีพารามิเตอร์: `'items_count'.trParams({'count': '5'})`
- มีสำรอง: `'missing_key'.trWith(fallback: 'ข้อความสำรอง')`

เพิ่ม/แก้คีย์แปล:
- เพิ่มคีย์ทั้ง `en_US` และ `th` ใน `app_translations.dart`
- ตั้งชื่อเป็น snake_case และใช้ `{param}` สำหรับตัวแปร

สลับภาษา:
- `TranslationController.to.toggleLanguage()` หรือ `switchLanguage('en'|'th')`
- ใช้วิดเจ็ตสำเร็จรูปเช่น `LanguageSwitcherWidget`

ข้อควรระวัง:
- อย่าใส่ `const` หน้า `Text('key'.tr)` เพราะ `.tr` ประเมินตอนรันไทม์
- ถ้าไม่เห็นคำแปล ให้เช็คคีย์ในสองภาษาและสะกดให้ตรงกัน

ตัวอย่างที่ทำล่าสุด:
- แปลชื่อหน้า Chat Center และ tooltip ด้วยคีย์ `chat_center`
- เพิ่มคีย์ `notification` สำหรับหัวข้อแจ้งเตือน
