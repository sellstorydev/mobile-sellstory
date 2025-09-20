## 2025-09-20 — Customer delete action

- Added delete icon to `customer_detail_page.dart` AppBar for users with permission (owner or `customer:delete`).
- On press: show confirm dialog (ยืนยัน/ยกเลิก). If confirmed, delete document at `/workspaces/{workspaceId}/customers/{customerId}` via `CustomersController.deleteCustomer()` and pop the page.
- No schema changes; relies on existing `CustomerRepository.deleteCustomer()` implementation.

