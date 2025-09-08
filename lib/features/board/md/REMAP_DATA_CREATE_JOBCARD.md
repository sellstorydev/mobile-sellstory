fix error ตอนนี่การ create jobcard ทำงานผิดพลาดอยู่โดยที่ ข้อมูลที่เก็บลง firestore ผิด key ให้ทำการ remap data ที่สร้างจาก flutter(ผิดพลาด) ให้ไปเก็บตาม key ที่บอกบน web ให้ถูกต้องหน่อย 

ข้อมูลที่ถูกต้อง (สร้างบน web)
```
      "bxcCuQimRU3tmcWvmFGJ": {
        "boardId": "Mop2RUYjlM9kRoXGa001",
        "workspaceId": "xKnLu20t7n6A0IJxl4NN",
        "title": "Job Card Title",
        "description": "<p><strong>Details</strong></p>",
        "status": "In Progress",
        "assignedTo": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
        "customFields": [],
        "hashtags": [
          {
            "id": "bew213",
            "text": "Bew213",
            "color": "#f97316"
          },
          {
            "id": "bew1234455",
            "text": "Bew1234455",
            "color": "#eab308"
          }
        ],
        "expenses": [],
        "todos": [
          {
            "id": "todo-1756930161065",
            "title": "<p><span style=\"color: rgb(2, 8, 23); font-size: 24px;\"><strong><em>To-Do List 1 True</em></strong></span></p>",
            "completed": true,
            "dueDate": 1756918860000,
            "mentions": []
          },
          {
            "id": "todo-1756930193071",
            "title": "<p><span style=\"color: rgb(2, 8, 23); font-size: 24px;\"><strong><em><u>To-Do List 2 False</u></em></strong></span></p>",
            "completed": false,
            "dueDate": 1756918860000,
            "mentions": []
          }
        ],
        "notes": [],
        "customer": "Bew",
        "customerId": "WNF9tUB8pFM6QKQw9Fj3",
        "company": {
          "value": "colaco company",
          "label": "Main",
          "id": "aVGCGee5LmYsr9oXYfE8"
        },
        "createdAt": 1756930238247,
        "createdBy": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
        "updatedBy": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
        "updatedByDisplayName": "bew kiw",
        "attachments": [],
        "quotationTemplateId": "",
        "startDate": 1756918800000,
        "endDate": 1757005200000,
        "customerInterest": "เริ่มต้น",
        "descriptionMentions": [],
        "customId": "JB-250904-0036",
        "order": 0,
        "watchers": [
          "xvdZZF0XGsWwR1yZtUdG8cQQgtU2"
        ],
        "collaborators": [
          "xvdZZF0XGsWwR1yZtUdG8cQQgtU2"
        ],
        "id": "bxcCuQimRU3tmcWvmFGJ",
        "laneId": "D8FI6YQaNYQLZavNCnyC",
        "updatedAt": {
          "_seconds": 1756972059,
          "_nanoseconds": 73000000
        }
      },
```

ข้อมูลที่ผิดพลาด (สร้างใน flutter )
```
      "mjbRlxktPSuwlQSuk6Ja": {
        "assignedTo": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
        "badges": [
          "Bew213",
          "Bew1234455"
        ],
        "boardId": "Mop2RUYjlM9kRoXGa001",
        "collaborators": [
          "xvdZZF0XGsWwR1yZtUdG8cQQgtU2"
        ],
        "company": {
          "id": "aVGCGee5LmYsr9oXYfE8",
          "label": "Main",
          "value": "colaco company"
        },
        "createdAt": 1756972179207,
        "createdBy": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
        "customId": "JB-040925-0040",
        "customer": "Bew",
        "customerId": "WNF9tUB8pFM6QKQw9Fj3",
        "customerInterest": "เริ่มต้น",
        "description": "Details",
        "endDate": 1757005200000,
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
        "laneId": "qesjwQS3saV9h3wzyYMz",
        "lanes": [
          "qesjwQS3saV9h3wzyYMz"
        ],
        "memberUids": [
          "xvdZZF0XGsWwR1yZtUdG8cQQgtU2"
        ],
        "members": [],
        "name": "Job Card Title",
        "order": 0,
        "startDate": 1756918800000,
        "status": "In Progress",
        "title": "Job Card Title",
        "todos": [
          {
            "completed": false,
            "dueDate": 1756918860000,
            "id": "todo-1756972119591",
            "mentions": [],
            "title": "To-Do List 2 False"
          },
          {
            "completed": true,
            "dueDate": 1756918860000,
            "id": "todo-1756972120259",
            "mentions": [],
            "title": "To-Do List 1 True"
          }
        ],
        "updatedAt": 1756972179207,
        "updatedBy": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
        "updatedByDisplayName": "bew kiw",
        "workspaceId": "xKnLu20t7n6A0IJxl4NN",
        "workspaces": [
          {
            "id": "xKnLu20t7n6A0IJxl4NN",
            "name": "",
            "role": "member"
          }
        ]
      },
```
