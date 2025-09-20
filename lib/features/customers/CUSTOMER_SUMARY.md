## 2025-09-20 — Customer delete action

## 2025-09-20 — Customer list after restart

- Hooked `CustomersController` to `FirebaseAuth.instance.authStateChanges()` to reliably initialize after app restarts when auth restores asynchronously.
- On user available: call `initializeWithUser(uid)` or re-`loadCustomers(workspaceId)` if list empty.
- On sign-out: cancel subscriptions and clear in-memory state.
- Added `onReady()` lifecycle with 2-second delayed check: if customers still empty but workspace/auth available, force `loadCustomers()` reload.

- Added delete icon to `customer_detail_page.dart` AppBar for users with permission (owner or `customer:delete`).
- On press: show confirm dialog (ยืนยัน/ยกเลิก). If confirmed, delete document at `/workspaces/{workspaceId}/customers/{customerId}` via `CustomersController.deleteCustomer()` and pop the page.
- No schema changes; relies on existing `CustomerRepository.deleteCustomer()` implementation.

