input ที่ต้อง mapping ค่าตอน init เข้าหน้า create jobcard และ edit jobcard
jobcard_id: disable input (ถูกต้องแล้วไม่ต้องทำอะไร)
job card title: input (ถูกต้องแล้วไม่ต้องทำอะไร)
lane: (ถูกต้องแล้วไม่ต้องทำอะไร)
hashtag: (ถูกต้องแล้วไม่ต้องทำอะไร)
assignee: (ถูกต้องแล้วไม่ต้องทำอะไร)
customer: (ถูกต้องแล้วไม่ต้องทำอะไร)
company:เป็นแบบ single select  /workspaces/xKnLu20t7n6A0IJxl4NN{workspace_id}/companies/aVGCGee5LmYsr9oXYfE8{company_id} (ถูกต้องแล้วไม่ต้องทำอะไร)
expected closing date: (ถูกต้องแล้วไม่ต้องทำอะไร)
status: (ถูกต้องแล้วไม่ต้องทำอะไร)
description: (ถูกต้องแล้วไม่ต้องทำอะไร)
collaborators:เป็นแบบ multi select  /users/d3z7heLqwYXXC3u3O9uR7iO9ium2{user_id}/workspaces[].id ในส่วนนี่ให้ไปทำการวนหาว่ามีใครฮยู่ workspace อยู่ โดยอิ่งจาก workspace_id ปัจจุบัน
watchers:เป็นแบบ multi select /users/d3z7heLqwYXXC3u3O9uR7iO9ium2{user_id}/workspaces[].id ในส่วนนี่ให้ไปทำการวนหาว่ามีใครฮยู่ workspace อยู่ โดยอิ่งจาก workspace_id ปัจจุบัน
todo_list:แสดงเป็น list todo /workspaces/xKnLu20t7n6A0IJxl4NN/cards/6VAYUMDzobYF1cTzMOax
 เมื่อทำการกดปุ่ม "Apply Template" ไม่ต้องทำอะไร  เมื่อทำการกดปุ่ม "+ Add item" จะต้องมี input ให้กรอกโดยจะมี action เป็น 4 action คิือ save,select datetime,delete,checkbox (โดย checkbox จะทำหนัาที่เปลียน status ที่ completed) 
attached files: เมื่อทำการกดปุ่ม "Add file" ให้ทำการเด้งหน้าต่างให้เลือกไฟล์ออกมาและโชว์เป็น list ค่างล่าง
comments:(ถูกต้องแล้วไม่ต้องทำอะไร) 


-------------------------------------------
ค่าตัวแปรและ path ใน database ที่ต้องทำการ save ลง

jobcard_id: (ถูกต้องแล้วไม่ต้องทำอะไร)
job card title: (ถูกต้องแล้วไม่ต้องทำอะไร)
lane: (ถูกต้องแล้วไม่ต้องทำอะไร)
hashtag: (ถูกต้องแล้วไม่ต้องทำอะไร)
assignee: (ถูกต้องแล้วไม่ต้องทำอะไร)
customer: (ถูกต้องแล้วไม่ต้องทำอะไร)
company:  /workspaces/xKnLu20t7n6A0IJxl4NN{workspace_id}/cards/6VAYUMDzobYF1cTzMOax{card_id}/company (ตัว company จะมี id{company_id},label{},value{company_name})
expected closing date: (ถูกต้องแล้วไม่ต้องทำอะไร)
collaborators: /workspaces/xKnLu20t7n6A0IJxl4NN{workspace_id}/cards/6VAYUMDzobYF1cTzMOax{card_id}/collaborators[] (โดยเมื่อ edit หรือ add ให้ทำการนำ user_id มา add เข้า array ตัวนี่ collaborators input เป็นแบบ mutiselect) 
watchers: /workspaces/xKnLu20t7n6A0IJxl4NN{workspace_id}/cards/6VAYUMDzobYF1cTzMOax{card_id}/watchers[] (โดยเมื่อ edit หรือ add ให้ทำการนำ user_id มา add เข้า array ตัวนี่ watchers input เป็นแบบ mutiselect)
description: (ถูกต้องแล้วไม่ต้องทำอะไร)
expense items: (ยังไม่ต้องทำอะไร)
todo-list:ตัวนี่จะเป็น array /workspaces/xKnLu20t7n6A0IJxl4NN{workspace_id}/cards/6VAYUMDzobYF1cTzMOax{card_id}/todos[] (ตัวที่ใช้ add หรือ edit จะมี completed เป็น cehckbox,id,title)
attached files: (ยังไม่ต้องทำอะไร)
history tap: (ยังไม่ต้องทำอะไร)
comment: (ยังไม่ต้องทำอะไร)
-------------------------------------------



หลังจากทำเสร็จให้ทำการเพิ่มข้อมูลที่ทำการแก้ไขที่ lib/features/board/md/SUMMARY.MD โดยใช้ format นี่

```
--------------------------------------
{$date}
{$detail}
--------------------------------------
```

และทำการ update ตัว DTB.md ด้วยในกรณีที่โครงสร้างไม่ตรง 
ถ้าต้องการดูโครงสร้าง คล่าวๆให้ไปดูที่ lib/features/board/md/DTB.md 
ถ้าต้องการดูโครงสร้างและข้อมูลใน database ที้งหมดให้ไปดูที่ firestore/backup-{date ล่าสุด}.json
