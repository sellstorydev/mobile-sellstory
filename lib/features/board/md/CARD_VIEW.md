

นี่จะเป็น file.md ของ card view ใน lane หน้า board 

นี่จะเป็นค่า mapping ตัวแปรที่ใช้แสดงหน้า card view /workspaces/{workspace_id}/cards/{card_id}
name: /workspaces/{workspace_id}/cards/{card_id}/name
job id: /workspaces/{workspace_id}/cards/{card_id}/customId
status: /workspaces/{workspace_id}/cards/{card_id}/status
created date: /workspaces/{workspace_id}/cards/{card_id}/createdAt
assignee: /workspaces/{workspace_id}/cards/{card_id}/assignedTo (ในส่วน assignedTo จะเป็น user_id ให้ไปดึง name มาจาก /users/{user_id/displayName})
company:  /workspaces/{workspace_id}/cards/{card_id}/company/value
customer interest: /workspaces/{workspace_id}/cards/{card_id}/customerInterest
collaborators: /workspaces/{workspace_id}/cards/{card_id}/collaborators[] (ในส่วนนี่จะเป็น collaborators[] array เก็บ [user_id,user_id] ให้ไปดึง name มาจาก /users/{user_id/displayName )
customer: /workspaces/{workspace_id}/cards/{card_id}/customer
hashtags: /workspaces/{workspace_id}/cards/{card_id}/hashtags[].text
priority: - 
grand total: /workspaces/{workspace_id}/cards/{card_id}/expenses[] (ในส่วนนี่จะเป็นการรวมค่า pricePerUnit ที่อยู่ใน array นี่)
net total: /workspaces/{workspace_id}/cards/{card_id}/expenses[] (ในส่วนนี่จะเป็นการรวมค่า pricePerUnit ที่อยู่ใน array นี่)
total (before discount): /workspaces/{workspace_id}/cards/{card_id}/expenses[] (ในส่วนนี่จะเป็นการรวมค่า pricePerUnit ที่อยู่ใน array นี่)
total (after discount):  /workspaces/{workspace_id}/cards/{card_id}/expenses[] (ในส่วนนี่จะเป็นการรวมค่า pricePerUnit ที่อยู่ใน array นี่)
total (before vat): /workspaces/{workspace_id}/cards/{card_id}/expenses[] (ในส่วนนี่จะเป็นการรวมค่า pricePerUnit ที่อยู่ใน array นี่)
description: /workspaces/{workspace_id}/cards/{card_id}/description (ในส่วนนี่ จะเป็นการเก็บแบบ <p>Bew111111234</p> ให้แสดงแบบนั้นเลยไม่ต้องแปลงอะไร)
to-do list:  /workspaces/{workspace_id}/cards/{card_id}/todos[] (ในส่วนนี่ ให้เอาแค่ count มาแสดงโดยถ้า completed เป็น true ให้นับ 1  โดยการแสดงประมาณนี่ 1/2,0/2)


