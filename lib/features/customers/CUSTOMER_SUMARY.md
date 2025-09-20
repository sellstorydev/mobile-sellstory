## 2025-09-20 — Customer delete action

## 2025-09-20 — Customer list after restart

- Hooked `CustomersController` to `FirebaseAuth.instance.authStateChanges()` to reliably initialize after app restarts when auth restores asynchronously.
- On user available: call `initializeWithUser(uid)` or re-`loadCustomers(workspaceId)` if list empty.
- On sign-out: cancel subscriptions and clear in-memory state.
- Added `onReady()` lifecycle with 2-second delayed check: if customers still empty but workspace/auth available, force `loadCustomers()` reload.

- Added delete icon to `customer_detail_page.dart` AppBar for users with permission (owner or `customer:delete`).
- On press: show confirm dialog (ยืนยัน/ยกเลิก). If confirmed, delete document at `/workspaces/{workspaceId}/customers/{customerId}` via `CustomersController.deleteCustomer()` and pop the page.
- No schema changes; relies on existing `CustomerRepository.deleteCustomer()` implementation.

## 2025-09-20 — Customer workspace switching fix

- Modified `switchWorkspace()` method in `CustomersController` to clear existing customer lists before loading new workspace data
- Added `customers.clear()` and `filteredCustomers.clear()` at the beginning of workspace switch to prevent showing old customer data
- This ensures clean slate when switching workspaces, solving the issue where old customer list was showing when switching to a workspace that has different or no customers

## 2025-09-21 — Debugging and cleanup

- Added extensive debug logging to track workspace switching and customer loading processes
- Removed all non-essential print statements while keeping error logging for debugging purposes
- Focus on core functionality without cluttering console output

## 2025-09-21 — Enhanced workspace switching with board info

- Enhanced `switchWorkspace()` method to immediately clear customer lists before loading new data
- Added debug prints to show current board ID and customer counts during workspace switching
- Ensures proper cleanup of old customer data and provides visibility into the switching process
- Added import for BoardController to access current board information

## 2025-09-21 — Customer list clearing fix

- Enhanced `switchWorkspace()` method to properly clear customer lists before workspace switching
- Added cancellation of existing customer subscriptions (`_customersSub`) to prevent data conflicts
- Reordered operations: clear data → cancel subscriptions → update workspace ID → load new data
- Added better debug logging to track the clearing process and final customer counts
- Fixed the issue where customer list was not properly cleared when switching workspaces

## 2025-09-21 — BoardController and CustomersController synchronization

- Added automatic notification from `BoardController.switchWorkspace()` to `CustomersController.switchWorkspace()` 
- When workspace is switched from board controller, it now automatically triggers customer data reload for the new workspace
- Added import of `CustomersController` in `BoardController` to enable cross-controller communication
- Verified backup data shows workspace `3w5mum6fnev2IEKF7G9d` (Bew1150) contains multiple customers that should be loaded
- Fixed the main issue where changing workspace in board didn't update customer list because controllers weren't synchronized


