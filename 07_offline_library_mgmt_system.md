# Design an Offline Library Management System

## 1. Functional Requirements

* Librarian should be able to add, update, delete, and view books.
* System should maintain multiple copies of the same book.
* Members should be able to register and maintain their profiles.
* Librarian should be able to search books by:

  * Title
  * Author
  * ISBN
  * Category
* Librarian should be able to issue books to members.
* Librarian should be able to accept returned books.
* System should track due dates and overdue books.
* System should calculate fines for late returns.
* Members should be able to reserve books when all copies are unavailable.
* System should maintain inventory status such as:

  * Available
  * Issued
  * Reserved
  * Lost
  * Damaged
* System should generate reports such as:

  * Issued books
  * Overdue books
  * Fine collection
  * Active members
* System should support authentication and role-based access control for Admin, Librarian, and Members.

---

## 2. Non-Functional Requirements

* The system should work completely offline without internet dependency.
* Search and issue operations should be fast and responsive.
* The system should support thousands of books and members.
* Data should be stored reliably without loss.
* Database transactions should ensure consistency during issue and return operations.
* The system should provide role-based security.
* The application should be easy to maintain and extend.
* Audit logs should be maintained for important actions.
* Regular backup and recovery mechanisms should be supported.

---

## 3. High-Level System Design

For an offline library management system, a **Layered Monolithic Architecture** is the most suitable choice.

Since all operations happen within a single library and there is no need for distributed services, microservices would introduce unnecessary complexity. A modular monolith is simpler to develop, deploy, and maintain.

**Architecture**

```text
+--------------------------------+
|          UI Layer              |
| (Desktop App / Web Interface)  |
+--------------------------------+
               |
               v
+--------------------------------+
|      Application Layer         |
|--------------------------------|
| Book Service                   |
| Member Service                 |
| Issue Service                  |
| Return Service                 |
| Fine Service                   |
| Report Service                 |
+--------------------------------+
               |
               v
+--------------------------------+
|     Repository / DAO Layer     |
+--------------------------------+
               |
               v
+--------------------------------+
|        PostgreSQL DB           |
+--------------------------------+
```

**UI Layer**

Provides screens for librarians and administrators to manage books, members, issuing, returns, and reports.

**Application Layer**

Contains all business logic.

* Book Service manages books and inventory.
* Member Service manages library members.
* Issue Service handles book borrowing.
* Return Service processes book returns.
* Fine Service calculates penalties.
* Report Service generates reports.

**Repository Layer**

Acts as an abstraction between business logic and database queries. It handles CRUD operations and database interactions.

**Database Layer**

A relational database such as PostgreSQL stores:

* Books
* Book Copies
* Members
* Transactions
* Reservations
* Fines

A relational database is preferred because library operations involve strong relationships and transactions, such as issuing and returning books.

**Why This Architecture?**

* Simple to develop and maintain.
* Suitable for offline deployment.
* Strong transactional consistency.
* Easy to scale vertically as the library grows.
* Follows a standard enterprise architecture commonly used in management systems.

---

# Database Schema Design for Offline Library Management System

The database should be designed in a normalized manner to avoid data duplication while maintaining strong relationships between books, members, transactions, reservations, and fines.

Since a Library Management System is highly transactional and relational in nature, a **Relational Database (PostgreSQL/MySQL)** is the preferred choice.

## Core Entities

The major entities are:

```text
Library
│
├── Librarian
├── Member
├── Book
│     ├── Author
│     ├── Publisher
│     ├── Category
│     └── Book Copy
│
├── Borrow Transaction
├── Reservation
├── Fine
├── Payment
└── Audit Log
```

---

## Library

Represents the physical library.

```sql
CREATE TABLE libraries (
    library_id UUID PRIMARY KEY,
    name VARCHAR(255),
    address TEXT,
    phone VARCHAR(20),
    created_at TIMESTAMP
);
```

**Relationship**

```text
Library (1) -----> (N) Librarians
Library (1) -----> (N) Members
Library (1) -----> (N) Books
```

---

## Librarians

Stores librarian/admin information.

```sql
CREATE TABLE librarians (
    librarian_id UUID PRIMARY KEY,
    library_id UUID REFERENCES libraries(library_id),

    first_name VARCHAR(100),
    last_name VARCHAR(100),

    email VARCHAR(255) UNIQUE,
    phone VARCHAR(20),

    role VARCHAR(50),

    password_hash TEXT,

    created_at TIMESTAMP
);
```

---

## Members

Stores library users.

```sql
CREATE TABLE members (
    member_id UUID PRIMARY KEY,
    library_id UUID REFERENCES libraries(library_id),

    first_name VARCHAR(100),
    last_name VARCHAR(100),

    email VARCHAR(255) UNIQUE,
    phone VARCHAR(20),

    address TEXT,

    membership_type VARCHAR(50),

    max_books_allowed INT,

    joined_at TIMESTAMP,
    expiry_date TIMESTAMP,

    status VARCHAR(50)
);
```

**Relationship**

```text
Member (1) -----> (N) Borrow Transactions
Member (1) -----> (N) Reservations
Member (1) -----> (N) Fines
```

---

## Authors

A book may have multiple authors.

```sql
CREATE TABLE authors (
    author_id UUID PRIMARY KEY,

    first_name VARCHAR(100),
    last_name VARCHAR(100),

    biography TEXT
);
```

---

## Publishers

```sql
CREATE TABLE publishers (
    publisher_id UUID PRIMARY KEY,

    publisher_name VARCHAR(255),

    email VARCHAR(255),
    phone VARCHAR(20)
);
```

---

## Categories

```sql
CREATE TABLE categories (
    category_id UUID PRIMARY KEY,

    category_name VARCHAR(100),

    description TEXT
);
```

Examples:

* Science
* Programming
* Fiction
* History

---

## Books

Stores book metadata.

One row represents one book title.

```sql
CREATE TABLE books (
    book_id UUID PRIMARY KEY,

    isbn VARCHAR(30) UNIQUE,

    title VARCHAR(255),

    publisher_id UUID REFERENCES publishers(publisher_id),

    category_id UUID REFERENCES categories(category_id),

    edition VARCHAR(50),

    publication_year INT,

    language VARCHAR(50),

    description TEXT,

    created_at TIMESTAMP
);
```

**Why separate Book and Book Copy?**

A library may own multiple physical copies of the same book.

Example:

```text
Book:
Introduction to Algorithms

Copies:
Copy-1
Copy-2
Copy-3
```

The metadata should not be duplicated.

---

## Book Authors (Many-to-Many)

One book can have multiple authors.

One author can write multiple books.

```sql
CREATE TABLE book_authors (
    book_id UUID REFERENCES books(book_id),

    author_id UUID REFERENCES authors(author_id),

    PRIMARY KEY(book_id, author_id)
);
```

Relationship:

```text
Books (N) <----> (N) Authors
```

---

## Book Copies

Represents physical copies.

```sql
CREATE TABLE book_copies (
    copy_id UUID PRIMARY KEY,

    book_id UUID REFERENCES books(book_id),

    barcode VARCHAR(100) UNIQUE,

    shelf_location VARCHAR(100),

    acquisition_date DATE,

    status VARCHAR(50),

    created_at TIMESTAMP
);
```

Status values:

```text
AVAILABLE
ISSUED
RESERVED
LOST
DAMAGED
```

Relationship:

```text
Book (1) -----> (N) Book Copies
```

---

## Borrow Transactions

Tracks issuance and return.

```sql
CREATE TABLE borrow_transactions (
    transaction_id UUID PRIMARY KEY,

    member_id UUID REFERENCES members(member_id),

    copy_id UUID REFERENCES book_copies(copy_id),

    issued_by UUID REFERENCES librarians(librarian_id),

    issue_date DATE,

    due_date DATE,

    return_date DATE,

    status VARCHAR(50)
);
```

Status:

```text
ACTIVE
RETURNED
OVERDUE
```

Relationship:

```text
Member (1) -----> (N) Borrow Transactions

Book Copy (1) -----> (N) Borrow Transactions
```

---

## Reservations

Stores waiting queue requests.

```sql
CREATE TABLE reservations (
    reservation_id UUID PRIMARY KEY,

    member_id UUID REFERENCES members(member_id),

    book_id UUID REFERENCES books(book_id),

    reservation_date TIMESTAMP,

    queue_position INT,

    status VARCHAR(50)
);
```

Status:

```text
PENDING
FULFILLED
CANCELLED
EXPIRED
```

Relationship:

```text
Member (1) -----> (N) Reservations

Book (1) -----> (N) Reservations
```

---

## Fines

Stores penalties.

```sql
CREATE TABLE fines (
    fine_id UUID PRIMARY KEY,

    transaction_id UUID
        REFERENCES borrow_transactions(transaction_id),

    member_id UUID
        REFERENCES members(member_id),

    amount DECIMAL(10,2),

    reason VARCHAR(255),

    status VARCHAR(50),

    created_at TIMESTAMP
);
```

Status:

```text
PENDING
PAID
WAIVED
```

Relationship:

```text
Borrow Transaction (1) -----> (0..1) Fine
```

---

## Fine Payments

Tracks payment history.

```sql
CREATE TABLE fine_payments (
    payment_id UUID PRIMARY KEY,

    fine_id UUID REFERENCES fines(fine_id),

    amount DECIMAL(10,2),

    payment_date TIMESTAMP,

    payment_method VARCHAR(50)
);
```

Payment methods:

```text
CASH
CARD
UPI
```

---

## Audit Logs

Stores important activities.

```sql
CREATE TABLE audit_logs (
    audit_id UUID PRIMARY KEY,

    user_id UUID,

    action VARCHAR(255),

    entity_type VARCHAR(100),

    entity_id UUID,

    created_at TIMESTAMP
);
```

Examples:

```text
BOOK_CREATED

BOOK_ISSUED

BOOK_RETURNED

MEMBER_CREATED

FINE_PAID
```

---

## Important Relationships

[Database Entities and Relationships](./images/erd_library_mgmt_system.png)

## Database Choice

**PostgreSQL** is the preferred database because:

* Strong ACID transaction support.
* Foreign key constraints ensure data integrity.
* Excellent indexing support for book search.
* Supports millions of transactions efficiently.
* Well-suited for highly relational systems like libraries.

This schema covers almost all major entities required in a production-grade offline Library Management System and is sufficient for most system design interviews.

---

# API Design for Core Functionalities

For a Library Management System interview, you generally do not need to expose every CRUD API. Focus on the **most frequently used business operations** that drive the system.

## 1. Search Books

This is one of the most heavily used APIs because librarians and members constantly search for books.

**Endpoint**

```http
GET /api/v1/books
```

**Query Parameters**

```http
GET /api/v1/books?title=algorithms
GET /api/v1/books?author=robert
GET /api/v1/books?isbn=9780262033848
```

**Response**

```json id="x31m4i"
{
  "books": [
    {
      "bookId": "B101",
      "title": "Introduction to Algorithms",
      "isbn": "9780262033848",
      "availableCopies": 3
    }
  ]
}
```

**Why Important?**

This is a read-heavy endpoint and should be optimized using indexes on:

* ISBN
* Title
* Author

---

## 2. Register Member

Used whenever a new member joins the library.

**Endpoint**

```http
POST /api/v1/members
```

**Request**

```json id="6fwl3s"
{
  "firstName": "John",
  "lastName": "Doe",
  "email": "john@gmail.com",
  "membershipType": "STUDENT"
}
```

**Response**

```json id="rpb7kn"
{
  "memberId": "MEM001",
  "status": "ACTIVE"
}
```

**Why Important?**

Creates a member profile that will be referenced by all future borrowing transactions.

---

## 3. Issue Book

One of the most critical transactional APIs.

**Endpoint**

```http
POST /api/v1/books/issue
```

**Request**

```json id="qrrg9u"
{
  "memberId": "MEM001",
  "copyId": "COPY1001",
  "issuedBy": "LIB001"
}
```

**Response**

```json id="xhv64v"
{
  "transactionId": "TXN101",
  "issueDate": "2026-06-07",
  "dueDate": "2026-06-21",
  "status": "ISSUED"
}
```

**Business Validation**

Before issuing:

* Verify member exists.
* Verify membership is active.
* Verify borrowing limit is not exceeded.
* Verify copy is available.

This operation should execute inside a database transaction.

**sequence of actions**:

1. Validate Member

2. Check Borrowing Limit

3. Lock Book Copy

4. Check Status

5. If Status = RESERVED
      Verify reserved_for_member_id
      matches requesting member

6. Create Borrow Transaction

7. Update Copy Status = ISSUED

8. Remove Reservation Record
   (if reservation existed)

9. Create Audit Log

10. Commit

---

## 4. Return Book

Another high-frequency operation.

**Endpoint**

```http
POST /api/v1/books/return
```

**Request**

```json id="j6v1xt"
{
  "transactionId": "TXN101"
}
```

**Response**

```json id="2ndivv"
{
  "transactionId": "TXN101",
  "returnedOn": "2026-06-25",
  "overdueDays": 4,
  "fineAmount": 40
}
```

**Business Logic**

* Update copy status to AVAILABLE.
* Calculate overdue days.
* Generate fine if applicable.
* Close borrowing transaction.

**sequence of actions**:

1. Return Book

2. Calculate Fine

3. Check Reservation Queue

4. If Queue Exists

      Get Queue Head

      Update Copy Status = RESERVED

      Set reserved_for_member_id

      Set Reservation Status = READY

5. Else

      Update Copy Status = AVAILABLE

6. Commit

---

## 5. Reserve Book

Used when all copies are currently unavailable.

**Endpoint**

```http
POST /api/v1/reservations
```

**Request**

```json id="r5zz83"
{
  "memberId": "MEM001",
  "bookId": "BOOK101"
}
```

**Response**

```json id="jzv2j6"
{
  "reservationId": "RES001",
  "queuePosition": 2,
  "status": "PENDING"
}
```

**Why Important?**

Prevents users from repeatedly checking availability and ensures fair allocation.

---

## 6. Get Overdue Books Report

Frequently accessed by librarians.

**Endpoint**

```http
GET /api/v1/reports/overdue-books
```

**Response**

```json id="jdr89w"
{
  "count": 2,
  "books": [
    {
      "memberId": "MEM001",
      "bookTitle": "Operating Systems",
      "dueDate": "2026-06-01",
      "daysOverdue": 6
    }
  ]
}
```

**Why Important?**

Helps librarians identify overdue books and collect fines.

---

## API Summary

| API                             | Method | Purpose            |
| ------------------------------- | ------ | ------------------ |
| `/api/v1/books`                 | GET    | Search books       |
| `/api/v1/members`               | POST   | Register member    |
| `/api/v1/books/issue`           | POST   | Issue a book       |
| `/api/v1/books/return`          | POST   | Return a book      |
| `/api/v1/reservations`          | POST   | Reserve a book     |
| `/api/v1/reports/overdue-books` | GET    | View overdue books |

These 6 APIs cover almost **80-90% of the daily operations** in a typical library and are usually sufficient for the API Design section of a system design interview.

---