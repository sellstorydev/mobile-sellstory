# PRE PROMPT
    - *important* You don't need to explain what you did. I don't want to know, it's a waste of time. Focus on editing the file to meet the task I gave you.
    - First read `lib/features/more/MORE_SUMMARY.md` file for review your memory and brainstrom your self. 
    - For better answer me please read your mememory inside file `lib/features/more/MORE_SUMMARY.md`
    - To give me better answers, please write a summary or review or document of each response to a file named `lib/features/more/MORE_SUMMARY.md`, so AI can remember and improve my prompts next time.
    - *important* I'm giving you the Document functionality, so try not to mess with the other features.


##
Topic: Fix ui.
Detail: After change profile image in แก้ไขโปรไฟล์ successed. and go back to more menu profile not change.I attach image for underdstanding 


##
Topic: Fix error Getx in edit_profile_page.dart
Detail: When open edit profile geting error
```
      throw """
      [Get] the improper use of a GetX has been detected. 
      You should only use GetX or Obx for the specific widget that will be updated.
      If you are seeing this error, you probably did not insert any observable variables into GetX/Obx 
      or insert them outside the scope that GetX considers suitable for an update 
      (example: GetX => HeavyWidget => variableObservable).
      If you need to update a parent widget and a child widget, wrap each one in an Obx/GetX.
      """;
```

##
Topic: Fix error in edit_profile_page.dart
Detail: after click "ถ่ายภาพ" from select profile method application stop working.
Step:
 1. check lib camera and permission.
 2. if not installed.install lib.
 3. check allow description allow camera in alert. and in case ios pod file, case android Manifest
 4. find part or section use camera and lib.
 5. generate NSCameraUsageDescription,NSPhotoLibraryUsageDescription and chage to descript in eng language.
