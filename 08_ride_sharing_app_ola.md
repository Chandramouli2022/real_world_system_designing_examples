# Design a Ride Sharing App like Uber / Ola

## 1. Functional Requirements

**Rider Features**

* User registration and login using phone number, email, or social login.
* Rider profile management.
* Add and manage multiple payment methods.
* Enter pickup and drop locations.
* Real-time fare estimation before booking.
* Book immediate rides.
* Schedule rides for a future time.
* View nearby available drivers.
* Track driver location in real time after booking.
* Receive ride status notifications.
* Cancel rides.
* Share trip details with friends and family.
* View ride history and invoices.
* Rate and review drivers.
* Contact driver through masked calling or in-app chat.

**Driver Features**

* Driver registration and KYC verification.
* Vehicle registration and verification.
* Go online/offline to accept rides.
* Receive ride requests.
* Accept or reject ride requests.
* Navigate to pickup location.
* Start and end trips.
* View earnings dashboard.
* View trip history.
* Receive incentives and bonuses.
* Rate riders.

**Matching and Dispatch Features**

* Find nearby drivers.
* Match rider with the most suitable driver.
* Intelligent driver assignment.
* Retry assignment if a driver rejects.
* Handle ride timeouts.
* Manage driver availability status.

**Pricing Features**

* Dynamic fare calculation.
* Surge pricing during peak demand.
* Toll and tax calculation.
* Discounts and promotional coupons.
* Wallet and reward points support.

**Payment Features**

* Online payments.
* Cash payments.
* Wallet payments.
* Automatic fare settlement.
* Driver payout processing.
* Refund management.

**Location Features**

* GPS tracking.
* Route calculation.
* ETA estimation.
* Traffic-aware routing.
* Geofencing support.

**Administrative Features**

* User management.
* Driver management.
* Vehicle management.
* Fraud detection.
* Pricing management.
* Ride monitoring.
* Customer support management.
* Analytics and reporting.

---

## 2. Non-Functional Requirements

* System should support millions of riders and drivers simultaneously.
* Ride matching latency should be less than a few seconds.
* Real-time location updates should occur every few seconds.
* High availability (99.99% uptime).
* Fault tolerance during service failures.
* Horizontal scalability across regions and cities.
* Strong security for payments and user data.
* Data encryption at rest and in transit.
* GDPR and regulatory compliance.
* Eventual consistency where immediate consistency is not required.
* Real-time notification delivery.
* Support for peak-hour traffic spikes.
* Disaster recovery and backup mechanisms.
* Monitoring, logging, and observability.
* Cost-efficient infrastructure utilization.

**Expected Scale Example**

* 100+ million registered users.
* Millions of daily rides.
* Hundreds of thousands of active drivers.
* Billions of location updates per day.
* Thousands of ride requests per second during peak hours.

---

## 3. High-Level System Design

A ride-sharing platform is essentially a **real-time distributed system** where location tracking, driver matching, trip management, and payments operate together.

The architecture is generally built using microservices because different domains such as rides, drivers, payments, and notifications scale independently.

```text
                   +------------------+
                   | Mobile Apps      |
                   | Rider / Driver   |
                   +--------+---------+
                            |
                            v
                   +------------------+
                   | API Gateway      |
                   +--------+---------+
                            |
    -------------------------------------------------
    |        |         |         |        |          |
    v        v         v         v        v          v

 User   Driver    Ride     Location  Payment  Notification
Service Service   Service   Service   Service    Service

    |        |         |         |        |          |
    -------------------------------------------------
                            |
                            v
                    Event Bus (Kafka)
                            |
          ----------------------------------
          |        |         |             |
          v        v         v             v

     Analytics  Pricing  Fraud Engine  Data Lake
```

**API Gateway**

The API Gateway acts as the single entry point for all mobile applications.

Responsibilities include:

* Authentication and authorization.
* Rate limiting.
* Request routing.
* API aggregation.
* Security filtering.

This prevents clients from directly interacting with internal services.

---

**Why Event-Driven Architecture is Important**

A ride-sharing system generates thousands of events per second.

Examples:

```text
Ride Requested

Driver Assigned

Ride Started

Ride Completed

Payment Success

Driver Online
```

Instead of tightly coupling services:

```text
Ride Service
    |
    ---> Payment Service
    ---> Analytics Service
    ---> Notification Service
    ---> Reward Service
```

we publish events to Kafka.

```text
Ride Service
      |
      v
     Kafka
      |
--------------------------------
|        |         |           |
v        v         v           v

Payment Notification Analytics Rewards
```

Benefits:

* Loose coupling.
* Independent scaling.
* Better fault isolation.
* Easier feature additions.

For example, when a ride completes:

```text
Ride Completed Event
```

Consumers can independently:

* Generate invoice.
* Process payment.
* Update analytics.
* Calculate rewards.
* Trigger notifications.

without modifying Ride Service.

---

**Databases Used**

```text
User Service        -> PostgreSQL
Driver Service      -> PostgreSQL
Ride Service        -> PostgreSQL
Location Service    -> Redis GEO
Pricing Service     -> Redis Cache
Payment Service     -> PostgreSQL
Analytics           -> Data Warehouse
```

The reason for using multiple databases is that each workload has different access patterns.

Location data requires extremely fast geo queries, while payment data requires strong consistency.

---

**High-Level Data Flow**

```text
1. Rider requests ride

2. Ride Service creates ride

3. Dispatch Service searches nearby drivers

4. Driver accepts request

5. Ride starts

6. Driver location streamed continuously

7. Ride completes

8. Ride Completed Event published

9. Payment Service charges rider

10. Notification Service sends receipt

11. Analytics Service updates reports
```

This architecture follows the same fundamental principles used by large-scale ride-sharing platforms such as Uber and Ola, where real-time location tracking, intelligent dispatching, event-driven communication, and horizontally scalable microservices enable millions of rides to be processed reliably every day.

---
# Database Schema Design for a Ride Sharing App (Uber/Ola)

For a production-grade ride-sharing system, the database should be designed around multiple business domains rather than storing everything in a few large tables. The major domains are Users, Drivers, Vehicles, Rides, Payments, Pricing, Location Tracking, Ratings, Promotions, Notifications, and Support.

In real-world systems, transactional entities are typically stored in PostgreSQL or MySQL, while high-frequency location data is stored in Redis, Cassandra, or time-series databases.

---

## Core Entity Relationships

```text
User
  |
  | 1:N
  |
Ride
  |
  | N:1
  |
Driver
  |
  | 1:N
  |
Vehicle

Ride
  |
  | 1:1
  |
Payment

Ride
  |
  | 1:N
  |
RideLocationHistory

Ride
  |
  | 1:1
  |
Rating

User
  |
  | 1:N
  |
PaymentMethod

User
  |
  | 1:N
  |
PromoUsage
```

---

## Users

Represents riders who book rides.

```sql
CREATE TABLE users (
    user_id UUID PRIMARY KEY,

    first_name VARCHAR(100),
    last_name VARCHAR(100),

    email VARCHAR(255) UNIQUE,
    phone_number VARCHAR(20) UNIQUE,

    profile_picture_url TEXT,

    status VARCHAR(30),

    created_at TIMESTAMP,
    updated_at TIMESTAMP
);
```

**Relationship**

```text
User
 ├── PaymentMethods
 ├── Rides
 ├── Ratings
 └── PromoUsages
```

---

## User Addresses

Stores frequently used rider locations.

```sql
CREATE TABLE user_addresses (
    address_id UUID PRIMARY KEY,

    user_id UUID REFERENCES users(user_id),

    label VARCHAR(50),

    address_text TEXT,

    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),

    created_at TIMESTAMP
);
```

Examples:

```text
Home
Office
Airport
Gym
```

---

## Drivers

Driver-specific information.

```sql
CREATE TABLE drivers (
    driver_id UUID PRIMARY KEY,

    first_name VARCHAR(100),
    last_name VARCHAR(100),

    email VARCHAR(255),

    phone_number VARCHAR(20),

    license_number VARCHAR(100),

    license_expiry_date DATE,

    average_rating DECIMAL(3,2),

    total_rides BIGINT DEFAULT 0,

    status VARCHAR(30),

    created_at TIMESTAMP,
    updated_at TIMESTAMP
);
```

---

## Driver Documents

Required for KYC verification.

```sql
CREATE TABLE driver_documents (
    document_id UUID PRIMARY KEY,

    driver_id UUID REFERENCES drivers(driver_id),

    document_type VARCHAR(50),

    document_url TEXT,

    verification_status VARCHAR(30),

    uploaded_at TIMESTAMP
);
```

Examples:

```text
Driving License
National ID
Vehicle Insurance
Vehicle Registration
```

---

## Vehicles

Each driver can own one or multiple vehicles.

```sql
CREATE TABLE vehicles (
    vehicle_id UUID PRIMARY KEY,

    driver_id UUID REFERENCES drivers(driver_id),

    registration_number VARCHAR(50) UNIQUE,

    vehicle_type VARCHAR(50),

    make VARCHAR(100),

    model VARCHAR(100),

    color VARCHAR(50),

    year_of_manufacture INT,

    seating_capacity INT,

    verification_status VARCHAR(30),

    created_at TIMESTAMP
);
```

---

## Driver Availability

Maintains online/offline state.

```sql
CREATE TABLE driver_availability (
    driver_id UUID PRIMARY KEY REFERENCES drivers(driver_id),

    current_status VARCHAR(30),

    last_online_at TIMESTAMP,

    updated_at TIMESTAMP
);
```

Examples:

```text
ONLINE
OFFLINE
ON_TRIP
BREAK
```

---

## Rides

Central transactional table.

```sql
CREATE TABLE rides (
    ride_id UUID PRIMARY KEY,

    rider_id UUID REFERENCES users(user_id),

    driver_id UUID REFERENCES drivers(driver_id),

    vehicle_id UUID REFERENCES vehicles(vehicle_id),

    ride_status VARCHAR(50),

    pickup_address TEXT,
    drop_address TEXT,

    pickup_latitude DECIMAL(10,7),
    pickup_longitude DECIMAL(10,7),

    drop_latitude DECIMAL(10,7),
    drop_longitude DECIMAL(10,7),

    requested_at TIMESTAMP,

    accepted_at TIMESTAMP,

    started_at TIMESTAMP,

    completed_at TIMESTAMP,

    cancelled_at TIMESTAMP
);
```

---

## Ride Status History

Maintains audit trail.

```sql
CREATE TABLE ride_status_history (
    history_id UUID PRIMARY KEY,

    ride_id UUID REFERENCES rides(ride_id),

    old_status VARCHAR(50),

    new_status VARCHAR(50),

    changed_at TIMESTAMP
);
```

Example flow:

```text
REQUESTED
→ DRIVER_ASSIGNED
→ DRIVER_ARRIVING
→ STARTED
→ COMPLETED
```

---

## Ride Location History

Stores trip path.

```sql
CREATE TABLE ride_location_history (
    location_id UUID PRIMARY KEY,

    ride_id UUID REFERENCES rides(ride_id),

    latitude DECIMAL(10,7),

    longitude DECIMAL(10,7),

    captured_at TIMESTAMP
);
```

In large systems this table usually moves to Cassandra or a time-series database because billions of location points are generated daily.

---

## Driver Assignment Attempts

Tracks dispatch retries.

```sql
CREATE TABLE driver_assignment_attempts (
    attempt_id UUID PRIMARY KEY,

    ride_id UUID REFERENCES rides(ride_id),

    driver_id UUID REFERENCES drivers(driver_id),

    assignment_status VARCHAR(30),

    attempted_at TIMESTAMP
);
```

Example:

```text
Driver A -> Rejected

Driver B -> Timed Out

Driver C -> Accepted
```

Useful for analytics and optimization.

---

## Fare Details

Stores fare breakdown.

```sql
CREATE TABLE fare_details (
    fare_id UUID PRIMARY KEY,

    ride_id UUID UNIQUE REFERENCES rides(ride_id),

    base_fare DECIMAL(10,2),

    distance_fare DECIMAL(10,2),

    duration_fare DECIMAL(10,2),

    surge_amount DECIMAL(10,2),

    toll_amount DECIMAL(10,2),

    tax_amount DECIMAL(10,2),

    discount_amount DECIMAL(10,2),

    final_fare DECIMAL(10,2)
);
```

---

## Payments

Financial transactions.

```sql
CREATE TABLE payments (
    payment_id UUID PRIMARY KEY,

    ride_id UUID UNIQUE REFERENCES rides(ride_id),

    rider_id UUID REFERENCES users(user_id),

    payment_method_id UUID,

    amount DECIMAL(10,2),

    currency VARCHAR(10),

    payment_status VARCHAR(30),

    gateway_transaction_id VARCHAR(255),

    paid_at TIMESTAMP
);
```

---

## Payment Methods

Stored payment options.

```sql
CREATE TABLE payment_methods (
    payment_method_id UUID PRIMARY KEY,

    user_id UUID REFERENCES users(user_id),

    payment_type VARCHAR(30),

    provider VARCHAR(50),

    token_reference VARCHAR(255),

    created_at TIMESTAMP
);
```

Examples:

```text
UPI
Credit Card
Wallet
Net Banking
```

---

## Driver Earnings

Tracks payouts.

```sql
CREATE TABLE driver_earnings (
    earning_id UUID PRIMARY KEY,

    driver_id UUID REFERENCES drivers(driver_id),

    ride_id UUID REFERENCES rides(ride_id),

    gross_amount DECIMAL(10,2),

    commission_amount DECIMAL(10,2),

    net_amount DECIMAL(10,2),

    payout_status VARCHAR(30),

    created_at TIMESTAMP
);
```

---

## Ratings & Reviews

Both rider and driver feedback.

```sql
CREATE TABLE ratings (
    rating_id UUID PRIMARY KEY,

    ride_id UUID REFERENCES rides(ride_id),

    reviewer_type VARCHAR(20),

    reviewer_id UUID,

    reviewee_id UUID,

    rating INT,

    comments TEXT,

    created_at TIMESTAMP
);
```

Examples:

```text
Driver rates Rider

Rider rates Driver
```

---

## Coupons

Promotion management.

```sql
CREATE TABLE coupons (
    coupon_id UUID PRIMARY KEY,

    coupon_code VARCHAR(50) UNIQUE,

    discount_type VARCHAR(30),

    discount_value DECIMAL(10,2),

    max_discount DECIMAL(10,2),

    valid_from TIMESTAMP,

    valid_until TIMESTAMP,

    usage_limit INT
);
```

---

## Coupon Usage

Tracks redemption.

```sql
CREATE TABLE coupon_usage (
    usage_id UUID PRIMARY KEY,

    coupon_id UUID REFERENCES coupons(coupon_id),

    user_id UUID REFERENCES users(user_id),

    ride_id UUID REFERENCES rides(ride_id),

    used_at TIMESTAMP
);
```

---

## Notifications

Stores notification history.

```sql
CREATE TABLE notifications (
    notification_id UUID PRIMARY KEY,

    user_type VARCHAR(20),

    user_id UUID,

    notification_type VARCHAR(50),

    title VARCHAR(255),

    message TEXT,

    delivery_status VARCHAR(30),

    created_at TIMESTAMP
);
```

---

## Support Tickets

Customer support management.

```sql
CREATE TABLE support_tickets (
    ticket_id UUID PRIMARY KEY,

    ride_id UUID REFERENCES rides(ride_id),

    user_id UUID REFERENCES users(user_id),

    issue_type VARCHAR(100),

    description TEXT,

    status VARCHAR(30),

    created_at TIMESTAMP,

    resolved_at TIMESTAMP
);
```

---

## Surge Pricing Zones

Used by the pricing engine.

```sql
CREATE TABLE surge_zones (
    zone_id UUID PRIMARY KEY,

    zone_name VARCHAR(100),

    city VARCHAR(100),

    surge_multiplier DECIMAL(5,2),

    updated_at TIMESTAMP
);
```

Example:

```text
Airport Area = 2.0x

City Center = 1.5x

Railway Station = 1.8x
```

---

## Real-Time Location Storage (Redis)

Current driver locations should not be stored in PostgreSQL because location updates arrive every few seconds.

Instead:

```text
Redis GEO

Key:
driver_location

Value:
DriverID -> (latitude, longitude)
```

Example:

```text
Driver_101 -> (19.0760,72.8777)

Driver_102 -> (19.0810,72.8820)
```

This allows:

```text
Find nearest drivers

Find drivers within 3 km

Calculate ETA
```

in milliseconds.

---

This schema covers roughly **90–95% of the entities found in a production ride-sharing platform**, including rider management, driver onboarding, ride lifecycle, dispatching, geolocation tracking, payments, earnings, promotions, ratings, notifications, support, and surge pricing while remaining scalable enough to evolve into a large-scale Uber/Ola-style architecture.

---

# ERD

[Database Entities and Relationships](./images/erd_ride_app.png)