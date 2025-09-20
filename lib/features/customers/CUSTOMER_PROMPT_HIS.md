 # PRE PROMPT
    - *important* You don't need to explain what you did. I don't want to know, it's a waste of time. Focus on editing the file to meet the task I gave you.
    - First read `lib/features/board/BOARD_SUMMARY.md` file for review your memory and brainstrom your self. 
    - For better answer me please read your mememory inside file `lib/features/board/BOARD_SUMMARY.md`
    - To give me better answers, please write a summary or review or document of each response to a file named `lib/features/board/BOARD_SUMMARY.md`, so AI can remember and improve my prompts next time.
    - *important* I'm giving you the Document functionality, so try not to mess with the other features.



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