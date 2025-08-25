### SCOPE
ระบบใช้ Firestore โครงสร้างหลัก: workspace → boards/lanes/cards/customers/companies/activities (ดู PATHS)  
จุดประสงค์ context: ให้ AI เข้าใจโมเดลข้อมูล, ความสัมพันธ์, และชนิดข้อมูล เพื่อใช้ตอบคำถาม/เขียนโค้ด map ค่าได้ถูกต้อง

### DATABASE_OVERVIEW
collections:
  - presences
  - quotationTemplates
  - test
  - userFilters
  - users
  - workspaces   # โดเมนหลักของระบบ

### TYPE_LEGEND
string, number (epoch ms หรือ counter), boolean, timestamp (Firestore), map<Object>, array<Type>, map<string,string>

### PATHS
- Workspace (doc):
  /workspaces/{workspaceId}
- Subcollections ของ workspace:
  /workspaces/{workspaceId}/boards/{boardId}
  /workspaces/{workspaceId}/cards/{cardId}
  /workspaces/{workspaceId}/lanes/{laneId}
  /workspaces/{workspaceId}/customers/{customerId}
  /workspaces/{workspaceId}/companies/{companyId}
  /workspaces/{workspaceId}/activities/{activityId}

### RELATIONS (สำคัญ)
- board.workspaceId == workspaceId
- lane.workspaceId == workspaceId AND lane.boardId == boardId
- card.workspaceId == workspaceId
- activity.workspaceId == workspaceId AND activity.boardId == boardId
- company.associatedCustomerIds[] ⊆ customers ids ใน workspace เดียวกัน

### ENTITIES & FIELDS

Workspace (document)
/workspaces/{workspaceId}
fields:
  companyProfile: map
  catalogSettings: map
  enableAddToCart: boolean
  isPublished: boolean
  customerCustomFieldTemplate: array
  customerSources: array
  hashtagSettings: map
  automation: map
  autoCreateFromChat: boolean
  isEnabled: boolean
  masterList: array
  mode: string
  idGenerationRules: map
    # <entity> ∈ {company, customer, invoice, jobCard, product, quotation, receipt}
    idGenerationRules.<entity>.dateFormat: string
    idGenerationRules.<entity>.generationMode: string
    idGenerationRules.<entity>.minLength: number
    idGenerationRules.<entity>.prefix: string
    idGenerationRules.<entity>.separator: string
  lastUsedCounters: map
    # <entity> ∈ {company, customer, invoice, jobCard, product, quotation, receipt}
    lastUsedCounters.<entity>: number
  roles: array<map>
    roles[].id: string
    roles[].name: string
    roles[].permissions: array<string>
  createdAt: number
  members: map<string,string>   # uid → role/permission (ตามการใช้งานจริง)
  name: string
  ownerId: string

Board (document)
/workspaces/{workspaceId}/boards/{boardId}
fields:
  createdBy: string
  lanes: array                     # อาจเก็บ id อ้างถึง lanes
  memberUids: array<string>
  members: array<map>
    members[].displayName: string
    members[].email: string
    members[].language: string
    members[].photoURL: string|null
    members[].role: string
    members[].uid: string
    members[].workspaces?: array<map>
      workspaces[].id: string
      workspaces[].name: string
      workspaces[].role: string
  workspaces?: array<map>          # ถ้าอยู่ระดับบอร์ด (ซ้ำกับด้านบนบางเคส)
    workspaces[].id: string
    workspaces[].name: string
    workspaces[].role: string
  name: string
  workspaceId: string

Card (document)
/workspaces/{workspaceId}/cards/{cardId}
fields:
  createdBy: string
  lanes: array                     # อาจเก็บ id ของ lane ที่เกี่ยวข้อง
  memberUids: array<string>
  members: array<map>
    members[].displayName: string
    members[].email: string
    members[].language: string
    members[].photoURL: string|null
    members[].role: string
    members[].uid: string
    members[].workspaces?: array<map>
      workspaces[].id: string
      workspaces[].name: string
      workspaces[].role: string
  workspaces?: array<map>
    workspaces[].id: string
    workspaces[].name: string
    workspaces[].role: string
  name: string
  workspaceId: string

Lane (document)
/workspaces/{workspaceId}/lanes/{laneId}
fields:
  boardId: string
  createdAt: timestamp
  hasMoreCards: boolean
  name: string
  order: number
  updatedAt: timestamp
  workspaceId: string

Customer (document)
/workspaces/{workspaceId}/customers/{customerId}
fields:
  companyNames: array<map>
    companyNames[].id: string
    companyNames[].label: string
    companyNames[].value: string
  createdAt: number       # epoch ms
  createdBy: string
  customFields: array
  customId: string
  emails: array<map>
    emails[].id: string
    emails[].label: string
    emails[].value: string
  phones: array<map>
    phones[].id: string
    phones[].label: string
    phones[].value: string
  name: string
  updatedAt: number       # epoch ms
  updatedBy: string
  workspaceId: string

Company (document)
/workspaces/{workspaceId}/companies/{companyId}
fields:
  associatedCustomerIds: array<string>
  createdAt: number       # epoch ms
  createdBy: string
  customId: string
  emails: array<map>
    emails[].id: string
    emails[].label: string
    emails[].value: string
  name: string
  phones: array<map>
    phones[].id: string
    phones[].label: string
    phones[].value: string
  updatedAt: number       # epoch ms
  updatedBy: string
  workspaceId: string

Activity (document)
/workspaces/{workspaceId}/activities/{activityId}
fields:
  boardId: string
  details: map
    details.cardId: string
    details.cardTitle: string
    details.destinationLaneId: string
    details.destinationLaneName: string
    details.sourceLaneId: string
    details.sourceLaneName: string
    details.timestamp: number      # epoch ms
    details.type: string           # เช่น "card-move"
    details.userDisplayName: string
    details.userId: string
    details.userPhotoURL: string|null
  workspaceId: string

### NOTES & CONVENTIONS
- วันที่/เวลาใน number ใช้ epoch ms; ถ้าเป็น Firestore timestamp จะระบุเป็นชนิด timestamp
- ตั้งชื่อคีย์ให้สม่ำเสมอ (เลือกใช้ camelCase ตามข้อมูลชุดนี้)
- ความสัมพันธ์ซ้ำซ้อน (เช่น members.workspaces และ field workspaces บน board/card) ให้ยึด source of truth ที่ทีมกำหนด
- โครงสร้างสอดคล้องแนวคิด documents/collections/subcollections ของ Firestore


