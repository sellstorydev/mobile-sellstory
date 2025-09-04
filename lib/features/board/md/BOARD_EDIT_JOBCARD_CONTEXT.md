# Add jobcard

## Overview
Add jobcard is page receive input from user to create card in lane on board screen. All value will store in frirestore only when press save button. and Based on data or data type you can see in Related Database. After save this page should go back.
and see card in lane on board screen 

## Project structure:
- folder structure is `mvp` (Model View Presenter)
- framework is `flutter`

mvp_scaffold:
  feature_id: add_jobcard
  flutter_framework: getx
  root_path: lib/features/board

  routes:
    name: CreateCardRoute
    path: /board/create-card
    back_after_save: true
    back_to: /board  # หรือเจาะจง Board เดิม

  bindings:
    file: bindings/create_card_binding.dart
    class: CreateCardBinding
    inject:
      - type: JobCardRepository
        impl: FirebaseJobCardRepository
      - type: CreateCardPresenter
        deps: [JobCardRepository]

  files:
    - path: model/job_card.dart
      class: JobCard
      type: model
    - path: data/job_card_repository.dart
      class: JobCardRepository
      type: repository_interface
    - path: data/firebase_job_card_repository.dart
      class: FirebaseJobCardRepository
      type: repository_impl
    - path: presenter/create_card_presenter.dart
      class: CreateCardPresenter
      type: presenter
    - path: view/create_card_page.dart
      class: CreateCardPage
      type: view
    - path: widgets/ # component เสริม เช่น chips, pickers

  state:
    class: CreateCardState
    fields:
      jobCardId: {type: String?, default: null, readonly: true}
      title: {type: String, required: true, minLength: 1, maxLength: 200}
      laneId: {type: String, required: true}
      hashtags: {type: List<HashtagTag>, default: []}
      assigneeUid: {type: String?, required: true}
      customerId: {type: String?, required: true}
      company: {type: CompanyRef?, default: null} # {id,label,value}
      customerInterest: {type: CustomerInterest, required: false, default: "เริ่มต้น"}
      startDate: {type: int?, unit: epochMillis}
      endDate: {type: int?, unit: epochMillis}
      status: {type: JobStatus, required: true, default: Pending}
      collaborators: {type: List<String>, default: []}
      watchers: {type: List<String>, default: []}
      descriptionHtml: {type: String, sanitize: [b,i,u,color,h1,h2,h3]}
      todos: {type: List<TodoItem>, default: []}

  enums:
    JobStatus: [Pending, InProgress, Done, Canceled]
    CustomerInterest: ["เริ่มต้น","น้อย (Low)","กลาง (Medium)","มาก (High)"]

  id_generation:
    source_settings_path: workspaces/{workspaceId}/companyProfile/idGenerationRules/jobCard
    last_counter_path: workspaces/{workspaceId}/companyProfile/lastUsedCounters/jobCard
    algorithm:
      - read prefix, dateFormat, separator, minLength
      - generate: <prefix><separator><date(format)><separator><counter(pad to minLength)>
      - counter: last_counter + 1, update atomically (transaction)

  selects:
    lane:
      query: workspaces/{workspaceId}/lanes where boardId == {boardId}
      value_field: id
      label_field: name
    hashtag_master:
      path: workspaces/{workspaceId}/companyProfile/hashtagSettings/masterList[]
      map_to:
        - hashtags[]: array<{id,text,color}>
        - hashtag: string (e.g. "#Bew1234455 #Bew213")
    customer:
      path: workspaces/{workspaceId}/customers
      value_field: docId
      label_field: name
      also_use:
        companyNames[] -> for company select
    company:
      source: customers/{customerId}/companyNames[]  # {id,label,value}
    users_single_select:
      query: users where workspaces[].id contains {workspaceId}
      value_field: uid
      label_field: displayName
    users_multi_select:
      same_as: users_single_select

  ui_contract:
    view_methods:
      showLoading(): void
      hideLoading(): void
      showError(message: String): void
      showToast(message: String): void
    presenter_methods:
      init(workspaceId: String, boardId: String, currentUserId: String): Future<void>
      pickLane(laneId: String): void
      pickHashtags(list: List<HashtagTag>): void
      pickAssignee(uid: String): void
      pickCustomer(customerId: String): void
      pickCompany(company: CompanyRef?): void
      pickInterest(value: CustomerInterest): void
      pickStatus(value: JobStatus): void
      pickDateRange(startEpoch: int?, endEpoch: int?): void
      editDescription(html: String): void
      addTodo(title: String, dueDateEpoch: int?): void
      updateTodo(id: String, title?: String, dueDateEpoch?: int?, completed?: bool): void
      removeTodo(id: String): void
      submit(): Future<void>

  validation_rules:
    - title: required
    - laneId: required
    - assigneeUid: required
    - customerId: required
    - date_range: startDate <= endDate (if both present)
    - status: must be in enums.JobStatus
    - descriptionHtml: sanitize to allowed tags only

  firestore_write_map:
    doc_path: workspaces/{workspaceId}/cards/{cardId}
    fields:
      title: state.title
      laneId: state.laneId
      hashtags: state.hashtags  # array<{id,text,color}>
      hashtag: "join with '#'+text and space"
      customId: generated.jobCardId
      assignedTo: state.assigneeUid
      customerId: state.customerId
      company: state.company  # {id,label,value} or null
      startDate: state.startDate
      endDate: state.endDate
      status: state.status
      collaborators: state.collaborators
      watchers: state.watchers
      description: state.descriptionHtml
      todos: state.todos  # [{id,title,completed,dueDate?}]
      workspaceId: {workspaceId}
      boardId: {boardId}
      createdBy: {currentUserId}
      createdAt: now()
      updatedBy: {currentUserId}
      updatedAt: now()

  navigation_after_save:
    action: pop_to
    target: /board
    refresh_signal: board_should_reload=true

  activity_log:
    path: workspaces/{workspaceId}/activities
    on_create:
      type: card-create
      details: {cardId, cardTitle: state.title, laneId: state.laneId}
    on_update_title:
      type: card-update-field
      details: {cardId, fieldName: "Title", from, to}

  security_requirements:
    - user must be member of workspaces/{workspaceId}.members OR users/{uid}.workspaces contains {workspaceId}
    - writes must be denied if status not in enums.JobStatus

  test_scenarios:
    - "save minimal": title+lane+assignee+customer -> created card visible in lane
    - "date invalid": endDate < startDate -> block with error
    - "hashtag join": two tags -> hashtag string "#TagA #TagB"
    - "permission": non-member user -> write denied

  i18n_keys:
    screen_title: board.create_card.title
    save_button: common.save
    cancel_button: common.cancel
    toast_saved: board.create_card.saved
    error_required: common.error.required



## Tool
- `get: ^4.6.6` - State management and dependency injection
- `firebase_core`: ^3.4.0
- `firebase_auth`: ^5.3.0
- `firebase_database`: ^11.1.4
- `firebase_database`: ^5.4.0
- `cloud_firestore`: ^5.4.0

## Path
- board folder `lib/features/board`
- jobcard create page `lib/features/board/view/create_card_page.dart`

## input
All input in this file
- Job Card id `input`
- Job Card Title `input`
- Lane `single select`
- Hashtag `multiple select`
- Assignee `single select`
- Customer `single select`
- Company `single select` 
- Customer Interest `single select`  "เริ่มตัน|น้อย (Low)|กลาง (Medium)|มาก (High)" 
- Expected Closing Date `date range select`
- Status `single select` Pending|In Progress|Done|Canceled
- Collaborators `multiple select`
- Watchers `multiple select`
- Description `html input`
- Expense Items `No need to do anything yet`
- Todo List `input and select`
- Attached Files `input file picker`
- Comment `input` can reply text



## Feature
-  Job card id is disable input when tap save job card id auto generate. this input don't nedd value when save. No need to do anything yet.
- Job Card Title is text input
- Lane is single select.This select use value from `workspaces/{workspace UIDs}/lanes(sub col)/{lane UIDs}/name`
- Hashtag is single select. This select use value from `workspaces/{workspace UIDs}/companyProfile/hashtagSettings/masterList[Json Array]/name || color`
- Customer is single select. This select use value from `workspaces/{workspace UIDs}/customers(sub col)/name`
- Company is single select. This select use value from `workspaces/{workspace UIDs}/customers(sub col)/companyNames[json Array]`
- Assignee  is single select. This select use value from `users/{user UIDs}/displayName`.You should check all user in collection `users` have workspaces in path `users/{user UIDs}/workspaces[json array]/id`
- Expected Closing Date is date range picker only date
- Status is single select only have value Pending|In Progress|Done|Canceled
- Collaborators is multiple select This select use value from `users/{user UIDs}/displayName`.You should check all user in collection `users` have workspaces in path `users/{user UIDs}/workspaces[json array]/id`
- Watchers is multiple select This select use value from `users/{user UIDs}/displayName`.You should check all user in collection `users` have workspaces in path `users/{user UIDs}/workspaces[json array]/id`
- Description is html input. Input only have b,i,u,color,h1,h2,h3 
- Todolist have two option is select form template and create new. When select template go to get value from `/workspaces/{workspaces UIDs}/boards(sub col)/{board UIDs}/todoTemplates[json array]/name`. When tap "+ Add Item" app show input have 1 text input and 4 action. first action is check box ,second seclect datetime picker, third is edit ,four delete todo
- Customer Interest is single select.value is  "เริ่มตัน|น้อย (Low)|กลาง (Medium)|มาก (High)" 

## Create input to database
- job card id 
- job card title = `/workspaces/{workspace UIDs}/cards/{card UIDs}(sub col)/title`
- Lane = `/workspaces/{workspace UIDs}/cards/{card UIDs}(sub col)/laneId`
- hashtage = `/workspaces/{workspace UIDs}/cards/{card UIDs}(sub col)/hashtags[json array]` and  `/workspaces/{workspace UIDs}/cards/{card UIDs}(sub col)/hashtag`string( "#Bew1234455 #Bew213")
- Customer = `/workspaces/{workspace UIDs}/cards/{card UIDs}(sub col)/customId`
- Company = `/workspaces/{workspace UIDs}/cards/{card UIDs}(sub col)/company` value json(id,label,value)
- Assignee = `/workspaces/{workspace UIDs}/cards/{card UIDs}(sub col)/assignedTo`
- Expected Closing Date = `/workspaces/{workspace UIDs}/cards/{card UIDs}(sub col)/startDate` and `/workspaces/{workspace UIDs}/cards/{card UIDs}(sub col)/endDate`
- status = `/workspaces/{workspace UIDs}/cards/{card UIDs}(sub col)/status`
- Collaborators = `/workspaces/{workspace UIDs}/cards/{card UIDs}(sub col)/collaborators[]` value (user UIDs)
- Watchers =  `/workspaces/{workspace UIDs}/cards/{card UIDs}(sub col)/watchers[]` value (user UIDs)
- Description = `/workspaces/{workspace UIDs}/cards/{card UIDs}(sub col)/description`
- Todo List = `/workspaces/{workspace UIDs}/cards/{card UIDs}(sub col)/todos[json array]` value(completed,dueDate,id,title)
- Customer Interest =  `/workspaces/{workspace UIDs}/cards/{card UIDs}(sub col)/customerInterest`

## Related Database
Collection
`workspaces` 
Sub collection of workspaces
`activities`
`boards`
`cards`
`companies`
`customers`
`lanes`
`products`

Collection
`users` 
Sub collection of users
`notifications`

#### workspaces/{workspace UIDs}/
```
{
  "workspaces": {
    "xKnLu20t7n6A0IJxl4NN": {
      "createdAt": 1755845149854,
      "name": "test1",
      "ownerId": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
      "members": {
        "xvdZZF0XGsWwR1yZtUdG8cQQgtU2": "owner",
        "d3z7heLqwYXXC3u3O9uR7iO9ium2": "admin"
      },
      "companyProfile": {
        "catalogSettings": {
          "enableAddToCart": true,
          "isPublished": false
        },
        "customerCustomFieldTemplate": [],
        "customerSources": [],
        "idGenerationRules": {
          "company": {
            "dateFormat": "YYMMDD",
            "generationMode": "auto-editable",
            "minLength": 4,
            "prefix": "COM",
            "separator": "-"
          },
          "customer": {
            "dateFormat": "YYMMDD",
            "generationMode": "auto-editable",
            "minLength": 4,
            "prefix": "CUS",
            "separator": "-"
          },
          "invoice": {
            "dateFormat": "YYMMDD",
            "generationMode": "auto-editable",
            "minLength": 4,
            "prefix": "INV",
            "separator": "-"
          },
          "jobCard": {
            "dateFormat": "YYMMDD",
            "generationMode": "auto-editable",
            "minLength": 4,
            "prefix": "JB",
            "separator": "-"
          },
          "product": {
            "dateFormat": "YYMMDD",
            "generationMode": "auto-editable",
            "minLength": 4,
            "prefix": "P",
            "separator": "-"
          },
          "quotation": {
            "dateFormat": "YYMMDD",
            "generationMode": "auto-editable",
            "minLength": 4,
            "prefix": "EST",
            "separator": "-"
          },
          "receipt": {
            "dateFormat": "YYMMDD",
            "generationMode": "auto-editable",
            "minLength": 4,
            "prefix": "RE",
            "separator": "-"
          }
        },
        "roles": [
          {
            "id": "owner",
            "name": "Owner",
            "permissions": [
              "*"
            ]
          },
          {
            "id": "admin",
            "name": "Admin",
            "permissions": [
              "jobcard:view:all",
              "jobcard:create",
              "jobcard:edit:all",
              "jobcard:delete:all",
              "jobcard:move",
              "customer:view:all",
              "customer:create",
              "customer:edit:all",
              "customer:delete",
              "customer:import",
              "company:view",
              "company:create",
              "company:edit:all",
              "company:delete",
              "company:import",
              "product:view",
              "product:create",
              "product:edit:all",
              "product:delete",
              "product:import",
              "user:manage",
              "settings:board:manage",
              "settings:company:manage",
              "settings:id:manage",
              "settings:catalog:manage",
              "settings:roles:manage"
            ]
          },
          {
            "id": "member",
            "name": "Member",
            "permissions": [
              "jobcard:view:assigned",
              "jobcard:create"
            ]
          }
        ],
        "todoTemplates": [],
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
        "lastUsedCounters": {
          "invoice": 0,
          "receipt": 0,
          "customer": 2,
          "product": 2,
          "company": 3,
          "jobCard": 28,
          "quotation": 1
        }
      },
      "subCollection": {
        "workspaces/xKnLu20t7n6A0IJxl4NN/activities": {
          "06gdvC2yyeHnk6fybg0h": {
            "boardId": "uysAvnxpDG4EbdbI7r1Y",
            "workspaceId": "xKnLu20t7n6A0IJxl4NN",
            "userId": "d3z7heLqwYXXC3u3O9uR7iO9ium2",
            "userDisplayName": "BewLnwZa",
            "userPhotoURL": null,
            "type": "card-create",
            "timestamp": 1756116275079,
            "details": {
              "cardId": "3jxu5Me8oI3sjhAkLek2",
              "cardTitle": "New Job",
              "laneId": "9V1OtWzxrwJpLLFZoJHp",
              "laneName": "Bewtest01"
            }
          },
          "6rjcLlTUVihVM27FHkEb": {
            "boardId": "Mop2RUYjlM9kRoXGa001",
            "workspaceId": "xKnLu20t7n6A0IJxl4NN",
            "userId": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "userDisplayName": "bew kiw",
            "userPhotoURL": null,
            "type": "card-move",
            "timestamp": 1756092318372,
            "details": {
              "cardId": "FIFVO81Kg4EfzdCUpZwI",
              "cardTitle": "123456",
              "sourceLaneId": "qesjwQS3saV9h3wzyYMz",
              "sourceLaneName": "In Progress",
              "destinationLaneId": "nvx4rzpcNcJk8GIw4YsK",
              "destinationLaneName": "Done"
            }
          },
          "97gfxUDi7B05W1qPFE04": {
            "boardId": "Mop2RUYjlM9kRoXGa001",
            "workspaceId": "xKnLu20t7n6A0IJxl4NN",
            "userId": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "userDisplayName": "bew kiw",
            "userPhotoURL": null,
            "type": "card-create",
            "timestamp": 1756140015939,
            "details": {
              "cardId": "6VAYUMDzobYF1cTzMOax",
              "cardTitle": "123456ดด",
              "laneId": "D8FI6YQaNYQLZavNCnyC",
              "laneName": "To Do"
            }
          },
          "9sZJglrOLqZQeDTpMJ8s": {
            "boardId": "Mop2RUYjlM9kRoXGa001",
            "workspaceId": "xKnLu20t7n6A0IJxl4NN",
            "userId": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "userDisplayName": "bew kiw",
            "userPhotoURL": null,
            "type": "card-move",
            "timestamp": 1756052266623,
            "details": {
              "cardId": "G2OB4pCjtR0hSHAfmmeV",
              "cardTitle": "New Card",
              "sourceLaneId": "qesjwQS3saV9h3wzyYMz",
              "sourceLaneName": "In Progress",
              "destinationLaneId": "nvx4rzpcNcJk8GIw4YsK",
              "destinationLaneName": "Done"
            }
          },
          "AqLyZ1nsBCxMc8i3gxBo": {
            "boardId": "Mop2RUYjlM9kRoXGa001",
            "workspaceId": "xKnLu20t7n6A0IJxl4NN",
            "userId": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "userDisplayName": "bew kiw",
            "userPhotoURL": null,
            "type": "card-move",
            "timestamp": 1756052223594,
            "details": {
              "cardId": "MSGxSxiHMSe1OCD34GeT",
              "cardTitle": "New Card",
              "sourceLaneId": "D8FI6YQaNYQLZavNCnyC",
              "sourceLaneName": "To Do",
              "destinationLaneId": "qesjwQS3saV9h3wzyYMz",
              "destinationLaneName": "In Progress"
            }
          },
          "AwMpiiDup4NZcPh897pA": {
            "boardId": "uysAvnxpDG4EbdbI7r1Y",
            "workspaceId": "xKnLu20t7n6A0IJxl4NN",
            "userId": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "userDisplayName": "bew kiw",
            "userPhotoURL": null,
            "type": "card-update-field",
            "timestamp": 1755857026384,
            "details": {
              "cardId": "k2vbyyOc5RkyyA1fWQE0",
              "cardTitle": "New Cardด",
              "fieldName": "Expenses"
            }
          },
          "IsMInymDQ4oomW77QqTF": {
            "boardId": "Mop2RUYjlM9kRoXGa001",
            "workspaceId": "xKnLu20t7n6A0IJxl4NN",
            "userId": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "userDisplayName": "bew kiw",
            "userPhotoURL": null,
            "type": "card-move",
            "timestamp": 1756052219851,
            "details": {
              "cardId": "G2OB4pCjtR0hSHAfmmeV",
              "cardTitle": "New Card",
              "sourceLaneId": "D8FI6YQaNYQLZavNCnyC",
              "sourceLaneName": "To Do",
              "destinationLaneId": "qesjwQS3saV9h3wzyYMz",
              "destinationLaneName": "In Progress"
            }
          },
          "M7F8P3epRAmOaxOHSUhD": {
            "boardId": "Mop2RUYjlM9kRoXGa001",
            "workspaceId": "xKnLu20t7n6A0IJxl4NN",
            "userId": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "userDisplayName": "bew kiw",
            "userPhotoURL": null,
            "type": "card-move",
            "timestamp": 1756052305443,
            "details": {
              "cardId": "FIFVO81Kg4EfzdCUpZwI",
              "cardTitle": "123456",
              "sourceLaneId": "nvx4rzpcNcJk8GIw4YsK",
              "sourceLaneName": "Done",
              "destinationLaneId": "nOsAcuKYIaNx4gDblwJO",
              "destinationLaneName": "1111"
            }
          },
          "Mp6BoZVXdmCKiT3dbiwn": {
            "boardId": "Mop2RUYjlM9kRoXGa001",
            "workspaceId": "xKnLu20t7n6A0IJxl4NN",
            "userId": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "userDisplayName": "bew kiw",
            "userPhotoURL": null,
            "type": "card-update-field",
            "timestamp": 1756052282340,
            "details": {
              "cardId": "FIFVO81Kg4EfzdCUpZwI",
              "cardTitle": "123456",
              "fieldName": "Title",
              "from": "New Cardๅ_กก",
              "to": "123456"
            }
          },
          "NUBtsTUrycKhPzdYDtr7": {
            "boardId": "uysAvnxpDG4EbdbI7r1Y",
            "workspaceId": "xKnLu20t7n6A0IJxl4NN",
            "userId": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "userDisplayName": "bew kiw",
            "userPhotoURL": null,
            "type": "card-create",
            "timestamp": 1755852198783,
            "details": {
              "cardId": "KUi2CBRssaZ43K6AsKXC",
              "cardTitle": "New Card",
              "laneId": "wGzrjxCb85kpTEqvaucY",
              "laneName": "To Do"
            }
          },
          "PdVSa8SRHKACSzcbZu70": {
            "boardId": "uysAvnxpDG4EbdbI7r1Y",
            "workspaceId": "xKnLu20t7n6A0IJxl4NN",
            "userId": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "userDisplayName": "bew kiw",
            "userPhotoURL": null,
            "type": "card-create",
            "timestamp": 1755845253327,
            "details": {
              "cardId": "k2vbyyOc5RkyyA1fWQE0",
              "cardTitle": "New Card",
              "laneId": "wGzrjxCb85kpTEqvaucY",
              "laneName": "To Do"
            }
          },
          "SZgrmbo6lFnrPsSeKPN1": {
            "boardId": "Mop2RUYjlM9kRoXGa001",
            "workspaceId": "xKnLu20t7n6A0IJxl4NN",
            "userId": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "userDisplayName": "bew kiw",
            "userPhotoURL": null,
            "type": "card-move",
            "timestamp": 1756052201348,
            "details": {
              "cardId": "9ZqnRBV0fWvaHh40wQwS",
              "cardTitle": "New Card",
              "sourceLaneId": "qesjwQS3saV9h3wzyYMz",
              "sourceLaneName": "In Progress",
              "destinationLaneId": "D8FI6YQaNYQLZavNCnyC",
              "destinationLaneName": "To Do"
            }
          },
          "YErecfLlgMJKMW3NjdYm": {
            "boardId": "Mop2RUYjlM9kRoXGa001",
            "workspaceId": "xKnLu20t7n6A0IJxl4NN",
            "userId": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "userDisplayName": "bew kiw",
            "userPhotoURL": null,
            "type": "card-move",
            "timestamp": 1756052276335,
            "details": {
              "cardId": "FIFVO81Kg4EfzdCUpZwI",
              "cardTitle": "New Cardๅ_กก",
              "sourceLaneId": "qesjwQS3saV9h3wzyYMz",
              "sourceLaneName": "In Progress",
              "destinationLaneId": "nOsAcuKYIaNx4gDblwJO",
              "destinationLaneName": "1111"
            }
          },
          "dSH0dRhDp5BwwQToUf6j": {
            "boardId": "Mop2RUYjlM9kRoXGa001",
            "workspaceId": "xKnLu20t7n6A0IJxl4NN",
            "userId": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "userDisplayName": "bew kiw",
            "userPhotoURL": null,
            "type": "card-move",
            "timestamp": 1756092317443,
            "details": {
              "cardId": "FIFVO81Kg4EfzdCUpZwI",
              "cardTitle": "123456",
              "sourceLaneId": "nvx4rzpcNcJk8GIw4YsK",
              "sourceLaneName": "Done",
              "destinationLaneId": "qesjwQS3saV9h3wzyYMz",
              "destinationLaneName": "In Progress"
            }
          },
          "k9ZVRhpsMH40xdgDkVx0": {
            "boardId": "uysAvnxpDG4EbdbI7r1Y",
            "workspaceId": "xKnLu20t7n6A0IJxl4NN",
            "userId": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "userDisplayName": "bew kiw",
            "userPhotoURL": null,
            "type": "card-update-field",
            "timestamp": 1755857282003,
            "details": {
              "cardId": "k2vbyyOc5RkyyA1fWQE0",
              "cardTitle": "New Cardด",
              "fieldName": "Expenses"
            }
          },
          "kXdr8iN8j1suwVxoSaZK": {
            "boardId": "Mop2RUYjlM9kRoXGa001",
            "workspaceId": "xKnLu20t7n6A0IJxl4NN",
            "userId": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "userDisplayName": "bew kiw",
            "userPhotoURL": null,
            "type": "card-create",
            "timestamp": 1756137392624,
            "details": {
              "cardId": "gyJt5atnNjuHOZRxbW0i",
              "cardTitle": "New Job23",
              "laneId": "D8FI6YQaNYQLZavNCnyC",
              "laneName": "To Do"
            }
          },
          "oFT0uQUr8RU7s07AgANu": {
            "boardId": "Mop2RUYjlM9kRoXGa001",
            "workspaceId": "xKnLu20t7n6A0IJxl4NN",
            "userId": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "userDisplayName": "bew kiw",
            "userPhotoURL": null,
            "type": "card-move",
            "timestamp": 1756052302923,
            "details": {
              "cardId": "FIFVO81Kg4EfzdCUpZwI",
              "cardTitle": "123456",
              "sourceLaneId": "nOsAcuKYIaNx4gDblwJO",
              "sourceLaneName": "1111",
              "destinationLaneId": "nvx4rzpcNcJk8GIw4YsK",
              "destinationLaneName": "Done"
            }
          },
          "sn9v7FbTImAMRHvA0Nox": {
            "boardId": "uysAvnxpDG4EbdbI7r1Y",
            "workspaceId": "xKnLu20t7n6A0IJxl4NN",
            "userId": "d3z7heLqwYXXC3u3O9uR7iO9ium2",
            "userDisplayName": "BewLnwZa",
            "userPhotoURL": null,
            "type": "card-create",
            "timestamp": 1756116207830,
            "details": {
              "cardId": "zurP2JTWc5PkQMxferzT",
              "cardTitle": "New Job",
              "laneId": "wGzrjxCb85kpTEqvaucY",
              "laneName": "To Do"
            }
          },
          "vmRw80PF3umcUg4xyrq5": {
            "boardId": "uysAvnxpDG4EbdbI7r1Y",
            "workspaceId": "xKnLu20t7n6A0IJxl4NN",
            "userId": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "userDisplayName": "bew kiw",
            "userPhotoURL": null,
            "type": "card-update-field",
            "timestamp": 1755848033365,
            "details": {
              "cardId": "k2vbyyOc5RkyyA1fWQE0",
              "cardTitle": "New Cardด",
              "fieldName": "Title",
              "from": "New Card",
              "to": "New Cardด"
            }
          }
        },
        "workspaces/xKnLu20t7n6A0IJxl4NN/boards": {
          "Mop2RUYjlM9kRoXGa001": {
            "createdAt": {
              "_seconds": 1755854785,
              "_nanoseconds": 712489000
            },
            "createdBy": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "lanes": [],
            "memberUids": [
              "xvdZZF0XGsWwR1yZtUdG8cQQgtU2"
            ],
            "members": [
              {
                "displayName": "Mobile User",
                "email": "mobile-user@example.com",
                "language": "en",
                "photoURL": null,
                "role": "owner",
                "uid": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
                "workspaces": []
              }
            ],
            "name": "New Board",
            "updatedAt": {
              "_seconds": 1755854785,
              "_nanoseconds": 712758000
            },
            "workspaceId": "xKnLu20t7n6A0IJxl4NN",
            "todoTemplates": [
              {
                "id": "template-1756883110952",
                "name": "bewtest 1111",
                "todos": []
              },
              {
                "id": "template-1756883120551",
                "name": "bewtest11112",
                "todos": []
              }
            ]
          },
          "uysAvnxpDG4EbdbI7r1Y": {
            "createdBy": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "lanes": [],
            "name": "My First Board",
            "workspaceId": "xKnLu20t7n6A0IJxl4NN",
            "memberUids": [
              "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
              "d3z7heLqwYXXC3u3O9uR7iO9ium2"
            ],
            "members": [
              {
                "displayName": "User",
                "email": "ja@gmail.com",
                "language": "en",
                "photoURL": null,
                "role": "owner",
                "uid": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
                "workspaces": []
              },
              {
                "displayName": "BewLnwZa",
                "uid": "d3z7heLqwYXXC3u3O9uR7iO9ium2",
                "email": "jarukit.bunchan@gmail.com",
                "photoURL": null,
                "workspaces": [
                  {
                    "id": "xKnLu20t7n6A0IJxl4NN",
                    "name": "test1",
                    "role": "admin"
                  }
                ],
                "language": "en"
              }
            ]
          }
        },
        "workspaces/xKnLu20t7n6A0IJxl4NN/cards": {
          "3jxu5Me8oI3sjhAkLek2": {
            "boardId": "uysAvnxpDG4EbdbI7r1Y",
            "laneId": "9V1OtWzxrwJpLLFZoJHp",
            "workspaceId": "xKnLu20t7n6A0IJxl4NN",
            "title": "New Job",
            "description": "",
            "customFields": [],
            "status": "Pending",
            "expenses": [],
            "todos": [],
            "notes": [],
            "assignedTo": "d3z7heLqwYXXC3u3O9uR7iO9ium2",
            "watchers": [],
            "createdAt": 1756116274788,
            "updatedAt": 1756116266825,
            "createdBy": "d3z7heLqwYXXC3u3O9uR7iO9ium2",
            "updatedBy": "d3z7heLqwYXXC3u3O9uR7iO9ium2",
            "updatedByDisplayName": "BewLnwZa",
            "order": 1,
            "customer": "Bew",
            "customerId": "WNF9tUB8pFM6QKQw9Fj3",
            "company": null,
            "customId": "JB-250825-0016"
          },
          "6VAYUMDzobYF1cTzMOax": {
            "boardId": "Mop2RUYjlM9kRoXGa001",
            "laneId": "D8FI6YQaNYQLZavNCnyC",
            "workspaceId": "xKnLu20t7n6A0IJxl4NN",
            "customFields": [],
            "notes": [],
            "assignedTo": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "createdAt": 1756140015392,
            "createdBy": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "updatedBy": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "updatedByDisplayName": "bew kiw",
            "customer": "Bew",
            "customerId": "WNF9tUB8pFM6QKQw9Fj3",
            "customId": "JB-250825-0025",
            "id": "6VAYUMDzobYF1cTzMOax",
            "memberUids": [
              ""
            ],
            "members": [],
            "lanes": [
              "D8FI6YQaNYQLZavNCnyC"
            ],
            "name": "123456ดด",
            "workspaces": [
              {
                "id": "xKnLu20t7n6A0IJxl4NN",
                "name": "",
                "role": "member"
              }
            ],
            "hashtags": [
              {
                "color": "#eab308",
                "id": "bew1234455",
                "text": "Bew1234455"
              },
              {
                "color": "#f97316",
                "id": "bew213",
                "text": "Bew213"
              }
            ],
            "hashtag": "#Bew1234455 #Bew213",
            "todos": [
              {
                "id": "todo-1756233374696",
                "title": "test115022",
                "completed": false,
                "dueDate": 1756256760000
              },
              {
                "id": "todo-1756233931754",
                "title": "",
                "completed": false
              }
            ],
            "status": "Cancelled",
            "expenses": [
              {
                "id": "exp-1756351748426-RwedKMymVqN8W3nFYbJP",
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
            "endDate": 1757091600000,
            "quotationTemplateId": "",
            "startDate": 1756746000000,
            "dueDateLose": 1756746000000,
            "customerInterest": "กลาง (Medium)",
            "company": {
              "id": "aVGCGee5LmYsr9oXYfE8",
              "label": "Main",
              "value": "colaco company"
            },
            "collaborators": [
              "d3z7heLqwYXXC3u3O9uR7iO9ium2",
              "xvdZZF0XGsWwR1yZtUdG8cQQgtU2"
            ],
            "descriptionMentions": [],
            "order": 1,
            "watchers": [
              "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
              "d3z7heLqwYXXC3u3O9uR7iO9ium2"
            ],
            "title": "1111",
            "description": "<h1><em><u>Bew111111234</u></em></h1>",
            "attachments": [
              {
                "id": "workspaces/xKnLu20t7n6A0IJxl4NN/cards/6VAYUMDzobYF1cTzMOax/1756874147072-Screenshot 2025-09-03 at 9.42.37 AM.png",
                "name": "Screenshot 2025-09-03 at 9.42.37 AM.png",
                "filename": "Screenshot 2025-09-03 at 9.42.37 AM.png",
                "url": "https://firebasestorage.googleapis.com/v0/b/kanbanflow-iq93h.firebasestorage.app/o/workspaces%2FxKnLu20t7n6A0IJxl4NN%2Fcards%2F6VAYUMDzobYF1cTzMOax%2F1756874147072-Screenshot%202025-09-03%20at%209.42.37%E2%80%AFAM.png?alt=media&token=0c0864ea-0747-4aac-a0da-adc5c335bc05",
                "uploadedAt": 1756874148176,
                "size": 178795,
                "uploadedBy": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2"
              },
              {
                "id": "workspaces/xKnLu20t7n6A0IJxl4NN/cards/6VAYUMDzobYF1cTzMOax/1756874161312-sample1.epub",
                "name": "sample1.epub",
                "filename": "sample1.epub",
                "url": "https://firebasestorage.googleapis.com/v0/b/kanbanflow-iq93h.firebasestorage.app/o/workspaces%2FxKnLu20t7n6A0IJxl4NN%2Fcards%2F6VAYUMDzobYF1cTzMOax%2F1756874161312-sample1.epub?alt=media&token=2bf99d8e-fc5b-47e0-b3d3-6f2930008d48",
                "uploadedAt": 1756874162340,
                "size": 191468,
                "uploadedBy": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2"
              }
            ],
            "updatedAt": 1756874162340
          },
          "CAHAmmRF3dHOKGfhfMc3": {
            "assignedTo": "d3z7heLqwYXXC3u3O9uR7iO9ium2",
            "boardId": "Mop2RUYjlM9kRoXGa001",
            "createdAt": 1756283526086,
            "createdBy": "d3z7heLqwYXXC3u3O9uR7iO9ium2",
            "customId": "JB-270825-0027",
            "customer": "testssss",
            "customerId": "IhxyfTOYQ6k1UxmdMTT2",
            "laneId": "qesjwQS3saV9h3wzyYMz",
            "lanes": [
              "qesjwQS3saV9h3wzyYMz"
            ],
            "memberUids": [
              "d3z7heLqwYXXC3u3O9uR7iO9ium2"
            ],
            "members": [],
            "name": "123456789120.00",
            "order": 0,
            "title": "123456789120.00",
            "updatedBy": "d3z7heLqwYXXC3u3O9uR7iO9ium2",
            "updatedByDisplayName": "BewLnwZa",
            "workspaceId": "xKnLu20t7n6A0IJxl4NN",
            "workspaces": [
              {
                "id": "xKnLu20t7n6A0IJxl4NN",
                "name": "",
                "role": "member"
              }
            ],
            "id": "CAHAmmRF3dHOKGfhfMc3",
            "status": "Done",
            "expenses": [
              {
                "id": "exp-1756351733796-34N6d2Az4sYF7ZHvyFHN",
                "productId": "34N6d2Az4sYF7ZHvyFHN",
                "name": "Example html",
                "description": "",
                "quantity": 1,
                "unit": "item",
                "pricePerUnit": 51234,
                "discount": 0,
                "discountType": "amount"
              }
            ],
            "attachments": [],
            "notes": [],
            "hashtags": [],
            "endDate": 1753981200000,
            "customFields": [],
            "description": "",
            "watchers": [],
            "collaborators": [],
            "quotationTemplateId": "",
            "todos": [],
            "startDate": 1751130000000,
            "updatedAt": 1756784163281
          },
          "NHwtI90GGgXCvRarNPMP": {
            "assignedTo": "d3z7heLqwYXXC3u3O9uR7iO9ium2",
            "badges": [
              "Bew213",
              "Bew1234455"
            ],
            "boardId": "Mop2RUYjlM9kRoXGa001",
            "createdAt": 1756802238831,
            "createdBy": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "customId": "JB-020925-0028",
            "customer": "testssss",
            "customerId": "IhxyfTOYQ6k1UxmdMTT2",
            "description": "test1234",
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
            "laneId": "D8FI6YQaNYQLZavNCnyC",
            "lanes": [
              "D8FI6YQaNYQLZavNCnyC"
            ],
            "memberUids": [
              "xvdZZF0XGsWwR1yZtUdG8cQQgtU2"
            ],
            "members": [],
            "name": "New Card",
            "order": 0,
            "title": "New Card",
            "updatedBy": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "updatedByDisplayName": "BewLnwZa",
            "workspaceId": "xKnLu20t7n6A0IJxl4NN",
            "workspaces": [
              {
                "id": "xKnLu20t7n6A0IJxl4NN",
                "name": "",
                "role": "member"
              }
            ],
            "attachments": [],
            "notes": [],
            "customFields": [],
            "dueDate": {
              "seconds": 1758906000,
              "nanoseconds": 0
            },
            "watchers": [],
            "collaborators": [],
            "quotationTemplateId": "",
            "company": {
              "value": "test",
              "id": "Z1h1nm9GM2nfusJh7YuD",
              "label": "Main"
            },
            "id": "NHwtI90GGgXCvRarNPMP",
            "todos": [],
            "expenses": [],
            "status": "Archived",
            "updatedAt": 1756874054375
          },
          "YRd0VCq8PZ0ZO1SpYHw5": {
            "assignedTo": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "boardId": "Mop2RUYjlM9kRoXGa001",
            "createdAt": 1756283362326,
            "createdBy": "d3z7heLqwYXXC3u3O9uR7iO9ium2",
            "customId": "JB-270825-0026",
            "customer": "Bew",
            "customerId": "WNF9tUB8pFM6QKQw9Fj3",
            "laneId": "D8FI6YQaNYQLZavNCnyC",
            "lanes": [
              "D8FI6YQaNYQLZavNCnyC"
            ],
            "memberUids": [
              "d3z7heLqwYXXC3u3O9uR7iO9ium2"
            ],
            "members": [],
            "name": "test0123465",
            "status": "Pending",
            "title": "test0123465",
            "updatedBy": "d3z7heLqwYXXC3u3O9uR7iO9ium2",
            "updatedByDisplayName": "bew kiw",
            "workspaceId": "xKnLu20t7n6A0IJxl4NN",
            "workspaces": [
              {
                "id": "xKnLu20t7n6A0IJxl4NN",
                "name": "",
                "role": "member"
              }
            ],
            "id": "YRd0VCq8PZ0ZO1SpYHw5",
            "expenses": [
              {
                "id": "exp-1756351741174-34N6d2Az4sYF7ZHvyFHN",
                "productId": "34N6d2Az4sYF7ZHvyFHN",
                "name": "Example html",
                "description": "",
                "quantity": 1,
                "unit": "item",
                "pricePerUnit": 51234,
                "discount": 0,
                "discountType": "amount"
              }
            ],
            "attachments": [],
            "notes": [],
            "hashtags": [],
            "endDate": 1761757200000,
            "customFields": [],
            "description": "",
            "watchers": [],
            "collaborators": [],
            "quotationTemplateId": "",
            "todos": [],
            "startDate": 1758992400000,
            "customerInterest": "น้อย (Low)",
            "order": 2,
            "updatedAt": 1756802252701
          },
          "zurP2JTWc5PkQMxferzT": {
            "boardId": "uysAvnxpDG4EbdbI7r1Y",
            "laneId": "wGzrjxCb85kpTEqvaucY",
            "workspaceId": "xKnLu20t7n6A0IJxl4NN",
            "title": "New Job",
            "customFields": [],
            "expenses": [],
            "todos": [],
            "notes": [],
            "watchers": [],
            "createdBy": "d3z7heLqwYXXC3u3O9uR7iO9ium2",
            "updatedBy": "d3z7heLqwYXXC3u3O9uR7iO9ium2",
            "updatedByDisplayName": "BewLnwZa",
            "order": 1,
            "customerId": "WNF9tUB8pFM6QKQw9Fj3",
            "customId": "JB-250825-0015",
            "createdAt": {
              "_seconds": 1756116207,
              "_nanoseconds": 377000000
            },
            "dueDate": {
              "_seconds": 1755795600,
              "_nanoseconds": 0
            },
            "lanes": [
              "wGzrjxCb85kpTEqvaucY"
            ],
            "name": "New Job",
            "description": "test",
            "company": "test112345",
            "assignedTo": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "customer": "testssss",
            "status": "Cancelled",
            "updatedAt": {
              "_seconds": 1756119026,
              "_nanoseconds": 606424000
            }
          }
        },
        "workspaces/xKnLu20t7n6A0IJxl4NN/companies": {
          "Vr6SXzHlVkWsYJYnyiMJ": {
            "name": "test112345",
            "emails": [
              {
                "id": "email-initial",
                "label": "Main",
                "value": ""
              }
            ],
            "phones": [
              {
                "id": "phone-initial",
                "label": "Main",
                "value": ""
              }
            ],
            "workspaceId": "xKnLu20t7n6A0IJxl4NN",
            "customId": "COM-250822-0002",
            "createdAt": 1755851285082,
            "updatedAt": 1755851285082,
            "createdBy": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "updatedBy": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "associatedCustomerIds": [
              "IhxyfTOYQ6k1UxmdMTT2"
            ]
          },
          "Z1h1nm9GM2nfusJh7YuD": {
            "name": "test",
            "emails": [
              {
                "id": "email-initial",
                "label": "Main",
                "value": ""
              }
            ],
            "phones": [
              {
                "id": "phone-initial",
                "label": "Main",
                "value": ""
              }
            ],
            "workspaceId": "xKnLu20t7n6A0IJxl4NN",
            "customId": "COM-250822-0001",
            "createdAt": 1755851273203,
            "updatedAt": 1755851273203,
            "createdBy": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "updatedBy": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "associatedCustomerIds": [
              "IhxyfTOYQ6k1UxmdMTT2"
            ]
          },
          "aVGCGee5LmYsr9oXYfE8": {
            "name": "colaco company",
            "emails": [
              {
                "id": "email-initial",
                "label": "Main",
                "value": ""
              }
            ],
            "phones": [
              {
                "id": "phone-initial",
                "label": "Main",
                "value": ""
              }
            ],
            "workspaceId": "xKnLu20t7n6A0IJxl4NN",
            "customId": "COM-250902-0003",
            "createdAt": 1756797510936,
            "updatedAt": 1756797510936,
            "createdBy": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "updatedBy": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "associatedCustomerIds": [
              "WNF9tUB8pFM6QKQw9Fj3"
            ]
          }
        },
        "workspaces/xKnLu20t7n6A0IJxl4NN/customers": {
          "IhxyfTOYQ6k1UxmdMTT2": {
            "emails": [
              {
                "id": "email-initial",
                "label": "Work",
                "value": ""
              }
            ],
            "phones": [
              {
                "id": "phone-initial",
                "label": "Work",
                "value": ""
              }
            ],
            "customFields": [],
            "name": "testssss",
            "workspaceId": "xKnLu20t7n6A0IJxl4NN",
            "customId": "CUS-250822-0002",
            "createdAt": 1755850137421,
            "createdBy": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "updatedBy": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "companyNames": [
              {
                "id": "Z1h1nm9GM2nfusJh7YuD",
                "label": "Main",
                "value": "test"
              },
              {
                "id": "Vr6SXzHlVkWsYJYnyiMJ",
                "label": "Main",
                "value": "test112345"
              }
            ],
            "updatedAt": 1755851285241
          },
          "WNF9tUB8pFM6QKQw9Fj3": {
            "emails": [
              {
                "id": "email-initial",
                "label": "Work",
                "value": ""
              }
            ],
            "phones": [
              {
                "id": "phone-initial",
                "label": "Work",
                "value": ""
              }
            ],
            "customFields": [],
            "name": "Bew",
            "workspaceId": "xKnLu20t7n6A0IJxl4NN",
            "customId": "CUS-250822-0001",
            "createdAt": 1755845245761,
            "createdBy": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "assignees": [
              "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
              "d3z7heLqwYXXC3u3O9uR7iO9ium2"
            ],
            "updatedBy": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "companyNames": [
              {
                "id": "aVGCGee5LmYsr9oXYfE8",
                "label": "Main",
                "value": "colaco company"
              }
            ],
            "updatedAt": 1756797511482
          }
        },
        "workspaces/xKnLu20t7n6A0IJxl4NN/lanes": {
          "9V1OtWzxrwJpLLFZoJHp": {
            "boardId": "uysAvnxpDG4EbdbI7r1Y",
            "name": "Bewtest01",
            "order": 2,
            "cards": [],
            "hasMoreCards": false
          },
          "D8FI6YQaNYQLZavNCnyC": {
            "boardId": "Mop2RUYjlM9kRoXGa001",
            "cards": [],
            "createdAt": {
              "_seconds": 1755854785,
              "_nanoseconds": 732803000
            },
            "hasMoreCards": false,
            "name": "To Do",
            "order": 0,
            "updatedAt": {
              "_seconds": 1755854785,
              "_nanoseconds": 732809000
            },
            "workspaceId": "xKnLu20t7n6A0IJxl4NN"
          },
          "DHFougr6LuOrTwGN3pri": {
            "boardId": "xKnLu20t7n6A0IJxl4NN",
            "cards": [],
            "hasMoreCards": false,
            "name": "ๅๅๅๅๅ",
            "order": 4,
            "title": "ๅๅๅๅๅ",
            "workspaceId": "xKnLu20t7n6A0IJxl4NN"
          },
          "IOcSsForm8B4n9UwIGRo": {
            "boardId": "uysAvnxpDG4EbdbI7r1Y",
            "cards": [],
            "hasMoreCards": false,
            "name": "In Progress",
            "order": 1,
            "workspaceId": "xKnLu20t7n6A0IJxl4NN"
          },
          "JgWkDARvDVUsVTcpBB0R": {
            "boardId": "xKnLu20t7n6A0IJxl4NN",
            "cards": [],
            "hasMoreCards": false,
            "name": "ๅๅๅๅ",
            "order": 4,
            "title": "ๅๅๅๅ",
            "workspaceId": "xKnLu20t7n6A0IJxl4NN"
          },
          "hNGhlwpn4AYa4zje3own": {
            "boardId": "Mop2RUYjlM9kRoXGa001",
            "cards": [],
            "createdAt": {
              "_seconds": 1756696678,
              "_nanoseconds": 690054000
            },
            "hasMoreCards": false,
            "name": "กฟกด",
            "order": 3,
            "title": "กฟกด",
            "updatedAt": {
              "_seconds": 1756696678,
              "_nanoseconds": 690060000
            },
            "workspaceId": "xKnLu20t7n6A0IJxl4NN"
          },
          "nvx4rzpcNcJk8GIw4YsK": {
            "boardId": "Mop2RUYjlM9kRoXGa001",
            "cards": [],
            "createdAt": {
              "_seconds": 1755854785,
              "_nanoseconds": 732943000
            },
            "hasMoreCards": false,
            "name": "Done",
            "order": 2,
            "updatedAt": {
              "_seconds": 1755854785,
              "_nanoseconds": 732943000
            },
            "workspaceId": "xKnLu20t7n6A0IJxl4NN"
          },
          "qesjwQS3saV9h3wzyYMz": {
            "boardId": "Mop2RUYjlM9kRoXGa001",
            "cards": [],
            "createdAt": {
              "_seconds": 1755854785,
              "_nanoseconds": 732911000
            },
            "hasMoreCards": false,
            "name": "In Progress",
            "order": 1,
            "updatedAt": {
              "_seconds": 1755854785,
              "_nanoseconds": 732911000
            },
            "workspaceId": "xKnLu20t7n6A0IJxl4NN"
          },
          "wGzrjxCb85kpTEqvaucY": {
            "boardId": "uysAvnxpDG4EbdbI7r1Y",
            "cards": [],
            "hasMoreCards": false,
            "name": "To Do",
            "order": 0,
            "workspaceId": "xKnLu20t7n6A0IJxl4NN",
            "title": "To Doดดด"
          }
        },
        "workspaces/xKnLu20t7n6A0IJxl4NN/products": {
          "34N6d2Az4sYF7ZHvyFHN": {
            "status": "draft",
            "showInCatalog": true,
            "customFields": [],
            "imageUrl": "https://firebasestorage.googleapis.com/v0/b/kanbanflow-iq93h.firebasestorage.app/o/products%2Fnew_product%2F1756351122351-jpg1.jpg%2F1756351122352-jpg1.jpg?alt=media&token=9c377737-3143-4918-846a-b5bb9dd373c1",
            "name": "Example html",
            "unit": "",
            "costPrice": 0,
            "initialStock": 0,
            "reorderLevel": 0,
            "targetStockLevel": 0,
            "features": [],
            "sku": "P-250828-0002",
            "workspaceId": "xKnLu20t7n6A0IJxl4NN",
            "createdAt": 1756351145017,
            "searchableKeywords": [
              "example",
              "html",
              "p-250828-0002"
            ],
            "price": 51234,
            "availableStock": 0,
            "id": "34N6d2Az4sYF7ZHvyFHN",
            "updatedAt": 1756351672261
          },
          "RwedKMymVqN8W3nFYbJP": {
            "status": "draft",
            "showInCatalog": true,
            "customFields": [],
            "imageUrl": "https://firebasestorage.googleapis.com/v0/b/kanbanflow-iq93h.firebasestorage.app/o/products%2Fnew_product%2F1756263863933-jpeg2.jpeg%2F1756263863933-jpeg2.jpeg?alt=media&token=e0953010-4c61-442f-b2ad-599a5725e28f",
            "name": "test1",
            "costPrice": 0,
            "initialStock": 0,
            "reorderLevel": 0,
            "targetStockLevel": 0,
            "features": [],
            "sku": "P-250827-0001",
            "workspaceId": "xKnLu20t7n6A0IJxl4NN",
            "createdAt": 1756263867416,
            "searchableKeywords": [
              "test1",
              "p-250827-0001"
            ],
            "availableStock": 0,
            "id": "RwedKMymVqN8W3nFYbJP",
            "price": 11223344,
            "updatedAt": 1756351684876
          }
        }
      }
    }
  }
}
```
#### users/{user UIDs}/
```
{
  "users": {
    "d3z7heLqwYXXC3u3O9uR7iO9ium2": {
      "uid": "d3z7heLqwYXXC3u3O9uR7iO9ium2",
      "email": "jarukit.bunchan@gmail.com",
      "displayName": "BewLnwZa",
      "photoURL": null,
      "language": "en",
      "workspaces": [
        {
          "id": "xKnLu20t7n6A0IJxl4NN",
          "name": "test1",
          "role": "admin"
        },
        {
          "id": "Hh8DkaJ88XXgjtJwOlqi",
          "name": "BewLnwZa007",
          "role": "owner"
        }
      ],
      "lastActiveWorkspaceId": "xKnLu20t7n6A0IJxl4NN",
      "lastDeviceId": "2F2A576C-CF24-4BD1-AA70-6BD4321C51C5",
      "lastPlatform": "ios",
      "fcmToken": "cmdEXYZ-5EL8s6U-iahfRr:APA91bFX1yyn61IVMfhPYoYkyJ424YLfQH3UjCosnclpvABxQY_CV2vPj1bELYmBcQ6wbnuFA5A-wn_TLgSYTsz9ckG0FPtYkY0wLivf27h6iWPRE71dOXc",
      "fcmTokenUpdatedAt": {
        "_seconds": 1756283312,
        "_nanoseconds": 79000000
      },
      "subCollection": {
        "users/d3z7heLqwYXXC3u3O9uR7iO9ium2/devices": {
          "2F2A576C-CF24-4BD1-AA70-6BD4321C51C5": {
            "forceSignOut": false,
            "isActive": true,
            "platform": "ios",
            "token": "cmdEXYZ-5EL8s6U-iahfRr:APA91bFX1yyn61IVMfhPYoYkyJ424YLfQH3UjCosnclpvABxQY_CV2vPj1bELYmBcQ6wbnuFA5A-wn_TLgSYTsz9ckG0FPtYkY0wLivf27h6iWPRE71dOXc",
            "updatedAt": {
              "_seconds": 1756283312,
              "_nanoseconds": 2000000
            }
          }
        }
      }
    }
  }
}
```