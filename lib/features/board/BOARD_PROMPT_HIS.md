# PRE PROMPT
    - *important* You don't need to explain what you did. I don't want to know, it's a waste of time. Focus on editing the file to meet the task I gave you.
    - First read `lib/features/board/BOARD_SUMMARY.md` file for review your memory and brainstrom your self.
    - For better answer me please read your mememory inside file `lib/features/board/BOARD_SUMMARY.md`
    - To give me better answers, please write a summary or review or document of each response to a file named `lib/features/board/BOARD_SUMMARY.md`, so AI can remember and improve my prompts next time.
    - *important* I'm giving you the Document functionality, so try not to mess with the other features.
    - *important* after finish add command in terminal "say finish prompt"

Topic: Filter cards `lib/features/board/view/unified_filter_page.dart`
Detail: เมื่อทำการกด Select date type เป็น start date แล้วกด quick option เป็น today มันแสดงไม่ครบ คือจริงจะต้องแสดง card
Today,+1 day,+3 days,+7 days,+14 days,+30 days,End date 22/09/2025 , this week, this month, jobcard title1234 เนื่องจากมี start data คาบเกีวกับ


##
Topic: Filter cards `lib/features/board/view/unified_filter_page.dart`
Detail: เมื่อผมทำการกดที่ quick option แล้วมันไปล่างค่า select date type ออกหมดจริงๆๆมันต้องไม่ล้างออก ช่วยดูให้หน่อย มีข้อมูลตัวอย่างจาก firestore ที่แนบให้ `firestore/backup-workspaces-xKnLu20t7n6A0IJxl4NN-2025-09-21T18-48-22.json`

##
Topic: Filter cards `lib/features/board/view/unified_filter_page.dart`
Detail: ผมทำการกด last month แต่มันแสดง card last month กับ this month จริงๆมันต้องแสดงแค่ last month อย่างเดียว ช่วยดูให้หน่อย มีข้อมูลตัวอย่างจาก firestore ที่แนบให้ `firestore/backup-workspaces-xKnLu20t7n6A0IJxl4NN-2025-09-21T18-48-22.json`


##
Topic: Filter cards `lib/features/board/view/unified_filter_page.dart`
Detail: คือตอนนี่มันแสดงผิดอยู่นิดหน่อย  ช่วยดูให้หน่อย มีข้อมูลตัวอย่างจาก firestore ที่แนบให้ `firestore/backup-workspaces-xKnLu20t7n6A0IJxl4NN-2025-09-21T18-48-22.json`

##
Topic: Filter cards `lib/features/board/view/unified_filter_page.dart`
Detail:คือตอนนี่มันแสดงผิดอยู่นิดหน่อย ผิดแค่ตอนติ๊ก checkbox Show Unselected Datesแล้ว card +1 day มันไม่ขึ้น แต่ card no date ขึ้น แต่จริงๆต้องขึ้นทั้ง 2 อันเลย คือ +1 day กับ no date ช่วยดูให้หน่อย มีข้อมูลตัวอย่างจาก firestore ที่แนบให้ `firestore/backup-workspaces-xKnLu20t7n6A0IJxl4NN-2025-09-21T18-48-22.json`

##
Topic: Filter cards `lib/features/board/view/unified_filter_page.dart`
Detail:ยังแสดงผิดอยู่ ถ้าไม่ได้ checkbox Show Unselected Dates จะต้องขึ้นแค่ card +1 day แต่เมื่อติกจะต้อง ขึ้น +1day กับ no date ดูหน่อย มีข้อมูลตัวอย่างจาก firestore ที่แนบให้ `firestore/backup-workspaces-xKnLu20t7n6A0IJxl4NN-2025-09-21T18-48-22.json`


##
Topic: Filter cards `lib/features/board/view/unified_filter_page.dart`
Detail: จาก filter ในรูปควรแสดง card ที่ีมี start date หรือ end date อยู่ในช่วงวันที่ที่เลือกและแสดง card ที่ไม่มี start และ end date แต่เมื่อทดสอบจริงๆ กลับแสดง card ที่ไม่มี start date หรือ end date อย่างเดียว fix ให้หน่อย ช่วยดูข้อมูลหน่อยจริงๆต้องโชว์ 2 card ใหมคือ +1 day กับ no date มีข้อมูลตัวอย่างจาก firestore ที่แนบให้ `firestore/backup-workspaces-xKnLu20t7n6A0IJxl4NN-2025-09-21T18-48-22.json`



##
Topic: Filter cards `lib/features/board/view/unified_filter_page.dart`
Detail: Job card date filter select date type,quick option set custom date range: not working.

Select date type section:
consists of
- Start date path: `workspaces/{Workspace id}/cards/{cardId}/startDate`
- End date path: `workspaces/{Workspace id}/cards/{cardId}/endDate`
- Created date path: `workspaces/{Workspace id}/cards/{cardId}/createdAt`
- To-do date path: `workspaces/{Workspace id}/cards/{cardId}/todos[]/{todoId}/dueDate`
- Updated date path: `workspaces/{Workspace id}/cards/{cardId}/updatedAt`
การทำงานของ multi select date type คือเมื่อทำการเลือก date type แล้วตัว date type จะไปกรองเอาการ์ดที่มี key ตามที่เลือกและตรงกับ Custom date rage มาโชว์ แต่มีข้อยกเว้นคือถ้าเลือก Show Unselected Dates จะเป็นการนำกาดร์ที่ไม่มี key start date หรือ end date มาโชว์

Quick option section:
Today is 21/sep/2025, start week is sunday
consists of and explaination case in ()
- Today (Start date is 21/sep/2025 00:00 - End date is 21/sep/2025 23:59)
- This week (Start date is 21/sep/2025 00:00 - End date is 27/sep/2025 23:59)
- This month (Start date is 01/sep/2025 00:00 - End date is 30/sep/2025 23:59)
- Next month (Start date is 01/oct/2025 00:00 - End date is 31/oct/2025 23:59)
- Last Week (Start date is 14/sep/2025 00:00 - End date is 20/sep/2025 23:59)
- Last month (Start date is 01/aug/2025 00:00 - End date is 31/aug/2025 23:59)
- +1 Day (Start date is 21/sep/2025 00:00 - End date is 22/sep/2025 23:59)
- +3 Days (Start date is 21/sep/2025 00:00 - End date is 24/sep/2025 23:59)
- +7 Days (Start date is 21/sep/2025 00:00 - End date is 28/sep/2025 23:59)
- +14 Days (Start date is 21/sep/2025 00:00 - End date is 05/oct/2025 23:59)
- +30 Days (Start date is 21/sep/2025 00:00 - End date is 21/oct/2025 23:59)
- Show Unselected Dates ('check box')
การทำงานของ Quick option จะไม่ใช้การ select หรือ check box ใดๆทั้งสิ้น แต่จะเป็น button เมื่อทำการกดแล้วจะไป set ค่า start date และ end date ใน Set Custom date range section ให้อัตโนมัติ และ check box Show Unselected Dates จะเป็นการนำกาดร์ที่ไม่มี key start date หรือ end date มาโชว์

Set Custom date range section:
consists of
- Start date picker
- End date picker

Example data from firestore `workspaces/{workspace id}/cards`

```
        "workspaces/xKnLu20t7n6A0IJxl4NN/cards": {
          "AhzmaDyKm4wwcMntM3hO": {
            "boardId": "Mop2RUYjlM9kRoXGa001",
            "workspaceId": "xKnLu20t7n6A0IJxl4NN",
            "assignedTo": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "customFields": [],
            "customer": "Bew",
            "customerId": "WNF9tUB8pFM6QKQw9Fj3",
            "company": {
              "label": "Main",
              "id": "aVGCGee5LmYsr9oXYfE8",
              "value": "colaco company"
            },
            "watchers": [
              "xvdZZF0XGsWwR1yZtUdG8cQQgtU2"
            ],
            "collaborators": [
              "xvdZZF0XGsWwR1yZtUdG8cQQgtU2"
            ],
            "createdAt": 1756975589247,
            "createdBy": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "updatedBy": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "startDate": 1756918800000,
            "descriptionMentions": [],
            "id": "AhzmaDyKm4wwcMntM3hO",
            "isVatEnabled": true,
            "additionalDiscount": {
              "value": 97,
              "type": "percentage"
            },
            "badges": [],
            "dueDate": null,
            "priority": null,
            "endDate": 1758906000000,
            "title": "Job Card Title1234",
            "customId": "JB-250904-00431234",
            "hashtags": [
              {
                "color": "#eab308",
                "id": "bew1234455",
                "text": "Bew1234455"
              }
            ],
            "hashtag": "#Bew1234455",
            "status": "Pending",
            "attachments": [
              {
                "filename": "jpeg2.jpeg",
                "id": "workspaces/xKnLu20t7n6A0IJxl4NN/cards/AhzmaDyKm4wwcMntM3hO/1756977560926-jpeg2.jpeg",
                "name": "jpeg2.jpeg",
                "size": 5827,
                "uploadedAt": 1756977561769,
                "uploadedBy": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
                "url": "https://firebasestorage.googleapis.com/v0/b/kanbanflow-iq93h.firebasestorage.app/o/workspaces%2FxKnLu20t7n6A0IJxl4NN%2Fcards%2FAhzmaDyKm4wwcMntM3hO%2F1756977560926-jpeg2.jpeg?alt=media&token=87e11ad0-6989-4ac3-913f-f43d3741a371"
              },
              {
                "filename": "jpeg1.jpeg",
                "id": "workspaces/xKnLu20t7n6A0IJxl4NN/cards/AhzmaDyKm4wwcMntM3hO/1756977563859-jpeg1.jpeg",
                "name": "jpeg1.jpeg",
                "size": 55627,
                "uploadedAt": 1756977564258,
                "uploadedBy": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
                "url": "https://firebasestorage.googleapis.com/v0/b/kanbanflow-iq93h.firebasestorage.app/o/workspaces%2FxKnLu20t7n6A0IJxl4NN%2Fcards%2FAhzmaDyKm4wwcMntM3hO%2F1756977563859-jpeg1.jpeg?alt=media&token=db6f932e-238b-4c2a-911e-8e2c70b3a5c2"
              }
            ],
            "customerInterest": "เริ่มต้น",
            "laneId": "qesjwQS3saV9h3wzyYMz",
            "updatedByDisplayName": "BewLnwZa",
            "quotationTemplateId": "MwDjGmET9ECYTGveik98",
            "expenses": [
              {
                "customInputs": {
                  "BZp1ilY7pFssB5cVhH_RP": "BewLnwZa001",
                  "Ww9jjpqJA3_-4QBgWvXXP": "sku1",
                  "nWnGJtH7SjOyYsBeK5LhX": "Bew1150",
                  "zJ1Gk75NoiV4WxZT1yEZN": "test01"
                },
                "description": "",
                "discount": 20,
                "discountType": "percentage",
                "id": "exp-1756975564459-34N6d2Az4sYF7ZHvyFHN",
                "name": "รายการ1",
                "pricePerUnit": 1,
                "productId": "34N6d2Az4sYF7ZHvyFHN",
                "quantity": 1,
                "unit": "จำนวน"
              }
            ],
            "todos": [
              {
                "completed": false,
                "dueDate": 1756918860000,
                "id": "todo-todo-todo-todo-todo-todo-todo-todo-todo-todo-todo-1756975522376",
                "mentions": [],
                "title": "<p><span style=\"color: rgb(2, 8, 23); font-size: 24px;\"><strong><em>fasdfasdf</em></strong></span></p>"
              },
              {
                "completed": false,
                "dueDate": 1756918860000,
                "id": "todo-todo-todo-todo-todo-todo-todo-todo-todo-todo-todo-1756975523853",
                "mentions": [],
                "title": "<p><span style=\"color: rgb(2, 8, 23); font-size: 24px;\"><strong><em><p><span style=\"color: rgb(2, 8, 23); font-size: 24px;\"><strong><em><p><span style=\"color: rgb(2, 8, 23); font-size: 24px;\"><strong><em></em></strong></span></p></em></strong></span></p></em></strong></span></p>"
              }
            ],
            "relatedDocuments": [
              {
                "id": "fan8Q0INnmXPI26bVeOq",
                "docNo": "EST-250916-0055",
                "type": "QT"
              },
              {
                "id": "EPVk6NpGXdv7Pbsco04g",
                "docNo": "EST-250918-0056",
                "type": "QT"
              }
            ],
            "amount": 0,
            "withholdingTaxPercentage": 3,
            "description": "<p></p><p></p><p></p><p></p><p></p><p></p><p><img src=\"https://firebasestorage.googleapis.com/v0/b/kanbanflow-iq93h.firebasestorage.app/o/workspaces%2FxKnLu20t7n6A0IJxl4NN%2Fcards%2FAhzmaDyKm4wwcMntM3hO%2F1758275041497-Screenshot%202568-09-19%20at%2016.44.00.png?alt=media&amp;token=0d15ce03-413a-469d-a755-7bc0ec8cc8d0\"></p><p><span style=\"color: rgb(2, 8, 23); font-size: 14px;\"><strong><em><u>Detailstest1111111</u></em></strong></span></p><p></p><p></p><p></p><p></p><p></p><p></p><p></p>",
            "formatDataExpense": {
              "subTotal": 1,
              "totalAfterDiscount": 0.03,
              "grandTotal": 0.03,
              "netTotal": 0.03
            },
            "notes": [
              {
                "mentions": [],
                "type": "text",
                "text": "<p>test</p>",
                "cardId": "AhzmaDyKm4wwcMntM3hO",
                "timestamp": 1756977906169,
                "id": "note-1756977906169",
                "userPhotoURL": null,
                "userDisplayName": "bew kiw",
                "userId": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
                "cardTitle": "Job Card Title"
              },
              {
                "userPhotoURL": null,
                "text": "<p>replytest</p>",
                "type": "text",
                "mentions": [],
                "parentId": "note-1756977906169",
                "id": "note-1756977911696",
                "cardTitle": "Job Card Title",
                "timestamp": 1756977911696,
                "userDisplayName": "bew kiw",
                "userId": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
                "cardId": "AhzmaDyKm4wwcMntM3hO"
              },
              {
                "userDisplayName": "bew kiw",
                "timestamp": 1757176041380,
                "cardId": "AhzmaDyKm4wwcMntM3hO",
                "userId": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
                "mentions": [],
                "type": "text",
                "parentId": "note-1757176026052",
                "cardTitle": "Job Card Title1234",
                "id": "note-1757176041380",
                "text": "<p>1123344</p>",
                "userPhotoURL": null
              },
              {
                "id": "note-1758303701505",
                "userId": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
                "userDisplayName": "BewLnwZa",
                "userPhotoURL": "https://firebasestorage.googleapis.com/v0/b/kanbanflow-iq93h.firebasestorage.app/o/users%2FxvdZZF0XGsWwR1yZtUdG8cQQgtU2%2F1758300587166-image_picker_5C38B012-1C85-4D52-9D61-B18F12BB5E3C-58445-0000021FFB61F7C2.jpg?alt=media&token=822a4fe9-cf76-4a0e-8b3c-954bad17baef",
                "text": "<p>ffff</p>",
                "timestamp": 1758303701505,
                "mentions": [],
                "cardId": "AhzmaDyKm4wwcMntM3hO",
                "cardTitle": "Job Card Title1234",
                "type": "text"
              },
              {
                "userId": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
                "mentions": [],
                "cardId": "AhzmaDyKm4wwcMntM3hO",
                "id": "note-1758303727411",
                "text": "<p>asdf</p>",
                "cardTitle": "Job Card Title1234",
                "type": "text",
                "userPhotoURL": "https://firebasestorage.googleapis.com/v0/b/kanbanflow-iq93h.firebasestorage.app/o/users%2FxvdZZF0XGsWwR1yZtUdG8cQQgtU2%2F1758300587166-image_picker_5C38B012-1C85-4D52-9D61-B18F12BB5E3C-58445-0000021FFB61F7C2.jpg?alt=media&token=822a4fe9-cf76-4a0e-8b3c-954bad17baef",
                "userDisplayName": "BewLnwZa",
                "timestamp": 1758303727411
              },
              {
                "userId": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
                "mentions": [],
                "parentId": "note-1758303727411",
                "id": "note-1758303745643",
                "cardId": "AhzmaDyKm4wwcMntM3hO",
                "text": "<p>fasdfasdf</p>",
                "cardTitle": "Job Card Title1234",
                "type": "text",
                "userPhotoURL": "https://firebasestorage.googleapis.com/v0/b/kanbanflow-iq93h.firebasestorage.app/o/users%2FxvdZZF0XGsWwR1yZtUdG8cQQgtU2%2F1758300587166-image_picker_5C38B012-1C85-4D52-9D61-B18F12BB5E3C-58445-0000021FFB61F7C2.jpg?alt=media&token=822a4fe9-cf76-4a0e-8b3c-954bad17baef",
                "userDisplayName": "BewLnwZa",
                "timestamp": 1758303745643
              }
            ],
            "order": 0,
            "updatedAt": {
              "_seconds": 1758447995,
              "_nanoseconds": 545000000
            },
            "subCollection": {
              "workspaces/xKnLu20t7n6A0IJxl4NN/cards/AhzmaDyKm4wwcMntM3hO/expenses": {
                "exp-1756975564459-34N6d2Az4sYF7ZHvyFHN": {
                  "customInputs": {
                    "BZp1ilY7pFssB5cVhH_RP": "BewLnwZa001",
                    "Ww9jjpqJA3_-4QBgWvXXP": "sku1",
                    "nWnGJtH7SjOyYsBeK5LhX": "Bew1150",
                    "zJ1Gk75NoiV4WxZT1yEZN": "test01"
                  },
                  "description": "",
                  "discount": 20,
                  "discountType": "percentage",
                  "name": "รายการ1",
                  "order": 0,
                  "pricePerUnit": 1,
                  "productId": "34N6d2Az4sYF7ZHvyFHN",
                  "quantity": 1,
                  "unit": "จำนวน",
                  "updatedAt": 1758192847010
                }
              }
            }
          },
          "I2oE1BMjZmhTDkCC3vSV": {
            "additionalDiscount": null,
            "assignedTo": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "attachments": [],
            "badges": [
              "Bew213",
              "Bew1234455"
            ],
            "boardId": "Mop2RUYjlM9kRoXGa001",
            "collaborators": [],
            "company": null,
            "createdAt": 1758265559974,
            "createdBy": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "customFields": [],
            "customId": "JB-190925-0073",
            "customerId": "UUzr7AJCvjTrlQYrzZfq",
            "customerInterest": "เริ่มต้น",
            "description": "Zach",
            "dueDate": null,
            "endDate": null,
            "expenses": [],
            "id": "I2oE1BMjZmhTDkCC3vSV",
            "isVatEnabled": false,
            "priority": null,
            "relatedDocuments": [],
            "startDate": null,
            "title": "New Cardasdfasdf",
            "todos": [],
            "updatedBy": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "watchers": [
              "xvdZZF0XGsWwR1yZtUdG8cQQgtU2"
            ],
            "workspaceId": "xKnLu20t7n6A0IJxl4NN",
            "hashtags": [
              {
                "color": "#eab308",
                "id": "bew1234455",
                "text": "Bew1234455"
              }
            ],
            "quotationTemplateId": "Fv9OBceNChku4n8jmx1P",
            "hashtag": "#Bew1234455",
            "updatedByDisplayName": "BewLnwZa",
            "status": "Done",
            "notes": [],
            "amount": 0,
            "withholdingTaxPercentage": 0,
            "laneId": "TNDqN1seUtOTDXqOnHKk",
            "updatedAt": {
              "_seconds": 1758447998,
              "_nanoseconds": 415000000
            },
            "order": 2,
            "customer": "Bew1123 (deleted)"
          },
          "LyWAo2Tkm8UN2QcxbqxN": {
            "additionalDiscount": null,
            "amount": 0,
            "assignedTo": "d3z7heLqwYXXC3u3O9uR7iO9ium2",
            "attachments": [],
            "badges": [
              "Bew213",
              "Bew1234455"
            ],
            "boardId": "Mop2RUYjlM9kRoXGa001",
            "collaborators": [],
            "company": null,
            "createdAt": 1758265480423,
            "createdBy": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "customFields": [],
            "customId": "JB-190925-0072",
            "customerId": "UUzr7AJCvjTrlQYrzZfq",
            "customerInterest": "เริ่มต้น",
            "description": "Asdmirs",
            "dueDate": null,
            "endDate": null,
            "expenses": [],
            "hashtag": "#Bew213 #Bew1234455",
            "hashtags": [
              {
                "color": "#f97316",
                "id": "bew213",
                "text": "Bew213"
              },
              {
                "color": "#eab308",
                "id": "bew1234455",
                "text": "Bew1234455"
              }
            ],
            "id": "LyWAo2Tkm8UN2QcxbqxN",
            "isVatEnabled": false,
            "notes": [],
            "priority": null,
            "quotationTemplateId": null,
            "relatedDocuments": [],
            "startDate": null,
            "status": "Pending",
            "title": "1112354",
            "todos": [],
            "updatedBy": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "updatedByDisplayName": "BewLnwZa1",
            "watchers": [
              "xvdZZF0XGsWwR1yZtUdG8cQQgtU2"
            ],
            "withholdingTaxPercentage": 0,
            "workspaceId": "xKnLu20t7n6A0IJxl4NN",
            "laneId": "TNDqN1seUtOTDXqOnHKk",
            "updatedAt": {
              "_seconds": 1758447998,
              "_nanoseconds": 415000000
            },
            "order": 1,
            "customer": "Bew1123 (deleted)"
          },
          "xLWhObXGC4mihoNlVLIr": {
            "additionalDiscount": null,
            "assignedTo": "d3z7heLqwYXXC3u3O9uR7iO9ium2",
            "attachments": [],
            "badges": [],
            "boardId": "Mop2RUYjlM9kRoXGa001",
            "collaborators": [],
            "company": null,
            "createdAt": 1758456581924,
            "createdBy": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "customFields": [],
            "customId": "JB-210925-0074",
            "customer": "Bew",
            "customerId": "WNF9tUB8pFM6QKQw9Fj3",
            "customerInterest": "เริ่มต้น",
            "description": "",
            "dueDate": null,
            "endDate": null,
            "expenses": [],
            "hashtag": null,
            "hashtags": [],
            "id": "xLWhObXGC4mihoNlVLIr",
            "isVatEnabled": false,
            "laneId": "TNDqN1seUtOTDXqOnHKk",
            "notes": [],
            "order": 0,
            "priority": null,
            "relatedDocuments": [],
            "startDate": null,
            "status": "Pending",
            "title": "New Card",
            "updatedBy": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "updatedByDisplayName": "BewLnwZa1",
            "watchers": [
              "xvdZZF0XGsWwR1yZtUdG8cQQgtU2"
            ],
            "withholdingTaxPercentage": 0,
            "workspaceId": "xKnLu20t7n6A0IJxl4NN",
            "amount": 0,
            "quotationTemplateId": "Fv9OBceNChku4n8jmx1P",
            "participantIds": [
              "d3z7heLqwYXXC3u3O9uR7iO9ium2",
              "xvdZZF0XGsWwR1yZtUdG8cQQgtU2"
            ],
            "todos": [
              {
                "dueDate": 1758474000000,
                "mentions": [],
                "title": "bewtest 1111 (1)",
                "completed": false,
                "id": "todo-1758456772181-0.3019017711398655"
              },
              {
                "title": "bewtest 1111 (2)",
                "dueDate": 1758474000000,
                "mentions": [],
                "completed": false,
                "id": "todo-1758456772181-0.01847240973709996"
              }
            ],
            "formatDataExpense": {
              "grandTotal": 0,
              "netTotal": 0,
              "subTotal": 0,
              "totalAfterDiscount": 0
            },
            "updatedAt": 1758456773426
          }
        },
```

##

Topic: Filter cards
Detail: Fix error

```

════════ Exception caught by widgets library ═══════════════════════════════════
The following assertion was thrown building RawGestureDetector(state: RawGestureDetectorState#f5b27(gestures: [tap, long press, tap and horizontal drag, force press], excludeFromSemantics: true, behavior: translucent)):
A TextEditingController was used after being disposed.
Once you have called dispose() on a TextEditingController, it can no longer be used.

The relevant error-causing widget was:
    TextField TextField:file:///Users/kiki/Works/02-SELLSTORY/mobile-sellstory/lib/features/products/view/products_page.dart:73:22

When the exception was thrown, this was the stack:
#0      ChangeNotifier.debugAssertNotDisposed.<anonymous closure> (package:flutter/src/foundation/change_notifier.dart:182:9)
change_notifier.dart:182
#1      ChangeNotifier.debugAssertNotDisposed (package:flutter/src/foundation/change_notifier.dart:189:6)
change_notifier.dart:189
#2      ChangeNotifier.addListener (package:flutter/src/foundation/change_notifier.dart:271:27)
change_notifier.dart:271
#3      _MergingListenable.addListener (package:flutter/src/foundation/change_notifier.dart:503:14)
change_notifier.dart:503
#4      _AnimatedState.didUpdateWidget (package:flutter/src/widgets/transitions.dart:119:25)
transitions.dart:119
#5      StatefulElement.update (package:flutter/src/widgets/framework.dart:5893:55)
framework.dart:5893
#6      Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
framework.dart:3982
#7      SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
framework.dart:7025
#8      Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
framework.dart:3982
#9      ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
framework.dart:5747
#10     StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
framework.dart:5884
#11     Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
framework.dart:5435
#12     StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
framework.dart:5909
#13     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
framework.dart:3982
#14     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
framework.dart:5747
#15     StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
framework.dart:5884
#16     Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
framework.dart:5435
#17     StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
framework.dart:5909
#18     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
framework.dart:3982
#19     SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
framework.dart:7025
#20     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
framework.dart:3982
#21     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
framework.dart:5747
#22     StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
framework.dart:5884
#23     Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
framework.dart:5435
#24     StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
framework.dart:5909
#25     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
framework.dart:3982
#26     SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
framework.dart:7025
#27     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
framework.dart:3982
#28     SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
framework.dart:7025
#29     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
framework.dart:3982
#30     SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
framework.dart:7025
#31     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
framework.dart:3982
#32     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
framework.dart:5747
#33     StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
framework.dart:5884
#34     Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
framework.dart:5435
#35     BuildScope._tryRebuild (package:flutter/src/widgets/framework.dart:2695:15)
framework.dart:2695
#36     BuildScope._flushDirtyElements (package:flutter/src/widgets/framework.dart:2752:11)
framework.dart:2752
#37     BuildOwner.buildScope (package:flutter/src/widgets/framework.dart:3056:18)
framework.dart:3056
#38     WidgetsBinding.drawFrame (package:flutter/src/widgets/binding.dart:1259:21)
binding.dart:1259
#39     RendererBinding._handlePersistentFrameCallback (package:flutter/src/rendering/binding.dart:495:5)
binding.dart:495
#40     SchedulerBinding._invokeFrameCallback (package:flutter/src/scheduler/binding.dart:1434:15)
binding.dart:1434
#41     SchedulerBinding.handleDrawFrame (package:flutter/src/scheduler/binding.dart:1347:9)
binding.dart:1347
#42     SchedulerBinding._handleDrawFrame (package:flutter/src/scheduler/binding.dart:1200:5)
binding.dart:1200
#43     _invoke (dart:ui/hooks.dart:330:13)
hooks.dart:330
#44     PlatformDispatcher._drawFrame (dart:ui/platform_dispatcher.dart:444:5)
platform_dispatcher.dart:444
#45     _drawFrame (dart:ui/hooks.dart:302:31)
hooks.dart:302

════════════════════════════════════════════════════════════════════════════════
<inspected variable>
flutter: ┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
flutter: │ #0   LoggerService.methodExit (package:sellstory/core/services/logger_service.dart:206:13)
logger_service.dart:206
flutter: │ #1   FirestoreRepository.getUserById (package:sellstory/data/repositories/firestore_repository.dart:2357:15)
firestore_repository.dart:2357
flutter: │ #2   <asynchronous suspension>
flutter: ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
flutter: │ 21:36:17.041 (+2:27:47.029853)
flutter: ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
flutter: │ 🐛 ⬅️ Exiting: FirestoreRepository.getUserById
flutter: └─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
flutter: ┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
flutter: │ #0   LoggerService.methodExit (package:sellstory/core/services/logger_service.dart:206:13)
logger_service.dart:206
flutter: │ #1   FirestoreRepository.getUserById (package:sellstory/data/repositories/firestore_repository.dart:2357:15)
firestore_repository.dart:2357
flutter: │ #2   <asynchronous suspension>
flutter: ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
flutter: │ 21:36:17.060 (+2:27:47.048319)
flutter: ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
flutter: │ 🐛 ⬅️ Exiting: FirestoreRepository.getUserById
flutter: └─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
<inspected variable>
<inspected variable>

════════ Exception caught by widgets library ═══════════════════════════════════
'package:flutter/src/widgets/framework.dart': Failed assertion: line 6171 pos 14: '_dependents.isEmpty': is not true.
The relevant error-causing widget was:
    GetMaterialApp GetMaterialApp:file:///Users/kiki/Works/02-SELLSTORY/mobile-sellstory/lib/app/app.dart:27:14
════════════════════════════════════════════════════════════════════════════════

════════ Exception caught by scheduler library ═════════════════════════════════
Tried to build dirty widget in the wrong build scope.
════════════════════════════════════════════════════════════════════════════════
```

##

Topic: Fix error in board.
Detail: after login i got error like this

```
flutter: ❌ Error loading field config: setState() called after dispose(): _BoardPageState#f6c1d(lifecycle state: defunct, not mounted)
This error happens if you call setState() on a State object for a widget that no longer appears in the widget tree (e.g., whose parent widget no longer includes the widget in its build). This error can occur when code calls setState() from a timer or an animation callback.
The preferred solution is to cancel the timer or stop listening to the animation in the dispose() callback. Another solution is to check the "mounted" property of this object before calling setState() to ensure the object is still in the tree.
This error might indicate a memory leak if setState() is being called because another object is retaining a reference to this State object after it has been removed from the tree. To avoid memory leaks, consider breaking the reference to this object during dispose().
```

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
