ผมมีอยากให้ทำการแก้ไข card view โดยที่ card view จะสามารถเปิดปิดค่าที่ใช้แสดงได้และ sort ค่าที่ใช้แสดงได้โดยจะมีค่าที่ใช้แสดงดัวนี่ (เปลียนแค่การแสดงผลเท่านั้นแค่ที่เกียวข่องกับ card view และ card view settings เท่านั้น)

NOTE: ในส่วน Grand Total,Net Total,Total (before discount),Total (after discount),Total (before VAT) ผมได้แนบรูปที่ถูกต้องไปให้ดูครับ 

- Job ID
- Status
- Date Range
- Created Date
- Assignee
- Customer Interest
- Collaborators
- Customer
- Company
- Hashtags
- Grand Total
- Net Total
- Total (before discount)
- Total (after discount)
- Total (before VAT)
- Description
- To-Do List


โดย card view จะอยู่บน lane และในหน้า board view
และ ตัวกรองจะอยู่ที่ card view settings

และค่าที่นำมาโชว์มีดังนี่ 
- Job ID ใช้ field(customId)   
- Status ใช้ field(status)
- Date Range ใช้ field(startDate ตอ้งแปลงเป็น date ธรรมดาก่อน) - ใช้ field(endDate ตอ้งแปลงเป็น date ธรรมดาก่อน) ตัวอย่าง "01/01/2025 - 02/01/2025"
- Created Date ใช้ field(createdAt)
- Assignee ใช้ field(assignedTo แต่ต้องเอาไป map กับ collection user แล้วไปเอา displayName มาโชว์) 
- Customer Interest ใช้ field(customerInterest)
- Collaborators ใช้ loop field(collaborators แต่ต้องเอาไป map กับ collection user แล้วไปเอา displayName มาโชว์)
- Customer ใช้ field(customer)
- Company ใช้ field(company แล้วเอา value มาแสดง)
- Hashtags ใช้ loop field(hashtags แล้วเอา text มาแสดงส่วน background color เป็น color)
- Grand Total ใช้ loop field(expenses มาคำนวนจาก pricePerUnit มาหาส่วนลด discount ถ้า discountType เป็น percentage ให้คำนวนส่วนลดเป็น percentage ถ้าเป็น amount ก็ ลบไปเลยแล้วเอามา บวกกัน แล้วถ้า isVatEnabled เป็น true ให้บวกไปอีก 7% และ ถ้ามี additionalDiscount.value มีค่า ให้นำไปคำนวนด้วยโดยถ้าไม่มี additionalDiscount.type ไม่มีค่าให้คำนวณปกติได้เลย และถ้า type
"percentage" ให้หักเป็น percentage ก็ประมาณนี่ช่วยคำนวนให้หน่อยอาจะไม่ใช้ทั้งหมด)
- Net Total ใช้ loop field(expenses มาคำนวนจาก pricePerUnit มาหาส่วนลด discount ถ้า discountType เป็น percentage ให้คำนวนส่วนลดเป็น percentage ถ้าเป็น amount ก็ ลบไปเลยแล้วเอามา บวกกัน แล้วถ้า isVatEnabled เป็น true ให้บวกไปอีก 7% และ ถ้ามี additionalDiscount.value มีค่า ให้นำไปคำนวนด้วยโดยถ้าไม่มี additionalDiscount.type ไม่มีค่าให้คำนวณปกติได้เลย และถ้า type
"percentage" ให้หักเป็น percentage ก็ประมาณนี่ช่วยคำนวนให้หน่อยอาจะไม่ใช้ทั้งหมด) 
- Total (before discount) ใช้ loop field(expenses มาคำนวนจาก pricePerUnit มาหาส่วนลด discount ถ้า discountType เป็น percentage ให้คำนวนส่วนลดเป็น percentage ถ้าเป็น amount ก็ ลบไปเลยแล้วเอามา บวกกัน แล้วถ้า isVatEnabled เป็น true ให้บวกไปอีก 7% และ ถ้ามี additionalDiscount.value มีค่า ให้นำไปคำนวนด้วยโดยถ้าไม่มี additionalDiscount.type ไม่มีค่าให้คำนวณปกติได้เลย และถ้า type
"percentage" ให้หักเป็น percentage ก็ประมาณนี่ช่วยคำนวนให้หน่อยอาจะไม่ใช้ทั้งหมด)
- Total (after discount) ใช้ loop field(expenses มาคำนวนจาก pricePerUnit มาหาส่วนลด discount ถ้า discountType เป็น percentage ให้คำนวนส่วนลดเป็น percentage ถ้าเป็น amount ก็ ลบไปเลยแล้วเอามา บวกกัน แล้วถ้า isVatEnabled เป็น true ให้บวกไปอีก 7% และ ถ้ามี additionalDiscount.value มีค่า ให้นำไปคำนวนด้วยโดยถ้าไม่มี additionalDiscount.type ไม่มีค่าให้คำนวณปกติได้เลย และถ้า type
"percentage" ให้หักเป็น percentage ก็ประมาณนี่ช่วยคำนวนให้หน่อยอาจะไม่ใช้ทั้งหมด)
- Total (before VAT) ใช้ loop field(expenses มาคำนวนจาก pricePerUnit มาหาส่วนลด discount ถ้า discountType เป็น percentage ให้คำนวนส่วนลดเป็น percentage ถ้าเป็น amount ก็ ลบไปเลยแล้วเอามา บวกกัน แล้วถ้า isVatEnabled เป็น true ให้บวกไปอีก 7% และ ถ้ามี additionalDiscount.value มีค่า ให้นำไปคำนวนด้วยโดยถ้าไม่มี additionalDiscount.type ไม่มีค่าให้คำนวณปกติได้เลย และถ้า type
"percentage" ให้หักเป็น percentage ก็ประมาณนี่ช่วยคำนวนให้หน่อยอาจะไม่ใช้ทั้งหมด)
- Description  ใช้ field(description แล้วเอาแล้วเอามาแปลง show แบบ html) 
- To-Do List  ใช้ loop field(todos ใช้ langth มาแสดง โดยใช้ completed ถ้าเป็น true ให้ count เป็น false ไม่ต้อง count ตัวอย่าง 0/2,1/2)



data  card
/workspaces/xKnLu20t7n6A0IJxl4NN/cards/AhzmaDyKm4wwcMntM3hO
          "AhzmaDyKm4wwcMntM3hO": {
            "boardId": "Mop2RUYjlM9kRoXGa001",
            "laneId": "qesjwQS3saV9h3wzyYMz",
            "workspaceId": "xKnLu20t7n6A0IJxl4NN",
            "title": "Job Card Title",
            "description": "<p><span style=\"color: rgb(2, 8, 23); font-size: 14px;\"><strong><em><u>Details</u></em></strong></span></p>",
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
            "expenses": [
              {
                "id": "exp-1756975564459-34N6d2Az4sYF7ZHvyFHN",
                "productId": "34N6d2Az4sYF7ZHvyFHN",
                "name": "Example html",
                "description": "",
                "quantity": 1,
                "unit": "item",
                "pricePerUnit": 51234,
                "discount": 20,
                "discountType": "percentage"
              },
              {
                "id": "exp-1756975564459-RwedKMymVqN8W3nFYbJP",
                "productId": "RwedKMymVqN8W3nFYbJP",
                "name": "test1",
                "description": "",
                "quantity": 1,
                "unit": "item",
                "pricePerUnit": 11223344,
                "discount": 0,
                "discountType": "amount"
              }
            ],
            "todos": [
              {
                "id": "todo-1756975522376",
                "title": "<p><span style=\"color: rgb(2, 8, 23); font-size: 24px;\"><strong>To-Do List false</strong></span></p>",
                "completed": false,
                "dueDate": 1756918860000,
                "mentions": []
              },
              {
                "id": "todo-1756975523853",
                "title": "<p><span style=\"color: rgb(2, 8, 23); font-size: 24px;\"><strong>To-Do List true</strong></span></p>",
                "completed": false,
                "dueDate": 1756918860000,
                "mentions": []
              }
            ],
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
            "updatedByDisplayName": "bew kiw",
            "quotationTemplateId": "",
            "startDate": 1756918800000,
            "endDate": 1757091600000,
            "customerInterest": "กลาง (Medium)",
            "descriptionMentions": [],
            "withholdingTaxPercentage": 3,
            "customId": "JB-250904-0043",
            "attachments": [
              {
                "id": "workspaces/xKnLu20t7n6A0IJxl4NN/cards/AhzmaDyKm4wwcMntM3hO/1756977560926-jpeg2.jpeg",
                "name": "jpeg2.jpeg",
                "filename": "jpeg2.jpeg",
                "url": "https://firebasestorage.googleapis.com/v0/b/kanbanflow-iq93h.firebasestorage.app/o/workspaces%2FxKnLu20t7n6A0IJxl4NN%2Fcards%2FAhzmaDyKm4wwcMntM3hO%2F1756977560926-jpeg2.jpeg?alt=media&token=87e11ad0-6989-4ac3-913f-f43d3741a371",
                "uploadedAt": 1756977561769,
                "uploadedBy": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
                "size": 5827
              },
              {
                "id": "workspaces/xKnLu20t7n6A0IJxl4NN/cards/AhzmaDyKm4wwcMntM3hO/1756977563859-jpeg1.jpeg",
                "name": "jpeg1.jpeg",
                "filename": "jpeg1.jpeg",
                "url": "https://firebasestorage.googleapis.com/v0/b/kanbanflow-iq93h.firebasestorage.app/o/workspaces%2FxKnLu20t7n6A0IJxl4NN%2Fcards%2FAhzmaDyKm4wwcMntM3hO%2F1756977563859-jpeg1.jpeg?alt=media&token=db6f932e-238b-4c2a-911e-8e2c70b3a5c2",
                "uploadedAt": 1756977564258,
                "uploadedBy": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
                "size": 55627
              }
            ],
            "notes": [
              {
                "id": "note-1756977906169",
                "userId": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
                "userDisplayName": "bew kiw",
                "userPhotoURL": null,
                "text": "<p>test</p>",
                "timestamp": 1756977906169,
                "mentions": [],
                "cardId": "AhzmaDyKm4wwcMntM3hO",
                "cardTitle": "Job Card Title",
                "type": "text"
              },
              {
                "id": "note-1756977911696",
                "userId": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
                "userDisplayName": "bew kiw",
                "userPhotoURL": null,
                "text": "<p>replytest</p>",
                "timestamp": 1756977911696,
                "mentions": [],
                "parentId": "note-1756977906169",
                "cardId": "AhzmaDyKm4wwcMntM3hO",
                "cardTitle": "Job Card Title",
                "type": "text"
              }
            ],
            "id": "AhzmaDyKm4wwcMntM3hO",
            "isVatEnabled": true,
            "order": 0,
            "additionalDiscount": {
              "value": 97,
              "type": "percentage"
            },
            "updatedAt": 1757008014158
          },

user 
/users/xvdZZF0XGsWwR1yZtUdG8cQQgtU2
{
  "users": {
    "xvdZZF0XGsWwR1yZtUdG8cQQgtU2": {
      "uid": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
      "email": "ja@gmail.com",
      "displayName": "bew kiw",
      "photoURL": null,
      "language": "en",
      "lastPlatform": "ios",
      "workspaces": [
        {
          "id": "xKnLu20t7n6A0IJxl4NN",
          "name": "test1",
          "role": "owner"
        },
        {
          "id": "3Z8UlZ5632kAHYrWPS8a",
          "name": "test2",
          "role": "owner"
        },
        {
          "id": "ueqzWiKWyxpXyewgqQEC",
          "name": "testworkspace lol1",
          "role": "owner"
        }
      ],
      "lastActiveWorkspaceId": "xKnLu20t7n6A0IJxl4NN",
      "lastDeviceId": "0E03E3E1-077B-4989-B129-8D4E458CCDF0",
      "updatedAt": {
        "_seconds": 1756722963,
        "_nanoseconds": 929000000
      },
      "fcmToken": "cWyViZfkg0NWvwATNb_pzu:APA91bEt4lJF2NIcBlQnhK7u-YjJ5Z_9vUtI46dNootQ53wLJVtcls-7wqeLpXHdv6KXDhuTrlFhDvJC_4ks82pQ5lXJi46fZcHhTMxizReI5GdoR9nxeQw",
      "viewSettings": {
        "status": {
          "isVisible": true,
          "order": 2,
          "style": {
            "color": "#000000",
            "fontWeight": "normal",
            "fontSize": 14
          }
        },
        "grandTotal": {
          "order": 12,
          "style": {
            "fontWeight": "normal",
            "fontSize": 14,
            "color": "#000000"
          },
          "isVisible": true
        },
        "jobId": {
          "style": {
            "fontWeight": "normal",
            "color": "#000000",
            "fontSize": 14
          },
          "isVisible": true,
          "order": 1
        },
        "hashtags": {
          "order": 10,
          "isVisible": false,
          "style": {
            "color": "#666666",
            "fontSize": 14,
            "fontWeight": "normal"
          }
        },
        "assignee": {
          "style": {
            "color": "#000000",
            "fontSize": 14,
            "fontWeight": "normal"
          },
          "order": 5,
          "isVisible": true
        },
        "totalAfterDiscount": {
          "order": 15,
          "isVisible": false,
          "style": {
            "fontSize": 14,
            "fontWeight": "normal",
            "color": "#666666"
          }
        },
        "todoList": {
          "isVisible": false,
          "order": 18,
          "style": {
            "fontWeight": "normal",
            "fontSize": 14,
            "color": "#666666"
          }
        },
        "priority": {
          "order": 11,
          "isVisible": true,
          "style": {
            "fontWeight": "normal",
            "fontSize": 14,
            "color": "#000000"
          }
        },
        "customerInterest": {
          "style": {
            "fontWeight": "normal",
            "fontSize": 14,
            "color": "#000000"
          },
          "order": 6,
          "isVisible": true
        },
        "collaborators": {
          "isVisible": false,
          "order": 7,
          "style": {
            "color": "#666666",
            "fontSize": 14,
            "fontWeight": "normal"
          }
        },
        "company": {
          "order": 9,
          "style": {
            "color": "#666666",
            "fontSize": 14,
            "fontWeight": "normal"
          },
          "isVisible": false
        },
        "description": {
          "style": {
            "fontWeight": "normal",
            "fontSize": 14,
            "color": "#666666"
          },
          "order": 17,
          "isVisible": false
        },
        "customer": {
          "style": {
            "color": "#000000",
            "fontSize": 14,
            "fontWeight": "normal"
          },
          "order": 8,
          "isVisible": true
        },
        "kanbanCardDisplayFieldsConfig_Mop2RUYjlM9kRoXGa001": {
          "customId": {
            "style": {},
            "isVisible": true,
            "order": 0
          },
          "priority": {
            "order": 10,
            "style": {},
            "isVisible": true
          },
          "hashtags": {
            "order": 9,
            "style": {},
            "isVisible": true
          },
          "netTotal": {
            "isVisible": true,
            "order": 12,
            "style": {}
          },
          "company": {
            "isVisible": true,
            "style": {},
            "order": 8
          },
          "status": {
            "isVisible": true,
            "order": 1,
            "style": {}
          },
          "assignee": {
            "isVisible": true,
            "style": {},
            "order": 4
          },
          "todos": {
            "isVisible": true,
            "style": {},
            "order": 17
          },
          "grandTotal": {
            "isVisible": true,
            "order": 11,
            "style": {}
          },
          "customer": {
            "isVisible": true,
            "style": {},
            "order": 7
          },
          "description": {
            "isVisible": true,
            "style": {},
            "order": 16
          },
          "totalAmountBeforeVat": {
            "order": 15,
            "isVisible": true,
            "style": {}
          },
          "customerInterest": {
            "isVisible": true,
            "order": 5,
            "style": {}
          },
          "collaborators": {
            "order": 6,
            "style": {},
            "isVisible": true
          },
          "totalAmountAfterDiscount": {
            "style": {},
            "isVisible": true,
            "order": 14
          },
          "dueDate": {
            "style": {},
            "order": 2,
            "isVisible": true
          },
          "totalAmountBeforeDiscount": {
            "order": 13,
            "style": {},
            "isVisible": true
          },
          "createdAt": {
            "isVisible": true,
            "order": 3,
            "style": {}
          }
        },
        "totalBeforeVAT": {
          "order": 16,
          "style": {
            "fontSize": 14,
            "color": "#666666",
            "fontWeight": "normal"
          },
          "isVisible": false
        },
        "totalBeforeDiscount": {
          "style": {
            "fontWeight": "normal",
            "fontSize": 14,
            "color": "#666666"
          },
          "order": 14,
          "isVisible": false
        },
        "netTotal": {
          "order": 13,
          "style": {
            "fontWeight": "normal",
            "fontSize": 14,
            "color": "#000000"
          },
          "isVisible": true
        },
        "customerProfileCardsConfig_WNF9tUB8pFM6QKQw9Fj3": {
          "customId": {
            "isVisible": true,
            "order": 0,
            "style": {}
          },
          "title": {
            "isVisible": true,
            "order": 1,
            "style": {}
          },
          "boardName": {
            "isVisible": true,
            "order": 2,
            "style": {}
          },
          "status": {
            "isVisible": true,
            "order": 3,
            "style": {}
          },
          "lane": {
            "isVisible": true,
            "order": 4,
            "style": {}
          },
          "dueDate": {
            "isVisible": true,
            "order": 5,
            "style": {}
          },
          "assignee": {
            "isVisible": true,
            "order": 6,
            "style": {}
          },
          "customerInterest": {
            "isVisible": true,
            "order": 7,
            "style": {}
          },
          "customer": {
            "isVisible": true,
            "order": 8,
            "style": {}
          },
          "company": {
            "isVisible": true,
            "order": 9,
            "style": {}
          },
          "hashtags": {
            "isVisible": true,
            "order": 10,
            "style": {}
          },
          "priority": {
            "isVisible": true,
            "order": 11,
            "style": {}
          },
          "grandTotal": {
            "isVisible": true,
            "order": 12,
            "style": {}
          },
          "netTotal": {
            "isVisible": true,
            "order": 13,
            "style": {}
          },
          "totalAmountBeforeDiscount": {
            "isVisible": true,
            "order": 14,
            "style": {}
          },
          "totalAmountAfterDiscount": {
            "isVisible": true,
            "order": 15,
            "style": {}
          },
          "totalAmountBeforeVat": {
            "isVisible": true,
            "order": 16,
            "style": {}
          },
          "description": {
            "isVisible": true,
            "order": 17,
            "style": {}
          },
          "todos": {
            "isVisible": true,
            "order": 18,
            "style": {}
          }
        },
        "createdDate": {
          "isVisible": true,
          "style": {
            "fontSize": 14,
            "fontWeight": "normal",
            "color": "#000000"
          },
          "order": 4
        },
        "dateRange": {
          "style": {
            "color": "#000000",
            "fontWeight": "normal",
            "fontSize": 14
          },
          "order": 3,
          "isVisible": true
        }
      },
      "fcmTokenUpdatedAt": {
        "_seconds": 1757002653,
        "_nanoseconds": 973000000
      },
      "subCollection": {
        "users/xvdZZF0XGsWwR1yZtUdG8cQQgtU2/devices": {
          "0E03E3E1-077B-4989-B129-8D4E458CCDF0": {
            "forceSignOut": false,
            "isActive": true,
            "platform": "ios",
            "token": "cWyViZfkg0NWvwATNb_pzu:APA91bEt4lJF2NIcBlQnhK7u-YjJ5Z_9vUtI46dNootQ53wLJVtcls-7wqeLpXHdv6KXDhuTrlFhDvJC_4ks82pQ5lXJi46fZcHhTMxizReI5GdoR9nxeQw",
            "updatedAt": {
              "_seconds": 1757002653,
              "_nanoseconds": 916000000
            }
          },
          "2F2A576C-CF24-4BD1-AA70-6BD4321C51C5": {
            "platform": "ios",
            "token": "cmdEXYZ-5EL8s6U-iahfRr:APA91bFX1yyn61IVMfhPYoYkyJ424YLfQH3UjCosnclpvABxQY_CV2vPj1bELYmBcQ6wbnuFA5A-wn_TLgSYTsz9ckG0FPtYkY0wLivf27h6iWPRE71dOXc",
            "updatedAt": {
              "_seconds": 1756715557,
              "_nanoseconds": 804000000
            },
            "forceSignOut": true,
            "kickAt": {
              "_seconds": 1756716867,
              "_nanoseconds": 32000000
            },
            "kickReason": "exceeded_limit",
            "isActive": false,
            "kickByDevice": "0E03E3E1-077B-4989-B129-8D4E458CCDF0"
          },
          "5E11B86B-11AF-49F3-9277-1CAD8E100B30": {
            "platform": "ios",
            "token": "fE2KMMVsFk8voSfUZ6f20b:APA91bFOCOFOSL1vK1eeqsEsOz3phc1bxDTNqQ_i3PGwHI4wQXAN6NUEh_XZzq3DFHpkrsZ6wqj5Pn9a0KzatBhJ4YkUsXhEGqNmuYOHjWMg7-GaM3_pur8",
            "updatedAt": {
              "_seconds": 1756283897,
              "_nanoseconds": 504000000
            },
            "forceSignOut": true,
            "kickAt": {
              "_seconds": 1756715664,
              "_nanoseconds": 192000000
            },
            "kickReason": "exceeded_limit",
            "isActive": false,
            "kickByDevice": "D98C8C2E-FE74-4A5E-9783-354DE800B0BA"
          },
          "D98C8C2E-FE74-4A5E-9783-354DE800B0BA": {
            "forceSignOut": false,
            "isActive": true,
            "platform": "ios",
            "token": "csx9_kXTk0xDhVpsGebEih:APA91bHlUWuZ4aLV_eShMmL9GZJf3YW4ZPU2yDRi0dULKPMkBoszVqI0SxKK4NYHFW0VLUgm1MmDDJHs2uiI6BBv_q6F5Qw4gr8MDU7HZY_Spz2cWbm-Diw",
            "updatedAt": {
              "_seconds": 1756715664,
              "_nanoseconds": 771000000
            }
          }
        }
      }
    }
  }
}