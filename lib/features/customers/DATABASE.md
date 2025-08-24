#DATBASE STRUCTURE

{
  "presences": {
    "%random uids%": {
      "uid": "string",
      "activeBoardId": "object",
      "lastSeen": "number"
    }
  },
  "quotationTemplates": {
    "XOEWskfy7cFrOPvVVZqS": {
      "name": "string",
      "font": "string",
      "imageElements": [
        {
          "id": "string",
          "url": "string",
          "position": {
            "x": "number",
            "y": "number"
          },
          "width": "number",
          "height": "number",
          "displayOn": "string",
          "type": "string",
          "opacity": "number",
          "rotation": "number"
        }
      ],
      "floatingTextBoxes": [
        {
          "id": "string",
          "text": "string",
          "position": {
            "x": "number",
            "y": "number"
          },
          "width": "number",
          "height": "number",
          "displayOn": "string",
          "style": {
            "fontSize": "string",
            "color": "string"
          }
        }
      ],
      "floatingTables": [],
      "headers": [
        {
          "id": "string",
          "displayOn": "string",
          "showSeparator": "boolean",
          "separatorConfig": {
            "style": "string",
            "color": "string",
            "thickness": "number"
          },
          "columns": [
            {
              "id": "string",
              "content": "string",
              "style": {
                "fontSize": "string",
                "color": "string",
                "paddingTop": "number",
                "paddingBottom": "number",
                "paddingLeft": "number",
                "paddingRight": "number"
              },
              "width": "string"
            }
          ]
        }
      ],
      "footers": [
        {
          "id": "string",
          "displayOn": "string",
          "columns": [
            {
              "id": "string",
              "content": "string",
              "style": {
                "fontSize": "string",
                "color": "string",
                "paddingTop": "number",
                "paddingBottom": "number",
                "paddingLeft": "number",
                "paddingRight": "number"
              },
              "width": "string"
            }
          ]
        }
      ],
      "body": [
        {
          "id": "string",
          "displayOn": "string",
          "columns": [
            {
              "id": "string",
              "content": "string",
              "style": {
                "fontSize": "string",
                "color": "string",
                "paddingTop": "number",
                "paddingBottom": "number",
                "paddingLeft": "number",
                "paddingRight": "number"
              },
              "width": "string"
            }
          ]
        }
      ],
      "tableStyle": {
        "headerBackgroundColor": "string",
        "headerTextColor": "string",
        "borderColor": "string",
        "borderWidth": "number",
        "headerBorderTopLeftRadius": "number",
        "headerBorderTopRightRadius": "number",
        "headerBorderBottomLeftRadius": "number",
        "headerBorderBottomRightRadius": "number",
        "layout": "string"
      },
      "columns": [
        {
          "id": "string",
          "label": "string",
          "type": "string"
        }
      ],
      "summaryRows": [
        {
          "id": "string",
          "label": "string",
          "value": "string"
        }
      ],
      "createdAt": {
        "_seconds": "number",
        "_nanoseconds": "number"
      }
    }
  },
  "test": {
    "connection_test": {
      "status": "string",
      "test": "boolean",
      "timestamp": {
        "_seconds": "number",
        "_nanoseconds": "number"
      }
    }
  },
  "userFilters": {
    "%random uids%": {
      "userId": "string",
      "boardId": "string",
      "name": "string",
      "filterData": {
        "assignee": [],
        "customer": [],
        "status": "object",
        "searchQuery": "string",
        "boardSort": "string",
        "dateFilter": {
          "fields": [
            "string"
          ],
          "range": "object",
          "includeCardsWithNoDate": "boolean"
        }
      },
      "createdAt": "number"
    }
  },
  "users": {
    "%random uids%": {
      "uid": "string",
      "email": "string",
      "displayName": "string",
      "photoURL": "object",
      "language": "string",
      "customId": "string",
      "workspaces": [
        {
          "id": "string",
          "name": "string",
          "role": "string"
        }
      ],
      "viewSettings": {
        "kanbanCardDisplayFieldsConfig_JRKLY5ne1TjCxWSAXtjO": {
          "todos": {
            "isVisible": "boolean",
            "style": {},
            "order": "number"
          },
          "customer": {
            "isVisible": "boolean",
            "style": {},
            "order": "number"
          },
          "totalAmountBeforeDiscount": {
            "order": "number",
            "style": {},
            "isVisible": "boolean"
          },
          "totalAmountBeforeVat": {
            "style": {},
            "order": "number",
            "isVisible": "boolean"
          },
          "priority": {
            "style": {},
            "order": "number",
            "isVisible": "boolean"
          },
          "assignee": {
            "style": {},
            "order": "number",
            "isVisible": "boolean"
          },
          "hashtags": {
            "order": "number",
            "style": {},
            "isVisible": "boolean"
          },
          "grandTotal": {
            "order": "number",
            "style": {},
            "isVisible": "boolean"
          },
          "netTotal": {
            "isVisible": "boolean",
            "order": "number",
            "style": {}
          },
          "company": {
            "order": "number",
            "style": {},
            "isVisible": "boolean"
          },
          "description": {
            "style": {},
            "isVisible": "boolean",
            "order": "number"
          },
          "totalAmountAfterDiscount": {
            "style": {},
            "isVisible": "boolean",
            "order": "number"
          },
          "customId": {
            "isVisible": "boolean",
            "order": "number",
            "style": {}
          },
          "status": {
            "style": {},
            "isVisible": "boolean",
            "order": "number"
          },
          "dueDate": {
            "isVisible": "boolean",
            "style": {},
            "order": "number"
          }
        },
        "customerProfileCardsConfig_9feJ0Ne6IpAB6eLOIgmA": {
          "customer": {
            "style": {},
            "order": "number",
            "isVisible": "boolean"
          },
          "status": {
            "isVisible": "boolean",
            "style": {},
            "order": "number"
          },
          "todos": {
            "style": {},
            "order": "number",
            "isVisible": "boolean"
          },
          "hashtags": {
            "isVisible": "boolean",
            "style": {},
            "order": "number"
          },
          "lane": {
            "style": {},
            "isVisible": "boolean",
            "order": "number"
          },
          "netTotal": {
            "isVisible": "boolean",
            "style": {},
            "order": "number"
          },
          "grandTotal": {
            "order": "number",
            "isVisible": "boolean",
            "style": {}
          },
          "company": {
            "style": {},
            "isVisible": "boolean",
            "order": "number"
          },
          "title": {
            "order": "number",
            "isVisible": "boolean",
            "style": {}
          },
          "dueDate": {
            "isVisible": "boolean",
            "order": "number",
            "style": {}
          },
          "priority": {
            "style": {},
            "order": "number",
            "isVisible": "boolean"
          },
          "description": {
            "isVisible": "boolean",
            "style": {},
            "order": "number"
          },
          "totalAmountBeforeVat": {
            "isVisible": "boolean",
            "style": {},
            "order": "number"
          },
          "totalAmountBeforeDiscount": {
            "isVisible": "boolean",
            "order": "number",
            "style": {}
          },
          "assignee": {
            "style": {},
            "order": "number",
            "isVisible": "boolean"
          },
          "totalAmountAfterDiscount": {
            "style": {},
            "isVisible": "boolean",
            "order": "number"
          },
          "customId": {
            "order": "number",
            "style": {},
            "isVisible": "boolean"
          }
        },
        "customerProfileCardsConfig_vW81BM560QxvMrcSlpvI": {
          "title": {
            "isVisible": "boolean",
            "style": {},
            "order": "number"
          },
          "totalAmountAfterDiscount": {
            "isVisible": "boolean",
            "style": {},
            "order": "number"
          },
          "description": {
            "order": "number",
            "isVisible": "boolean",
            "style": {}
          },
          "grandTotal": {
            "isVisible": "boolean",
            "order": "number",
            "style": {}
          },
          "status": {
            "isVisible": "boolean",
            "order": "number",
            "style": {}
          },
          "customer": {
            "order": "number",
            "isVisible": "boolean",
            "style": {}
          },
          "totalAmountBeforeDiscount": {
            "order": "number",
            "style": {},
            "isVisible": "boolean"
          },
          "dueDate": {
            "order": "number",
            "isVisible": "boolean",
            "style": {}
          },
          "hashtags": {
            "order": "number",
            "style": {},
            "isVisible": "boolean"
          },
          "priority": {
            "order": "number",
            "isVisible": "boolean",
            "style": {}
          },
          "assignee": {
            "order": "number",
            "style": {},
            "isVisible": "boolean"
          },
          "netTotal": {
            "style": {},
            "isVisible": "boolean",
            "order": "number"
          },
          "company": {
            "style": {},
            "order": "number",
            "isVisible": "boolean"
          },
          "totalAmountBeforeVat": {
            "order": "number",
            "style": {},
            "isVisible": "boolean"
          },
          "lane": {
            "isVisible": "boolean",
            "style": {},
            "order": "number"
          },
          "todos": {
            "isVisible": "boolean",
            "style": {},
            "order": "number"
          },
          "customId": {
            "order": "number",
            "style": {},
            "isVisible": "boolean"
          }
        },
        "customerProfileCardsConfig_qMR2jAhrqHop0BjGsWon": {
          "customId": {
            "isVisible": "boolean",
            "order": "number",
            "style": {}
          },
          "title": {
            "isVisible": "boolean",
            "order": "number",
            "style": {}
          },
          "status": {
            "isVisible": "boolean",
            "order": "number",
            "style": {}
          },
          "lane": {
            "isVisible": "boolean",
            "order": "number",
            "style": {}
          },
          "dueDate": {
            "isVisible": "boolean",
            "order": "number",
            "style": {}
          },
          "assignee": {
            "isVisible": "boolean",
            "order": "number",
            "style": {}
          },
          "customer": {
            "isVisible": "boolean",
            "order": "number",
            "style": {}
          },
          "company": {
            "isVisible": "boolean",
            "order": "number",
            "style": {}
          },
          "hashtags": {
            "isVisible": "boolean",
            "order": "number",
            "style": {}
          },
          "priority": {
            "isVisible": "boolean",
            "order": "number",
            "style": {}
          },
          "grandTotal": {
            "isVisible": "boolean",
            "order": "number",
            "style": {}
          },
          "netTotal": {
            "isVisible": "boolean",
            "order": "number",
            "style": {}
          },
          "totalAmountBeforeDiscount": {
            "isVisible": "boolean",
            "order": "number",
            "style": {}
          },
          "totalAmountAfterDiscount": {
            "isVisible": "boolean",
            "order": "number",
            "style": {}
          },
          "totalAmountBeforeVat": {
            "isVisible": "boolean",
            "order": "number",
            "style": {}
          },
          "description": {
            "isVisible": "boolean",
            "order": "number",
            "style": {}
          },
          "todos": {
            "isVisible": "boolean",
            "order": "number",
            "style": {}
          }
        }
      }
    }
  },
  "workspaces": {
    "%random uids%": {
      "name": "string",
      "ownerId": "string",
      "members": {
        "D81BSUymXITWwDdw73KvpjqMZdv1": "string"
      },
      "createdAt": "number",
      "companyProfile": {
        "roles": [
          {
            "id": "string",
            "name": "string",
            "permissions": [
              "string"
            ]
          }
        ],
        "idGenerationRules": {
          "customer": {
            "prefix": "string",
            "dateFormat": "string",
            "separator": "string",
            "minLength": "number",
            "generationMode": "string"
          },
          "company": {
            "prefix": "string",
            "dateFormat": "string",
            "separator": "string",
            "minLength": "number",
            "generationMode": "string"
          },
          "product": {
            "prefix": "string",
            "dateFormat": "string",
            "separator": "string",
            "minLength": "number",
            "generationMode": "string"
          },
          "jobCard": {
            "prefix": "string",
            "dateFormat": "string",
            "separator": "string",
            "minLength": "number",
            "generationMode": "string"
          },
          "quotation": {
            "prefix": "string",
            "dateFormat": "string",
            "separator": "string",
            "minLength": "number",
            "generationMode": "string"
          },
          "invoice": {
            "prefix": "string",
            "dateFormat": "string",
            "separator": "string",
            "minLength": "number",
            "generationMode": "string"
          },
          "receipt": {
            "prefix": "string",
            "dateFormat": "string",
            "separator": "string",
            "minLength": "number",
            "generationMode": "string"
          }
        },
        "lastUsedCounters": {
          "customer": "number",
          "company": "number",
          "product": "number",
          "jobCard": "number",
          "quotation": "number",
          "invoice": "number",
          "receipt": "number"
        },
        "customerCustomFieldTemplate": [],
        "todoTemplates": [],
        "customerSources": [],
        "hashtagSettings": {
          "isEnabled": "boolean",
          "mode": "string",
          "masterList": [
            {
              "count": 0,
              "color": "#ef4444",
              "id": "hot",
              "enabled": true,
              "totalUsage": 2,
              "scopes": {
                "product": true,
                "chat": true,
                "jobBoard": true,
                "company": true,
                "customer": true
              },
              "usage": {
                "product": 1,
                "jobBoard": 1
              },
              "name": "hot"
            }
          ],
          "automation": {
            "autoCreateFromChat": "boolean"
          }
        },
        "catalogSettings": {
          "isPublished": "boolean",
          "enableAddToCart": "boolean"
        },
        "connections": {
          "line": [
            {
              "workspaceId": "string",
              "channelId": "string",
              "channelSecret": "string",
              "channelAccessToken": "string",
              "userId": "string",
              "displayName": "string",
              "statusMessage": "string",
              "webhookUrl": "string",
              "connectedAt": "number",
              "quota": {
                "used": "number",
                "total": "number"
              }
            }
          ]
        }
      },
      "subCollection": {
        "workspaces/0kuhij5hJtYDT344KjM1/boards": {
          "ruLtvnJH61Y1694vW8zU": {
            "name": "string",
            "workspaceId": "string",
            "createdBy": "string",
            "members": [
              {
                "uid": "string",
                "email": "string",
                "displayName": "string",
                "photoURL": "object",
                "customId": "string",
                "role": "string",
                "language": "string",
                "workspaces": []
              }
            ],
            "memberUids": [
              "string"
            ],
            "lanes": []
          }
        },
        "workspaces/0kuhij5hJtYDT344KjM1/lanes": {
          "22pL7MsMUnV9c9n9n1b7": {
            "boardId": "string",
            "workspaceId": "string",
            "name": "string",
            "order": "number",
            "cards": [],
            "hasMoreCards": "boolean"
          },
          "5QEdsSKsh0IIgc5mB8FK": {
            "boardId": "string",
            "workspaceId": "string",
            "name": "string",
            "order": "number",
            "cards": [],
            "hasMoreCards": "boolean"
          },
          "vdwdm6JShKJQcrfaBTKx": {
            "boardId": "string",
            "workspaceId": "string",
            "name": "string",
            "order": "number",
            "cards": [],
            "hasMoreCards": "boolean"
          }
        },
        "workspaces/0kuhij5hJtYDT344KjM1/logs": {
          "%random uids%": {
            "level": "string",
            "context": "string",
            "message": "string",
            "workspaceId": "string",
            "timestamp": "number"
          }
        }
      }
    }
  }
}