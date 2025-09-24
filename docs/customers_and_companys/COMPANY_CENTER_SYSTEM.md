# Company Center System Documentation

This document provides a technical overview of the Company Relationship Management (CRM) system, specifically focusing on the management of corporate entities.

## 1. Data Structure

The CRM system is built around two primary Firestore collections within a workspace: **`companies`** and **`customers`**.

### A. `companies` Collection (Primary)

This collection is the master record for all corporate entities.

-   **`/workspaces/{workspaceId}/companies/{companyId}`**
    -   `name`, `branch`, `taxId`: Core company identification.
    -   `emails`, `phones`, `website`: Company contact information.
    -   `addressLine1`, `province`, etc.: Full address details.
    -   `associatedCustomerIds`: (array of strings) **Denormalized list of customer IDs** linked to this company. This allows for efficient lookups of all customers for a company.
    -   `customFields`: (array of objects) Stores data for any custom fields defined for companies in **Settings**.
    -   `hashtags`: (array of `Tag` objects) For categorization and automation.
    -   `notes`: (array of `Note` objects) A thread of comments and remarks specific to the company.

### B. `customers` Collection (Related)

This collection stores individual contacts who are linked to companies.

-   **`/workspaces/{workspaceId}/customers/{customerId}`**
    -   `name`, `prefix`, `gender`: Basic personal identification.
    -   `companyNames`: (array of `ContactInfo` objects) This is the key link back to the `companies` collection. Each object stores `{ id, value, label }` representing the company's ID, name, and the customer's role or branch there.
    -   `assignees`: (array of strings) UIDs of the salespersons responsible for this customer.

### C. Relationships with Other Collections

-   **`cards` (Job Cards)**: While jobs are primarily linked to a `customerId`, they can be associated with a company through the customer. A company's profile page would aggregate all job cards from its associated customers.
-   **`documents` (Quotations, Invoices)**: These are also linked to a `customerId` but can be billed to a company address. A company's profile provides a complete financial history by aggregating documents from all its linked customers.

## 2. System Workflow

1.  **Company Creation**:
    -   When a new company is created, a document is added to the `companies` collection.
    -   During creation or editing, users can link existing customers to the company.

2.  **Linking Customers**:
    -   When a customer is linked to a company, a two-way connection is established:
        -   The customer's ID is added to the company's `associatedCustomerIds` array.
        -   The company's ID and name are added to the customer's `companyNames` array.

3.  **Data Display**:
    -   The **Company Center** page (`/company-center`) queries the `companies` collection to display a master list.
    -   The **Company Detail** page (`/company-center/{id}`) fetches the specific company document. It then uses the `associatedCustomerIds` array to query the `customers` collection and find all linked individuals.
    -   Finally, it performs further queries on `cards` and `documents` using the list of associated customer IDs to build a complete history of all work and finances related to the company.

4.  **Data Updates & Synchronization**:
    -   When a **company's name** is updated, a backend function should iterate through all customers listed in its `associatedCustomerIds` and update the `value` (name) field in their `companyNames` array to maintain data consistency.
    -   When a customer is **unlinked** from a company, their ID should be removed from `associatedCustomerIds`, and the corresponding company entry removed from the customer's `companyNames`.

## 3. Information for Admin Panel

An administrative backend for the Company Center would provide tools for data integrity, bulk operations, and oversight.

-   **Data-Linking Dashboard**: A tool to identify and fix data integrity issues, such as:
    -   A `company` whose `associatedCustomerIds` array contains an ID of a deleted customer.
    -   A `customer` whose `companyNames` array contains an ID of a deleted company.
-   **Merge Duplicates**: A UI to select two duplicate company profiles and merge them into a single record. This process would involve:
    -   Combining their contact information and notes.
    -   Consolidating the `associatedCustomerIds` arrays.
    -   Updating all affected customer documents to point to the single, merged company ID.
-   **Bulk Operations**:
    -   **Bulk Assign:** Select multiple companies and assign a primary contact or account manager from the `users` collection.
    -   **Bulk Tagging:** Apply or remove a hashtag from a list of selected companies.
    -   **Bulk Delete/Archive:** Mass-delete or archive companies that have been inactive for a certain period.
-   **Hierarchy Management (Advanced)**: For complex B2B scenarios, an interface to establish parent-child relationships between companies (e.g., a holding company with multiple subsidiaries).
-   **Activity Log Integration**: An admin panel should allow filtering the main `activities` log to see all changes made to company profiles (e.g., `company-create`, `company-update-field`).