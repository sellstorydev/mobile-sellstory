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


