# POST PROMPT
    - *important* You don't need to explain what you did. I don't want to know, it's a waste of time. Focus on editing the file to meet the task I gave you.
    - First read `lib/features/board/BOARD_SUMMARY.md` file for review your memory and brainstrom your self. 
    - For better answer me please read your mememory inside file `lib/features/board/BOARD_SUMMARY.md`
    - To give me better answers, please write a summary or review or document of each response to a file named `lib/features/board/BOARD_SUMMARY.md`, so AI can remember and improve my prompts next time.
    - *important* I'm giving you the Document functionality, so try not to mess with the other features.

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
_Exception (Exception: HTML editor is still loading, please wait before evaluating this JS: $('#summernote-2').summernote('code', '<p><strong><p><strong><p><strong><p><strong><p><strong><p><strong><p><strong><p><span style=\"color: rgb(2, 8, 23); font-size: 14px;\"><strong><em><u>Details</u></em></strong></span></p></strong></p></strong></p></strong></p></strong></p></strong></p></strong></p></strong></p>');!)


##
Topic: Integrate HTML Editor for Content and Details Sections in edit_card_page.dart

Step
1. add lib html editor in section content and details and pubspec.yaml.
2. change textfield to html editor.
3. map value from card data in path "/workspaces/{workspaces uid}/cards/{card uid}/description" to html editor.
4. when save button pressed, map value from html editor to card data in path "/workspaces/{workspaces uid}/cards/{card uid}/description".

