# Customer Center System Documentation

This document provides a technical overview of the Customer Relationship Management (CRM) system, referred to as the Customer & Company Center. It explains the data structure, core workflows, and what an administrative backend would require.

## 1. Data Structure

The CRM system is built around two primary Firestore collections within a workspace: **`customers`** and **`companies`**.

### A. `customers` Collection

This collection stores profiles for individual contacts, who can be either leads or converted customers.

-   **`/workspaces/{workspaceId}/customers/{customerId}`**
    -   `name`, `prefix`, `gender`: Basic personal identification.
    -   `customerType`: (string) "Lead" or "Customer".
    -   `emails`, `phones`: (array of `ContactInfo` objects) Each object has `{ id, label, value }` to store multiple points of contact.
    -   `companyNames`: (array of `ContactInfo` objects) This is the key link to the `companies` collection. Each object stores `{ id, value, label }` representing the company's ID, name, and the customer's role or branch there.
    -   `assignees`: (array of strings) UIDs of the salespersons responsible for this customer.
    -   `customFields`: (array of objects) Stores data for any custom fields defined in **Settings > Company Settings**.
    -   `hashtags`: (array of `Tag` objects) For categorization and automation.
    -   `source`: (string) The lead source (e.g., "Facebook", "Website").
    -   `notes`: (array of `Note` objects) A thread of comments and remarks specific to the customer.

### B. `companies` Collection

This collection stores profiles for corporate entities.

-   **`/workspaces/{workspaceId}/companies/{companyId}`**
    -   `name`, `branch`, `taxId`: Core company identification.
    -   `emails`, `phones`, `website`: Company contact information.
    -   `addressLine1`, `province`, etc.: Full address details.
    -   `associatedCustomerIds`: (array of strings) **Denormalized list of customer IDs** linked to this company. This allows for efficient lookups of all customers for a company.

### C. Relationships with Other Collections

-   **`cards`**: Job cards link to a customer via `customerId` and `customer` (name). This allows all of a customer's jobs to be displayed on their profile page.
-   **`documents` (Quotations, Invoices, Receipts)**: These also link to a customer via `customerId` and `customer`, providing a complete financial history.

## 2. System Workflow

1.  **Customer/Company Creation**:
    -   When a new customer is created, a document is added to the `customers` collection.
    -   If a company is associated during creation, the system performs a two-way link:
        -   The company's ID and name are added to the customer's `companyNames` array.
        -   The new customer's ID is added to the company's `associatedCustomerIds` array.

2.  **Linking Existing Records**:
    -   From a company's profile page, a user can link existing customers.
    -   This action performs the same two-way link as described above, updating both the customer and company documents.

3.  **Data Display**:
    -   The **Customer Center** page (`/customer-center`) queries the `customers` and `companies` collections to display a master list.
    -   The **Customer Detail** page (`/customer-center/{id}`) fetches the specific customer document and then performs additional queries on `cards` and `documents` where `customerId` matches the current customer's ID to build a complete history.
    -   The **Company Detail** page performs a similar function, first fetching the company, then querying `customers` using the `associatedCustomerIds` array to find all linked individuals.

4.  **Data Updates**:
    -   When a **company's name** is updated, a backend function should iterate through all customers listed in its `associatedCustomerIds` and update the `value` field in their `companyNames` array to maintain consistency.
    -   When a **customer's name** is updated, a similar function should update the `customer` field on all of their associated `cards` and `documents`.

## 3. Information for Admin Panel

An administrative backend for the CRM system would provide tools for data integrity, bulk operations, and oversight.

-   **Data-Linking Dashboard**: A tool to identify and fix orphaned records, such as:
    -   A `customer` whose `companyNames` array contains an ID of a deleted company.
    -   A `company` whose `associatedCustomerIds` array contains an ID of a deleted customer.
    -   `cards` or `documents` linked to a `customerId` that no longer exists.
-   **Merge Duplicates**: A UI to select two duplicate customer or company profiles and merge them into a single record, intelligently combining their contact info, notes, and re-associating all related `cards` and `documents`.
-   **Bulk Operations**:
    -   **Bulk Assign:** Select multiple customers and assign them to a specific salesperson.
    -   **Bulk Tagging:** Apply or remove a hashtag from a list of selected customers.
    -   **Bulk Delete/Archive:** Mass-delete or archive customers who have been inactive for a certain period.
-   **Lead Source Management**: An interface to add, rename, or delete the options available in the "Customer Source" dropdown (this already exists in **Settings > Company Settings**).
-   **Custom Field Management**: The ability to define the `customerCustomFieldTemplate` stored on the workspace's `companyProfile` (this also exists in **Settings > Company Settings**).
-   **User Assignment Report**: A report showing which salespeople are assigned to which customers, and how many customers each salesperson is managing.