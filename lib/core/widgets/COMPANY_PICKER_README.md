# Overview
Company picker mean component that for use multiple page is that it like select option inside have company and have search for search company and have add button for add company

## DATABASE
### Example Firestore file for view reference how to get data
- `lib\data\repositories\firestore_repository.dart`
- `lib\data\services\firestore_service.dart`
- `lib\data\services\firestore_example.dart`

### Database Structure
**path**: workspaces/{uids}/companies

example data:

    ```json
    {
    "name": "a",
    "emails": [
        {
        "id": "email-initial",
        "label": "Main",
        "value": "d"
        },
        {
        "id": "contact-1756119925684",
        "label": "Work",
        "value": "e"
        }
    ],
    "phones": [
        {
        "id": "phone-initial",
        "label": "Main",
        "value": "f"
        },
        {
        "id": "contact-1756119928171",
        "label": "Work",
        "value": "g"
        }
    ],
    "taxId": "b",
    "branch": "c",
    "addressLine1": "h",
    "subdistrict": "i",
    "district": "j",
    "province": "k",
    "postalCode": "l",
    "country": "m",
    "hashtags": [
        {
        "id": "test",
        "text": "test",
        "color": "#eab308"
        },
        {
        "id": "tests",
        "text": "✅tests@🌚",
        "color": "#3b82f6"
        }
    ],
    "website": "n",
    "workspaceId": "5hMae0Og3XYVtM0T9XQR",
    "customId": "COM-250825-0002",
    "createdAt": 1756119939202,
    "updatedAt": 1756119939202,
    "createdBy": "0CaMzG4MyZdO0boiP2kaQYHTbSl1",
    "updatedBy": "0CaMzG4MyZdO0boiP2kaQYHTbSl1",
    "associatedCustomerIds": [
        "QnJaW3PPNnoKX5RgSYNH"
    ]
    }
    ```

    **remark** field "createdBy" mean id of authorite user