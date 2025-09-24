# Database structure for Board feature


## TodoList structure in Firestore
- Collection: `workspaces/{workspace_uid}/cards/{card_uid}/todos`
  - Type: json array
  - Fields: 
    - `id`: string (unique identifier for the todo item)
    - `title`: string (title of the todo item)
    - `dueDate`: timestamp (due date of the todo item,date time)
    - `completed`: boolean (status of the todo item, true if completed, false otherwise)
  - Example:
    ```json
    [
        {
                "completed": false,
                "dueDate": 1756918860000,
                "id": "todo-todo-todo-todo-todo-todo-todo-todo-1756975522376",
                "mentions": [],
                "title": "<p><span style=\"color: rgb(2, 8, 23); font-size: 24px;\"><strong><em></em></strong></span></p>"
        },
        {
                "completed": false,
                "dueDate": 1756918860000,
                "id": "todo-todo-todo-todo-todo-todo-todo-todo-1756975523853",
                "mentions": [],
                "title": "<p><span style=\"color: rgb(2, 8, 23); font-size: 24px;\"><strong><em></em></strong></span></p>"
        }
    ]
    ```
  