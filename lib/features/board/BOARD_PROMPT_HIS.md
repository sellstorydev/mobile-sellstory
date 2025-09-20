# PRE PROMPT

    - *important* You don't need to explain what you did. I don't want to know, it's a waste of time. Focus on editing the file to meet the task I gave you.
    - First read `lib/features/board/BOARD_SUMMARY.md` file for review your memory and brainstrom your self.
    - For better answer me please read your mememory inside file `lib/features/board/BOARD_SUMMARY.md`
    - To give me better answers, please write a summary or review or document of each response to a file named `lib/features/board/BOARD_SUMMARY.md`, so AI can remember and improve my prompts next time.
    - *important* I'm giving you the Document functionality, so try not to mess with the other features.

##
Topic: Add button "Add Customer" in Customer information section.
Detail: Add button "Add Customer" in Customer informaion section in edit_card_page.dart and create_card_page.dart. By pressed button go to Add customer "add_edit_customer_page.dart".After add customer success go back to edit card page or create card page and fetch new customer in select.

##
Topic: Fix comment.
Detail: can add scrollbar on coment section. in edit_card_page.dart

##

Topic: Fix comment.
Detail: After preassed post btn comment in edit_card_page.dart,data not store to fire store. And coment store wrong data comment should store to current card.
Path and example data.
Path: /workspaces/{workspace id}/cards/{card id}/note

```
{
                {
                "cardId": "AhzmaDyKm4wwcMntM3hO",
                "cardTitle": "Job Card Title",
                "id": "note-1756977906169",
                "mentions": [],
                "text": "<p>test</p>",
                "timestamp": 1756977906169,
                "type": "text",
                "userDisplayName": "bew kiw",
                "userId": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
                "userPhotoURL": null
              },
              {
                "cardId": "AhzmaDyKm4wwcMntM3hO",
                "cardTitle": "Job Card Title",
                "id": "note-1756977911696",
                "mentions": [],
                "parentId": "note-1756977906169",
                "text": "<p>replytest</p>",
                "timestamp": 1756977911696,
                "type": "text",
                "userDisplayName": "bew kiw",
                "userId": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
                "userPhotoURL": null
              },
              {
                "cardId": "AhzmaDyKm4wwcMntM3hO",
                "cardTitle": "Job Card Title1234",
                "id": "note-1757176041380",
                "mentions": [],
                "parentId": "note-1757176026052",
                "text": "<p>1123344</p>",
                "timestamp": 1757176041380,
                "type": "text",
                "userDisplayName": "bew kiw",
                "userId": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
                "userPhotoURL": null
              }
}

```

##

Topic: status card in board.
Detail: add count card in status card on board.

##

Topic: fix hashtag.
Detail: hashtag input on Assignment and tags in create_card_page.dart store wrong data to firestore, hashtag should have id and mapping color in hashtagSettings .
Path: /workspaces/{workspace id}

```
        "hashtagSettings": {
          "isEnabled": true,
          "mode": "global",
          "automation": {
            "autoCreateFromChat": false
          },
          "masterList": [
            {
              "count": 0,
              "color": "#f97316",
              "name": "Bew213",
              "id": "bew213",
              "enabled": true,
              "scopes": {
                "chat": true,
                "company": true,
                "customer": true,
                "jobBoard": true,
                "product": true
              },
              "totalUsage": 1,
              "usage": {
                "jobBoard": 1
              }
            },
            {
              "id": "bew1234455",
              "name": "Bew1234455",
              "enabled": true,
              "scopes": {
                "jobBoard": true,
                "customer": true,
                "product": true,
                "chat": true,
                "company": true
              },
              "count": 0,
              "color": "#eab308"
            }
          ]
        },
```

Wrong data

```
    {
        "color": "#6B7280",
        "text": "Bew213"
    },
    {
        "color": "#6B7280",
        "text": "Bew1234455"
    }
```

True data

```
    {
        "color": "#eab308",
        "id": "bew1234455",
        "text": "Bew1234455"
    }
```

##

Topic: html editor scroll
Detail: fix scroll in edit card page like create card page

### Auto-Scroll Prevention Fix in create_card_page.dart (September 18, 2025)

**Issue:** After entering create card page, when HTML editor finishes loading, the page automatically scrolls down to the HTML editor section instead of staying at the top.

**Root Cause:** The `shouldEnsureVisible: true` option in HtmlEditorOptions causes the HTML editor to automatically scroll itself into view when initialization completes.

**Solution Applied:**
Changed `shouldEnsureVisible` from `true` to `false` in HtmlEditorOptions to prevent automatic scrolling behavior.

**Technical Changes:**

```dart
// Before: Auto-scroll enabled
shouldEnsureVisible: true,

// After: Auto-scroll disabled
shouldEnsureVisible: false,
```

##

Topic:Change ui hashtags
Detail: hashtag not show after change widget like hashtag_input_field.dart. You should mapping or get hashtag like hashtag_input_field.dart. If current should show 2 hashtage Bew213,bew1234455. Data and struc you can see in path "firestore/backup-workspaces-xKnLu20t7n6A0IJxl4NN-2025-09-18T16-22-35.json"

##

Topic:Change ui hashtags
Detail: careate_card_page.dart and edit_card_page.dart in Assignment and tags change hashtag input like Add customer pages is HashtagInputField from hashtag_input_field.dart.

##

Topic: html editor not store to firebase.
Detail: I got this error after save card.
Error

```
flutter: 🔍 HTML Editor Save Debug (Create):
flutter:   - _isHtmlEditorReady: true
flutter:   - Fallback controller text: ""
[IOSInAppWebViewWidget] (iOS) IOSInAppWebViewWidget calling "dispose" using []
flutter: ⚠️ Error getting HTML editor content: MissingPluginException(No implementation found for method evaluateJavascript on channel com.pichillilorenzo/flutter_inappwebview_31)
flutter: ⚠️ WebView plugin error detected - HTML editor not fully initialized
```

you should fix this error .

##

Topic: html editor not store to firebase.
Detial:I filled value to htmleditor. And pressed save card success. but not store in firestore
Path: "/workspaces/xKnLu20t7n6A0IJxl4NN/cards/fIPtV1kTyO6NDk26MYVF"
Data:

```
{
description:""
}
```

you can check this data and structure from "firestore/backup-workspaces-xKnLu20t7n6A0IJxl4NN-2025-09-18T16-22-35.json"

##

Topic: descriptio Htmleditor not store data to firestore.
Detail: After pressed save card data not store data to firestore in path "/workspaces/{workspace id}/cards/{card id}/description"
Example description like

```
{
    ...,
    description:"<p><strong></strong></p><p><strong><strong></strong></strong></p><p><strong><strong><strong></strong></strong></strong></p><p><strong><strong><strong><strong></strong></strong></strong></strong></p><p><strong><strong><strong><strong></strong></strong></strong></strong></p><p><strong><strong><strong><strong></strong></strong></strong></strong></p><p><strong><strong><strong><strong></strong></strong></strong></strong></p><p><strong><strong><strong><span style="color: rgb(2, 8, 23); font-size: 14px;"><strong><em><u>Detailstest1111111</u></em></strong></span></strong></strong></strong></p><p></p><p></p><p></p><p></p><p></p><p></p><p></p>",
    ...
}
```

##

Topic: After enter careate_card_page.dart and edit_card_page.dart then press exit immediately, show error like this

```
[ERROR:flutter/runtime/dart_vm_initializer.cc(40)] Unhandled Exception: MissingPluginException(No implementation found for method evaluateJavascript on channel com.pichillilorenzo/flutter_inappwebview_3)
#0      MethodChannel._invokeMethod (package:flutter/src/services/platform_channel.dart:365:7)
platform_channel.dart:365
<asynchronous suspension>
#1      IOSInAppWebViewController.evaluateJavascript (package:flutter_inappwebview_ios/src/in_app_webview/in_app_webview_controller.dart:1924:16)
in_app_webview_controller.dart:1924
<asynchronous suspension>
#2      HtmlEditorController._evaluateJavascript (package:html_editor_enhanced/src/html_editor_controller_mobile.dart:264:20)
html_editor_controller_mobile.dart:264
```

##

Topic: /fix error htmleditor load not success
Detail: After enter careate_card_page.dart and edit_card_page.dart then press exit immediately, show error like this

```
Exception has occurred.
_Exception (Exception: HTML editor is still loading, please wait before evaluating this JS: $('#summernote-2').summernote('reset');!)
```

i think should disable go back button or PopScope go back until load html editor success

##

Topic: /fix error create_card_page.dart
detail: After enter create_card_page.dart then go back, show error like this

```
Exception has occurred.
MissingPluginException (MissingPluginException(No implementation found for method evaluateJavascript on channel com.pichillilorenzo/flutter_inappwebview_3))

flutter: 🔄 CreateCardPage.dispose - Page being disposed
[ERROR:flutter/runtime/dart_vm_initializer.cc(40)] Unhandled Exception: MissingPluginException(No implementation found for method evaluateJavascript on channel com.pichillilorenzo/flutter_inappwebview_3)
#0      MethodChannel._invokeMethod (package:flutter/src/services/platform_channel.dart:365:7)
platform_channel.dart:365
<asynchronous suspension>
#1      IOSInAppWebViewController.evaluateJavascript (package:flutter_inappwebview_ios/src/in_app_webview/in_app_webview_controller.dart:1924:16)
in_app_webview_controller.dart:1924
<asynchronous suspension>
#2      _HtmlEditorWidgetMobileState.build.<anonymous closure> (package:html_editor_enhanced/src/widgets/html_editor_widget_mobile.dart:445:23)
html_editor_widget_mobile.dart:445
<asynchronous suspension>

flutter: ❌ Failed to load companies for customer: setState() called after dispose(): _EditCardPageState#bb53e(lifecycle state: defunct, not mounted)
This error happens if you call setState() on a State object for a widget that no longer appears in the widget tree (e.g., whose parent widget no longer includes the widget in its build). This error can occur when code calls setState() from a timer or an animation callback.
The preferred solution is to cancel the timer or stop listening to the animation in the dispose() callback. Another solution is to check the "mounted" property of this object before calling setState() to ensure the object is still in the tree.
This error might indicate a memory leak if setState() is being called because another object is retaining a reference to this State object after it has been removed from the tree. To avoid memory leaks, consider breaking the reference to this object during dispose().
[ERROR:flutter/runtime/dart_vm_initializer.cc(40)] Unhandled Exception: setState() called after dispose(): _EditCardPageState#bb53e(lifecycle state: defunct, not mounted)
This error happens if you call setState() on a State object for a widget that no longer appears in the widget tree (e.g., whose parent widget no longer includes the widget in its build). This error can occur when code calls setState() from a timer or an animation callback.
The preferred solution is to cancel the timer or stop listening to the animation in the dispose() callback. Another solution is to check the "mounted" property of this object before calling setState() to ensure the object is still in the tree.
This error might indicate a memory leak if setState() is being called because another object is retaining a reference to this State object after it has been removed from the tree. To avoid memory leaks, consider breaking the reference to this object during dispose().
#0      State.setState.<anonymous closure> (package:flutte<…>
```

##

Topic: /fix Fix warning after create new jobcard
Detail: After create new jobcard, show alert dialog warning like attach image.

##

Topic: Add button "Add Customer" in Customer information section.
Detail: Add button "Add Customer" in Customer informaion section in edit_card_page.dart and create_card_page.dart. By pressed button go to Add customer "add_edit_customer_page.dart".After add customer success go back to edit card page or create card page and fetch new customer in select.

##

Topic:Fix error html input field description in Content and Tasks section in create_card_page.dart
Detail: Now after pressed save card button in create card page, show toast "Failed to create card: MissingPluginException(No implementation found for method evaluateJavascript on channel com.pichililorenzo/fluttter_inappwebview_15 )"

##

Topic: Comment section in edit_card_page.dart can't delete and edit
Detail: Comment section in edit_card_page.dart add icon delete and edit
Step:

1. Add icon delete and edit comment.
2. When click delete show confirm dialogs, then press confirm delete comment.
3. When click edit show input field, close or cancle icon and save icon an on conment display
4. after press save store data comment to firestore

Path: /workspaces/{workspace uid}/cards/{card uid}/notes[]

##

Topic: fix bad ui.
Detail: Timeline and status section in edit_card_page.dart status select ui not map create_card_page.dart chagne ui status select like create_card_page.dart

##

Topic: Remove input order.
Detail: Remove input field order in modal Add new lane

##

Topic: Todo title convert string in content and tasks section.
Detail: In image in textfield show html tag, Before Map value to title todo convert html tag string to normal string and save to html tag p.

In textfield should be like this

```
text
```

If Save to title todo in firestore add only tag p

```
<p>text</p>

```

##

Topic: Todo title data not show in input field

Detail: Todo title data not show in input field Content and Tasks section.

Step:

1. Mapping todo data from firestore to todo input field on table todo

Note: I export newest data in firestore path "backup-workspaces-xKnLu20t7n6A0IJxl4NN-2025-09-18T08-57-07.json"

##

Topic: Fix error in edit_card_page.dart
Step

1. Check error in edit_card_page.dart
2. Fix error in edit_card_page.dart

##

Topic: change content and tasks section in edit_card_page.dart to like create_card_page.dart
Step

1. copy content and tasks section in create_card_page.dart to edit_card_page.dart
2. change to text field.
3. map data to text field. not sure maybe convert html to text before map to text field.
4. when save button pressed,store data to firestore path "/workspaces/{workspace uid}/cards/{card uid}/todos[]"

##

Topic: Fix error html editor in edit_card_page.dart
Detail: Content and tasks section in edit_card_page.dart on todo part not show title of todo list in field editor.

Step

1. Check todo list data is currently mapping.
2. Check html editor in todo part.
3. Fix error html editor in todo part.
4. Check when save card pressed,store or edit todo list data to firestore path "/workspaces/{workspace uid}/cards/{card uid}/todos[]"

##

Topic: Mapping todo list data in edit_card_page.dart
Step

1. Find value in firestore path "/workspaces/{workspace uid}/cards/{card uid}/todos[].title"
2. Map value to html edit of todo part in edit_card_page.dart

##

Topic: Todo part, Content and tasks section in edit_card_page.dart is missing

1. Go to create_card_page.dart for copy structure todo part
2. Add todo part to edit_card_page.dart and todo input is html editor.
3. Check Map data to todo part.I'm not sure it aredy have it.
4. When save card press,store todo list data to firestore path "/workspaces/{workspace uid}/cards/{card uid}/todos[]"

##

Topic: Integrate HTML Editor for Content and Details Sections in create_card_page.dart
Step

1. change textfield to html editor.
2. When save card pressed,store description data to "/workspaces/{workspaces uid}/cards/{card uid}/description"

##

Topic: Fix error text htmleditor

I think error on map description to html editor

Exception has occurred.
\_Exception (Exception: HTML editor is still loading, please wait before evaluating this JS: $('#summernote-2').summernote('code', '<p><strong><p><strong><p><strong><p><strong><p><strong><p><strong><p><strong><p><span style=\"color: rgb(2, 8, 23); font-size: 14px;\"><strong><em><u>Details</u></em></strong></span></p></strong></p></strong></p></strong></p></strong></p></strong></p></strong></p></strong></p>');!)

##

Topic: Integrate HTML Editor for Content and Details Sections in edit_card_page.dart

Step

1. add lib html editor in section content and details and pubspec.yaml.
2. change textfield to html editor.
3. map value from card data in path "/workspaces/{workspaces uid}/cards/{card uid}/description" to html editor.
4. when save button pressed, map value from html editor to card data in path "/workspaces/{workspaces uid}/cards/{card uid}/description".
