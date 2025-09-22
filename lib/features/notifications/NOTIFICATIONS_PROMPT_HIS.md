# PRE PROMPT
    - *important* You don't need to explain what you did. I don't want to know, it's a waste of time. Focus on editing the file to meet the task I gave you.
    - First read `lib/features/notifications/NOTIFICATIONS_SUMMARY.md` file for review your memory and brainstrom your self.
    - For better answer me please read your mememory inside file `lib/features/notifications/NOTIFICATIONS_SUMMARY.md`
    - To give me better answers, please write a summary or review or document of each response to a file named `lib/features/notifications/NOTIFICATIONS_SUMMARY.md`, so AI can remember and improve my prompts next time.
    - *important* I'm giving you the Document functionality, so try not to mess with the other features.
    - *important* after finish add command in terminal "say finish prompt"

Topic: Notifications optimization and bug fixes `lib/features/notifications/view/notifications_page.dart`
Detail: แค่เลื่อนมันก็ทำการ steam ใหม่อยากให้ปรับกระบวนการโหลดใหม่ให้ดีขึ้น

```
flutter: 🔄 PAGINATION: Loading more notifications. Current limit: 240 -> 260
flutter: 🔄 STREAM: Connection state: ConnectionState.waiting
flutter: 🔄 STREAM: Connection state: ConnectionState.active
flutter: 📋 NOTIFICATIONS: Loaded 1 items (limit: 260)
flutter: 📄 ITEM 0: L5uERGYF5ddhmM9IXph4 - คุณได้รับมอบหมายงานใหม่
flutter: 🔄 PAGINATION: Loading more notifications. Current limit: 260 -> 280
flutter: 🔄 STREAM: Connection state: ConnectionState.waiting
flutter: 🔄 STREAM: Connection state: ConnectionState.active
flutter: 📋 NOTIFICATIONS: Loaded 1 items (limit: 280)
flutter: 📄 ITEM 0: L5uERGYF5ddhmM9IXph4 - คุณได้รับมอบหมายงานใหม่
flutter: 🔄 PAGINATION: Loading more notifications. Current limit: 280 -> 300
flutter: 🔄 STREAM: Connection state: ConnectionState.waiting
flutter: 🔄 STREAM: Connection state: ConnectionState.active
flutter: 📋 NOTIFICATIONS: Loaded 1 items (limit: 300)
flutter: 📄 ITEM 0: L5uERGYF5ddhmM9IXph4 - คุณได้รับมอบหมายงานใหม่
-[WFIsolatedShortcutRunner init] Taking sandbox extensions for execution
-[WFIsolatedShortcutRunner init]_block_invoke Sandbox extensions acquired
Indexing for request: <WFToolKitIndexingRequest: 0x600001704c80>, changeset: .partial(updated: ["me.sellstory.pro"], removed: []), priority: 31
Indexed: 0
Errored: 0
Skipped: [:]
Finished in 0.566585s
```

##
Topic: Notifications optimization and bug fixes `lib/features/notifications/view/notifications_page.dart`
Detail: When I scroll the notifications list, the list is blinking and jumping to the top all the time,
I think the problem is pagination or something, please fix it. and apply debug when get the notifications list.

##
Topic: Notifications optimization and bug fixes `lib/features/notifications/view/notifications_page.dart`
Detail: When I scroll the notifications list, the list is blinking and jumping to the top all the time, please fix it.
Step-by-step:
1. Identify the root cause of the blinking and jumping issue in the notifications list.
2. Modify the code to ensure that each notification item maintains its widget identity across rebuilds.


##
Topic: Notifications optimization and bug fixes `lib/features/notifications/view/notifications_page.dart`
Detail: When I scroll the notifications list, the list is blinking and jumping, please fix it.