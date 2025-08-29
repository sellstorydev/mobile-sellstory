

# Mobile Webview API Documentation

This document outlines how to retrieve a secure webview URL for embedding specific settings pages from the SellStory web application into a mobile app.

## Get Hashtag Settings Webview URL

This endpoint generates a secure, single-use URL with an authentication token that allows a user to access the Hashtag Settings page within a webview without needing to log in again.

### Endpoint

```
GET /api/mobile/settings/hashtag
```

### Query Parameters

| Parameter     | Type   | Required | Description                                  |
|---------------|--------|----------|----------------------------------------------|
| `userId`      | string | Yes      | The unique identifier (UID) of the user.     |
| `workspaceId` | string | Yes      | The ID of the active workspace for the user. |

### Example Request

```http
GET /api/mobile/settings/hashtag?userId=ABC123XYZ&workspaceId=WKS456PQR
```

### Example Success Response (200 OK)

The server will respond with a JSON object containing the secure URL.

```json
{
  "success": true,
  "webviewUrl": "https://workspace.sellstory.me/settings/hashtag?token=[CUSTOM_AUTH_TOKEN]&workspaceId=WKS456PQR"
}
```

The mobile application should open the `webviewUrl` in a webview component. The user will be automatically authenticated and taken to the correct page.

### Example Error Response (400 Bad Request)

If the `userId` or `workspaceId` is missing from the request.

```json
{
  "error": "Missing userId or workspaceId"
}
```

### Example Error Response (500 Internal Server Error)

If the server fails to generate the custom token.

```json
{
  "success": false,
  "error": "Failed to generate webview link.",
  "details": "Specific error message from the server."
}
```

---

## Get Company Settings Webview URL

This endpoint generates a secure, single-use URL for the Company Settings page.

### Endpoint

```
GET /api/mobile/settings/company
```

### Query Parameters

| Parameter     | Type   | Required | Description                                  |
|---------------|--------|----------|----------------------------------------------|
| `userId`      | string | Yes      | The unique identifier (UID) of the user.     |
| `workspaceId` | string | Yes      | The ID of the active workspace for the user. |

### Example Request

```http
GET /api/mobile/settings/company?userId=ABC123XYZ&workspaceId=WKS456PQR
```

### Example Success Response (200 OK)

```json
{
  "success": true,
  "webviewUrl": "https://workspace.sellstory.me/settings/company?token=[CUSTOM_AUTH_TOKEN]&workspaceId=WKS456PQR"
}
```
---

## Get Board Settings Webview URL

This endpoint generates a secure, single-use URL for the Board Settings page.

### Endpoint

```
GET /api/mobile/settings/board
```

### Query Parameters

| Parameter     | Type   | Required | Description                                  |
|---------------|--------|----------|----------------------------------------------|
| `userId`      | string | Yes      | The unique identifier (UID) of the user.     |
| `workspaceId` | string | Yes      | The ID of the active workspace for the user. |

### Example Request

```http
GET /api/mobile/settings/board?userId=ABC123XYZ&workspaceId=WKS456PQR
```

### Example Success Response (200 OK)

```json
{
  "success": true,
  "webviewUrl": "https://workspace.sellstory.me/settings/board?token=[CUSTOM_AUTH_TOKEN]&workspaceId=WKS456PQR"
}
```
---

## Get Notification Settings Webview URL

This endpoint generates a secure, single-use URL for the Notification Settings page.

### Endpoint

```
GET /api/mobile/settings/notifications
```

### Query Parameters

| Parameter     | Type   | Required | Description                                  |
|---------------|--------|----------|----------------------------------------------|
| `userId`      | string | Yes      | The unique identifier (UID) of the user.     |
| `workspaceId` | string | Yes      | The ID of the active workspace for the user. |

### Example Request

```http
GET /api/mobile/settings/notifications?userId=ABC123XYZ&workspaceId=WKS456PQR
```

### Example Success Response (200 OK)

```json
{
  "success": true,
  "webviewUrl": "https://workspace.sellstory.me/settings/notifications?token=[CUSTOM_AUTH_TOKEN]&workspaceId=WKS456PQR"
}
```
---

## Get Welcome Message Settings Webview URL

This endpoint generates a secure, single-use URL for the Welcome Message Settings page.

### Endpoint

```
GET /api/mobile/settings/welcome-messages
```

### Query Parameters
Same as other endpoints (`userId`, `workspaceId`).

### Example Success Response (200 OK)

```json
{
  "success": true,
  "webviewUrl": "https://workspace.sellstory.me/settings/welcome-messages?token=[CUSTOM_AUTH_TOKEN]&workspaceId=WKS456PQR"
}
```
---

## Get Chatbot Settings Webview URL

This endpoint generates a secure, single-use URL for the Chatbot Settings page.

### Endpoint

```
GET /api/mobile/settings/chatbot
```

### Query Parameters
Same as other endpoints (`userId`, `workspaceId`).

### Example Success Response (200 OK)

```json
{
  "success": true,
  "webviewUrl": "https://workspace.sellstory.me/settings/chatbot?token=[CUSTOM_AUTH_TOKEN]&workspaceId=WKS456PQR"
}
```
---
## Get ID Generation Rules Webview URL

This endpoint generates a secure, single-use URL for the ID Generation Rules page.

### Endpoint

```
GET /api/mobile/settings/id-rules
```
### Query Parameters
Same as other endpoints (`userId`, `workspaceId`).

### Example Success Response (200 OK)

```json
{
  "success": true,
  "webviewUrl": "https://workspace.sellstory.me/settings/id-rules?token=[CUSTOM_AUTH_TOKEN]&workspaceId=WKS456PQR"
}
```
---
## Get Roles & Permissions Webview URL

This endpoint generates a secure, single-use URL for the Roles & Permissions page.

### Endpoint

```
GET /api/mobile/settings/roles
```
### Query Parameters
Same as other endpoints (`userId`, `workspaceId`).

### Example Success Response (200 OK)

```json
{
  "success": true,
  "webviewUrl": "https://workspace.sellstory.me/settings/roles?token=[CUSTOM_AUTH_TOKEN]&workspaceId=WKS456PQR"
}
```
---
## Get Approval Conditions Webview URL

This endpoint generates a secure, single-use URL for the Approval Conditions page.

### Endpoint

```
GET /api/mobile/settings/approvals
```
### Query Parameters
Same as other endpoints (`userId`, `workspaceId`).

### Example Success Response (200 OK)

```json
{
  "success": true,
  "webviewUrl": "https://workspace.sellstory.me/settings/approvals?token=[CUSTOM_AUTH_TOKEN]&workspaceId=WKS456PQR"
}
```
---
## Get Document Settings Webview URL

This endpoint generates a secure, single-use URL for the Document Settings page.

### Endpoint

```
GET /api/mobile/settings/documents
```
### Query Parameters
Same as other endpoints (`userId`, `workspaceId`).

### Example Success Response (200 OK)

```json
{
  "success": true,
  "webviewUrl": "https://workspace.sellstory.me/settings/documents?token=[CUSTOM_AUTH_TOKEN]&workspaceId=WKS456PQR"
}
```
---
## Get Catalog Settings Webview URL

This endpoint generates a secure, single-use URL for the Public Catalog Settings page.

### Endpoint

```
GET /api/mobile/settings/catalog
```
### Query Parameters
Same as other endpoints (`userId`, `workspaceId`).

### Example Success Response (200 OK)

```json
{
  "success": true,
  "webviewUrl": "https://workspace.sellstory.me/settings/catalog?token=[CUSTOM_AUTH_TOKEN]&workspaceId=WKS456PQR"
}
```
