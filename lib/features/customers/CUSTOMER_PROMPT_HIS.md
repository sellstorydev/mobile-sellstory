 # PRE PROMPT
    - *important* You don't need to explain what you did. I don't want to know, it's a waste of time. Focus on editing the file to meet the task I gave you.
    - First read `lib/features/customers/CUSTOMER_SUMARY.md` file for review your memory and brainstrom your self. 
    - For better answer me please read your mememory inside file `lib/features/customers/CUSTOMER_SUMARY.md`
    - To give me better answers, please write a summary or review or document of each response to a file named `lib/features/customers/CUSTOMER_SUMARY.md`, so AI can remember and improve my prompts next time.
    - *important* I'm giving you the Document functionality, so try not to mess with the other features.
    - *important* after finish add command in terminal "say finish prompt"

##
Topic: Customer page
Detail: plz recheck data because i change workspace to Bew1150 should have customer list but after i change is still on 1111ffff is 0 customer.
Path data.json for understanding:firestore/backup-all-2025-09-20T17-32-26.json

```
flutter: 🔄 BoardController.render - Updating UI with new state:
flutter:   - Lanes count: 3
flutter:   - Lane: To Do (0 cards)
flutter:   - Lane: In Progress (0 cards)
flutter:   - Lane: Done (0 cards)
flutter: 🔍 Lane "To Do": 0/0 cards have hashtags
flutter: 🔍 Lane "In Progress": 0/0 cards have hashtags
flutter: 🔍 Lane "Done": 0/0 cards have hashtags
flutter: 🔍 Available assignees updated: 0 assignees
flutter: 🔍 UIDs: {}
flutter: 🔍 Display names: []
flutter: 🔍 Available customers updated: 0 customers
flutter: 🔍 Customers: {}
flutter: 🔍 _updateAvailableHashtags() started
flutter: 🔍 Processing 3 lanes
flutter: 🔍 Lane: To Do has 0 cards
flutter: 🔍 Lane: In Progress has 0 cards
flutter: 🔍 Lane: Done has 0 cards
flutter: 🔍 Available hashtags updated: 0 hashtags from 0/0 cards
flutter: 🔍 Final hashtags list: {}
flutter: 🔍 availableHashtags after update: []
flutter: 🔍 _updateAvailableInterests() started
flutter: 🔍 Processing 3 lanes
flutter: 🔍 Lane: To Do has 0 cards
flutter: 🔍 Lane: In Progress has 0 cards
flutter: 🔍 Lane: Done has 0 cards
flutter: 🔍 Available interests updated: 0 interests from 0/0 cards
flutter: 🔍 Interests: {}
flutter: 📱 Board state updated - 3 lanes
flutter: 🎯 Status Summary Cards Obx called - hasWorkspaces: true, lanes count: 3
flutter: 🎯 hasAnyFilter: false, selectedStatuses: []
flutter: 🎯 selectedInterests: []
flutter: 🔍 displayLanes getter called
flutter: 🔍 hasAnyFilter: false
flutter: 🔍 isSearching: false
flutter: 🔍 selectedInterests: []
flutter: 🔍 filteredLanes count: 3
flutter: 🔍 lanes count: 3
flutter: 🔍 Returning original lanes: 3 lanes
flutter: 🎯 Display lanes count: 3, All cards count: 0
flutter: 🔍 displayLanes getter called
flutter: 🔍 hasAnyFilter: false
flutter: 🔍 isSearching: false
flutter: 🔍 selectedInterests: []
flutter: 🔍 filteredLanes count: 3
flutter: 🔍 lanes count: 3
flutter: 🔍 Returning original lanes: 3 lanes
flutter: 🎯 StatusSummaryCards displayMode: LaneDisplayMode.totalBeforeDiscount for laneId: CdWn4l1fngZdgIRRGalF
flutter: 🎯 All laneDisplayModes: {}
flutter: 🎯 StatusSummaryCards build() called with 0 cards
flutter: 🎯 Selected statuses: []
flutter: 🎯 Display mode: LaneDisplayMode.totalBeforeDiscount
flutter: 🔍 displayLanes getter called
flutter: 🔍 hasAnyFilter: false
flutter: 🔍 isSearching: false
flutter: 🔍 selectedInterests: []
flutter: 🔍 filteredLanes count: 3
flutter: 🔍 lanes count: 3
flutter: 🔍 Returning original lanes: 3 lanes
flutter: 🔍 displayLanes getter called
flutter: 🔍 hasAnyFilter: false
flutter: 🔍 isSearching: false
flutter: 🔍 selectedInterests: []
flutter: 🔍 filteredLanes count: 3
flutter: 🔍 lanes count: 3
flutter: 🔍 Returning original lanes: 3 lanes
flutter: 🔍 Building board with 3 lanes
flutter:   - Lane: To Do (0 cards)
flutter:   - Lane: In Progress (0 cards)
flutter:   - Lane: Done (0 cards)
flutter: 🔍 Building add card button for lane: To Do
flutter: 🔍 Add Card Button Debug for lane: To Do
flutter:   - isOwner: true
flutter:   - can(jobcard:create): true
flutter:   - canCreate: true
flutter:   - Current permissions: [*]
flutter: 🔍 Building add card button for lane: In Progress
flutter: 🔍 Add Card Button Debug for lane: In Progress
flutter:   - isOwner: true
flutter:   - can(jobcard:create): true
flutter:   - canCreate: true
flutter:   - Current permissions: [*]
flutter: 🔍 Building add card button for lane: Done
flutter: 🔍 Add Card Button Debug for lane: Done
flutter:   - isOwner: true
flutter:   - can(jobcard:create): true
flutter:   - canCreate: true
flutter:   - Current permissions: [*]
flutter: 🔍 DEBUG: availableHashtags current state:
flutter: 🔍 DEBUG: length = 0
flutter: 🔍 DEBUG: items = []
flutter: 🔍 DEBUG: availableHashtags current state:
flutter: 🔍 DEBUG: length = 0
flutter: 🔍 DEBUG: items = []
```

##
Topic: Customer Page
Detail: Clear and get new customer list is not working

##
Topic: Customer Page
Detail: After change workspace customer list not get from new workspace. It should clear old customer list and get new customer list from new workspace. can u print current board and customer count list.

##
Topic: Customer Page
Detail: customer list show in customer page is not have customer. When change workspace should clear customer list and get new customer list from new workspace. But now is not clear customer list when change workspace. So it show old customer list from old workspace.


##
Topic: Customer Page
Detail: /fix Customer list in addy"ajKydLWgXNQdBNJP3Efj" not have customer but is show 117 customer it should not show 0,I think app use customer from Bew1150 "3w5mum6fnev2IEKF7G9d"


##
Topic: Customer Page
Detail: Customer list not show. path customer "/workspaces/{workspaces}/customers" You can get data for example on "firestore/backup-workspaces-3w5mum6fnev2IEKF7G9d-2025-09-20T16-10-05.json" and "firestore/backup-workspaces-ajKydLWgXNQdBNJP3Efj-2025-09-20T16-06-32.json" those file is data in workspace.

##
Topic Customer Page
Detail: Customer list in customer page show list custom that is not in workspace.customer should show only in workspaces
Path: /workspaces/{workspaces}/customers

##
Topic: Customer lists
Detail: Check again plz, is still error. if i logout then login again customer list is back. But restart application by 'RUN AND DEBUG' customer list is gone

##
Topic: Customer lists
Detail: After restart application, Customer list is missing. But logout and login again is back. I attach image of case for understanding.


##
Topic:Function and section in customer dtail.
Detail: Add icon delete for delete customer. After pressed icon alert confirm dialog. pressed confirm go to delete customer from path "/workspaces/{workspace id}/customers/{customer id}".Can see structure from attach file .json

##
Topic:Function and section customer.
Detail: Add section address to customer deatil lib/features/customers/view/customer_detail_page.dart . Use data from firestore from 
Path: /workspaces/{workspace id}/customers/{customer id}/customers.
Like attach image.

Example customer json
```
 "HM4qDpnY8k6D7M7Sr37y": {
            "hashtags": [
              {
                "color": "#8b5cf6",
                "id": "hot",
                "text": "hot"
              },
              {
                "color": "#f43f5e",
                "id": "sell",
                "text": "sell"
              },
              {
                "color": "#10b981",
                "id": "pro",
                "text": "pro"
              },
              {
                "color": "#a855f7",
                "id": "d3",
                "text": "D3"
              },
              {
                "color": "#10b981",
                "id": "ddd",
                "text": "DDD"
              },
              {
                "color": "#6366f1",
                "id": "edit",
                "text": "edit"
              }
            ],
            "assignees": [
              "2WPcgvluApNvAU0MyzQc0A6h7qu1"
            ],
            "notes": [
              {
                "id": "note-1757928532705",
                "text": "67890",
                "timestamp": 1757928532705,
                "type": "text",
                "userDisplayName": "SEll OAT",
                "userId": "ekgHtCF7fhNsH0mSpGxCPtdjkBJ2",
                "userPhotoURL": null
              },
              {
                "id": "note-1757908283125",
                "text": "เทสว่า note สามารถรับข้อความยาวๆได้ไหมของลองดูหน่อยอยากรู้ว่ามันจะแสดงผลยังไง",
                "timestamp": 1757908283126,
                "type": "text",
                "userDisplayName": "SEll OAT",
                "userId": "ekgHtCF7fhNsH0mSpGxCPtdjkBJ2",
                "userPhotoURL": null
              },
              {
                "id": "note-1757908231058",
                "text": "ๅ/-ภๅภ",
                "timestamp": 1757908231058,
                "type": "text",
                "userDisplayName": "SEll OAT",
                "userId": "ekgHtCF7fhNsH0mSpGxCPtdjkBJ2",
                "userPhotoURL": null
              },
              {
                "id": "note-1757907811211",
                "text": "CDC",
                "timestamp": 1757907811211,
                "type": "text",
                "userDisplayName": "SEll OAT",
                "userId": "ekgHtCF7fhNsH0mSpGxCPtdjkBJ2",
                "userPhotoURL": null
              },
              {
                "id": "note-1757907800995",
                "text": "Test",
                "timestamp": 1757907800995,
                "type": "text",
                "userDisplayName": "SEll OAT",
                "userId": "ekgHtCF7fhNsH0mSpGxCPtdjkBJ2",
                "userPhotoURL": null
              },
              {
                "fileName": "oatza",
                "fileSize": null,
                "id": "note-1757408684334",
                "storagePath": null,
                "text": "oatza",
                "thumbnailStoragePath": null,
                "thumbnailUrl": null,
                "timestamp": 1757408684334,
                "title": "oatza",
                "type": "text",
                "url": null,
                "userDisplayName": null,
                "userId": "ekgHtCF7fhNsH0mSpGxCPtdjkBJ2",
                "userPhotoURL": null
              }
            ]
          },
```