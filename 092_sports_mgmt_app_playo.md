# Design a Sports Management App like Playo / Hudle

## 1. Functional Requirements

### User Management

* Users should be able to register using email, mobile number, Google login, or social authentication.
* Users should be able to manage their profile including name, age, gender, sports interests, skill level, location, and achievements.
* Users should be able to verify their identity and contact information.
* Users should be able to maintain player ratings and sports history.

### Sports Venue Discovery

* Users should be able to search nearby sports venues.
* Users should be able to filter venues based on sport type, location, price, ratings, amenities, and availability.
* Users should be able to view venue details including images, facilities, pricing, and reviews.
* Users should be able to navigate to venue locations using map integrations.

### Venue Booking

* Users should be able to view available courts, grounds, and time slots.
* Users should be able to reserve sports facilities for a specific duration.
* Users should be able to modify or cancel bookings according to venue policies.
* Users should receive booking confirmations and reminders.

### Match and Game Creation

* Users should be able to create public or private games.
* Organizers should be able to specify sport type, date, time, venue, skill level, and player requirements.
* Users should be able to join existing games.
* Organizers should be able to approve or reject participants.

### Team Management

* Users should be able to create teams.
* Team owners should be able to invite players.
* Teams should be able to maintain rosters and player statistics.
* Teams should be able to participate in tournaments and leagues.

### Tournament Management

* Organizers should be able to create tournaments.
* Tournament organizers should be able to define formats such as knockout, league, or round-robin.
* Teams or individual players should be able to register.
* The system should generate fixtures and schedules.
* Tournament standings and rankings should be automatically maintained.

### Payments and Refunds

* Users should be able to pay for venue bookings.
* Tournament registration fees should be supported.
* Multiple payment methods should be available.
* Refund workflows should be supported based on cancellation policies.

### Social and Community Features

* Users should be able to follow players and teams.
* Users should be able to post updates, photos, and achievements.
* Users should be able to like, comment, and share activities.
* Sports communities and discussion groups should be supported.

### Ratings and Reviews

* Players should be able to rate venues.
* Players should be able to rate fellow participants after matches.
* Venue owners should be able to respond to reviews.
* Reputation scores should be maintained.

### Notifications

* Booking confirmations.
* Match reminders.
* Tournament updates.
* Payment notifications.
* Team invitations.
* Real-time game updates.

### Admin Features

* Manage users.
* Manage venues.
* Moderate content.
* Handle disputes and refunds.
* Monitor platform activity.
* Generate reports and analytics.

---

## 2. Non-Functional Requirements

### Scalability

* The system should support millions of registered users.
* The platform should handle thousands of concurrent venue bookings.
* The architecture should scale horizontally during tournament seasons and weekends when traffic spikes significantly.

### High Availability

* Sports bookings are time-sensitive and revenue-generating.
* The platform should target 99.9%+ availability.
* Failure of a single service should not impact the entire platform.

### Low Latency

* Venue searches should return results within a few hundred milliseconds.
* Availability checks should be near real-time.
* Match joining and booking operations should feel instantaneous.

### Consistency

* Booking systems require strong consistency.
* Double booking of a sports court or ground must never occur.
* Payment and booking records must remain synchronized.

### Reliability

* Booking requests must never be lost.
* Notifications should be delivered reliably.
* Payment transactions should be idempotent.

### Security

* Secure authentication and authorization.
* Encryption of sensitive user information.
* Secure payment processing.
* Protection against fraud and abuse.

### Observability

* Centralized logging.
* Distributed tracing.
* Real-time monitoring dashboards.
* Automated alerting for failures.

### Maintainability

* Services should be independently deployable.
* Clear service boundaries should exist.
* CI/CD pipelines should support frequent releases.

### Extensibility

* New sports should be added without major redesign.
* New tournament formats should be configurable.
* Third-party integrations should be easy to introduce.

---

## 3. High-Level System Design

A production-scale Playo/Hudle-like platform is typically built using a microservices architecture because multiple business domains evolve independently. Venue booking, tournaments, social networking, payments, and notifications all have different scaling characteristics.

```text
                     Users
                       │
                Mobile/Web Apps
                       │
                 API Gateway
                       │
 ┌──────────────────────────────────────┐
 │                                      │
 │      Authentication Service          │
 │      User Profile Service            │
 │      Venue Service                   │
 │      Booking Service                 │
 │      Match Management Service        │
 │      Team Service                    │
 │      Tournament Service              │
 │      Payment Service                 │
 │      Review & Rating Service         │
 │      Social Feed Service             │
 │      Notification Service            │
 │      Admin Service                   │
 │                                      │
 └──────────────────────────────────────┘
                       │
        ┌──────────────┴──────────────┐
        │                             │
   Event Bus / Queue            Cache Layer
        │                             │
        └──────────────┬──────────────┘
                       │
               Data Storage Layer
```

**Client Applications**

Mobile applications and web applications serve as the primary user interface. Most traffic originates from mobile devices because users typically book venues and join matches on the go.

**API Gateway**

The API Gateway acts as the single entry point for all client requests. It handles authentication validation, request routing, throttling, rate limiting, and API aggregation.

This prevents clients from directly communicating with dozens of backend services.

**Authentication Service**

Responsible for login, registration, token generation, user verification, and session management.

This service is usually isolated because authentication requirements differ from normal business operations and require stricter security controls.

**User Profile Service**

Stores player information, sports interests, rankings, skill levels, and participation history.

Separating profiles from authentication improves security and scalability.

**Venue Service**

Manages sports facilities, courts, grounds, schedules, pricing, images, and amenities.

Venue information changes relatively infrequently, making it highly cacheable.

**Booking Service**

One of the most critical services.

Responsibilities include:

* Slot reservation
* Availability checks
* Booking confirmation
* Cancellation handling

This service must ensure strong consistency because multiple users may attempt to reserve the same court simultaneously.

**Match Management Service**

Responsible for creating games, finding players, managing participants, and tracking match outcomes.

This service drives community engagement and repeat platform usage.

**Team Service**

Handles team creation, memberships, invitations, player rosters, and team statistics.

Separating team operations from match management simplifies ownership boundaries.

**Tournament Service**

Manages tournament creation, registration, fixture generation, standings, leaderboards, and rankings.

Tournament traffic often spikes during active events, making independent scaling important.

**Payment Service**

Responsible for:

* Payment initiation
* Payment verification
* Refunds
* Wallet management

This service integrates with external payment gateways and maintains transactional integrity.

**Review and Rating Service**

Manages venue reviews, player ratings, and reputation scores.

Separating this service prevents review-related traffic from affecting booking operations.

**Social Feed Service**

Supports:

* Activity feeds
* Posts
* Likes
* Comments
* Followers

Social traffic is read-heavy and scales differently from transactional services.

**Notification Service**

Handles:

* Push notifications
* SMS
* Emails
* WhatsApp notifications

Notification delivery is asynchronous because users do not need immediate responses from these external channels.

---

**Event Bus / Message Queue**

Large-scale sports platforms heavily utilize event-driven architecture.

Whenever an important action occurs:

```text
Booking Created
      │
      ▼
 Publish Event
      │
      ▼
 Message Queue
      │
 ┌────┼─────┬─────┐
 ▼    ▼     ▼     ▼
Payment Notification Analytics Match Service
```

For example:

```text
User Books Court
      │
      ▼
Booking Service
      │
      ▼
BookingConfirmed Event
      │
      ▼
Message Broker
      │
 ┌────┼──────────────┬──────────┐
 ▼    ▼              ▼          ▼
Payment  Notification Analytics Recommendation
```

This architecture reduces service coupling.

Without events:

```text
Booking Service
    │
    ├── Call Payment
    ├── Call Notification
    ├── Call Analytics
    ├── Call Recommendation
    └── Call Audit
```

The booking service becomes tightly coupled and difficult to scale.

With event-driven architecture, consumers subscribe independently and process events asynchronously.

Benefits:

* Better scalability
* Improved fault isolation
* Independent service evolution
* Higher throughput

---

**Cache Layer**

Caching is heavily used for:

* Venue search results
* Popular tournaments
* Leaderboards
* User profiles
* Frequently accessed schedules

This significantly reduces backend load and improves response times.

---

**Data Storage Layer**

Although each service typically owns its own database, at a high level the storage layer persists:

* Users
* Venues
* Bookings
* Teams
* Matches
* Tournaments
* Payments
* Reviews
* Social content

This follows the database-per-service pattern commonly used in large-scale microservice architectures.

---

**Why This Architecture Works**

A sports management platform contains both transactional workloads (bookings, payments) and social workloads (feeds, comments, followers).

By separating these domains into independent services and connecting them through asynchronous events, the platform can:

* Scale individual components independently.
* Prevent failures from cascading across the system.
* Handle large traffic spikes during tournaments.
* Support future business features without major redesign.
* Maintain strong consistency for bookings while allowing eventual consistency for social and notification features.

This is the architecture commonly seen in production-grade sports booking and community platforms operating at large scale.

---
# Database Schema Design for Sports Management App (Playo / Hudle)

The system has three major business domains:

1. **Sports Booking Domain** (Venue Discovery and Booking)
2. **Sports Community Domain** (Players, Teams, Social Features)
3. **Tournament Domain** (Competitions, Fixtures, Rankings)

A good interview answer should separate transactional entities from social entities because they have different scaling patterns.

---

## Core Entity Relationship Overview

```text
User
 │
 ├── UserProfile
 │
 ├── UserSports
 │
 ├── TeamMembers
 │        │
 │        ▼
 │      Teams
 │
 ├── Bookings
 │        │
 │        ▼
 │      Slots
 │        │
 │        ▼
 │      Courts
 │        │
 │        ▼
 │      Venues
 │
 ├── MatchParticipants
 │        │
 │        ▼
 │      Matches
 │
 ├── TournamentRegistrations
 │        │
 │        ▼
 │     Tournaments
 │
 ├── Reviews
 │
 ├── Payments
 │
 └── Notifications
```

---

## User Management

### Users

Stores authentication-related information.

```sql
CREATE TABLE users (
    user_id UUID PRIMARY KEY,

    email VARCHAR(255) UNIQUE,

    phone VARCHAR(20) UNIQUE,

    password_hash VARCHAR(500),

    auth_provider VARCHAR(50),

    is_verified BOOLEAN,

    account_status VARCHAR(50),

    created_at TIMESTAMP,

    updated_at TIMESTAMP
);
```

---

### User Profiles

Stores player-specific information.

```sql
CREATE TABLE user_profiles (
    profile_id UUID PRIMARY KEY,

    user_id UUID UNIQUE REFERENCES users(user_id),

    first_name VARCHAR(100),

    last_name VARCHAR(100),

    gender VARCHAR(20),

    date_of_birth DATE,

    profile_image_url TEXT,

    city VARCHAR(100),

    state VARCHAR(100),

    bio TEXT,

    skill_level VARCHAR(50),

    rating DECIMAL(3,2),

    created_at TIMESTAMP
);
```

---

### Sports Master

Supported sports.

```sql
CREATE TABLE sports (
    sport_id UUID PRIMARY KEY,

    sport_name VARCHAR(100),

    description TEXT
);
```

Examples:

* Cricket
* Football
* Tennis
* Badminton
* Basketball

---

### User Sports

Many-to-many relationship.

```sql
CREATE TABLE user_sports (
    user_sport_id UUID PRIMARY KEY,

    user_id UUID REFERENCES users(user_id),

    sport_id UUID REFERENCES sports(sport_id),

    skill_level VARCHAR(50),

    rating DECIMAL(3,2)
);
```

---

# Venue Management

## Venues

Sports complexes.

```sql
CREATE TABLE venues (
    venue_id UUID PRIMARY KEY,

    owner_id UUID REFERENCES users(user_id),

    venue_name VARCHAR(255),

    description TEXT,

    phone VARCHAR(20),

    email VARCHAR(255),

    rating DECIMAL(3,2),

    status VARCHAR(50),

    created_at TIMESTAMP
);
```

---

## Venue Addresses

```sql
CREATE TABLE venue_addresses (
    address_id UUID PRIMARY KEY,

    venue_id UUID REFERENCES venues(venue_id),

    address_line1 TEXT,

    city VARCHAR(100),

    state VARCHAR(100),

    country VARCHAR(100),

    postal_code VARCHAR(20),

    latitude DECIMAL(10,7),

    longitude DECIMAL(10,7)
);
```

---

## Courts / Grounds

A venue may contain multiple playable areas.

```sql
CREATE TABLE courts (
    court_id UUID PRIMARY KEY,

    venue_id UUID REFERENCES venues(venue_id),

    sport_id UUID REFERENCES sports(sport_id),

    court_name VARCHAR(255),

    capacity INTEGER,

    surface_type VARCHAR(100),

    status VARCHAR(50)
);
```

Examples:

* Court-1
* Badminton Court-A
* Football Turf

---

## Court Slots

Bookable time slots.

```sql
CREATE TABLE court_slots (
    slot_id UUID PRIMARY KEY,

    court_id UUID REFERENCES courts(court_id),

    start_time TIMESTAMP,

    end_time TIMESTAMP,

    slot_price DECIMAL(12,2),

    slot_status VARCHAR(50)
);
```

---

# Booking Management

## Bookings

Most critical transactional table.

```sql
CREATE TABLE bookings (
    booking_id UUID PRIMARY KEY,

    user_id UUID REFERENCES users(user_id),

    slot_id UUID REFERENCES court_slots(slot_id),

    booking_status VARCHAR(50),

    booking_amount DECIMAL(12,2),

    created_at TIMESTAMP
);
```

---

## Booking Participants

Supports group bookings.

```sql
CREATE TABLE booking_participants (
    booking_participant_id UUID PRIMARY KEY,

    booking_id UUID REFERENCES bookings(booking_id),

    user_id UUID REFERENCES users(user_id)
);
```

---

# Match Management

## Matches

Created by players.

```sql
CREATE TABLE matches (
    match_id UUID PRIMARY KEY,

    organizer_id UUID REFERENCES users(user_id),

    sport_id UUID REFERENCES sports(sport_id),

    venue_id UUID REFERENCES venues(venue_id),

    booking_id UUID REFERENCES bookings(booking_id),

    match_title VARCHAR(255),

    skill_level VARCHAR(50),

    max_players INTEGER,

    visibility VARCHAR(50),

    match_status VARCHAR(50),

    scheduled_at TIMESTAMP
);
```

---

## Match Participants

```sql
CREATE TABLE match_participants (
    participant_id UUID PRIMARY KEY,

    match_id UUID REFERENCES matches(match_id),

    user_id UUID REFERENCES users(user_id),

    join_status VARCHAR(50),

    joined_at TIMESTAMP
);
```

---

# Team Management

## Teams

```sql
CREATE TABLE teams (
    team_id UUID PRIMARY KEY,

    owner_id UUID REFERENCES users(user_id),

    sport_id UUID REFERENCES sports(sport_id),

    team_name VARCHAR(255),

    team_logo TEXT,

    team_rating DECIMAL(3,2),

    created_at TIMESTAMP
);
```

---

## Team Members

Many-to-many relationship.

```sql
CREATE TABLE team_members (
    member_id UUID PRIMARY KEY,

    team_id UUID REFERENCES teams(team_id),

    user_id UUID REFERENCES users(user_id),

    role VARCHAR(50),

    joined_at TIMESTAMP
);
```

Roles:

* Captain
* Vice Captain
* Player
* Coach

---

# Tournament Management

## Tournaments

```sql
CREATE TABLE tournaments (
    tournament_id UUID PRIMARY KEY,

    organizer_id UUID REFERENCES users(user_id),

    sport_id UUID REFERENCES sports(sport_id),

    tournament_name VARCHAR(255),

    format VARCHAR(50),

    registration_fee DECIMAL(12,2),

    start_date DATE,

    end_date DATE,

    status VARCHAR(50)
);
```

Formats:

* Knockout
* Round Robin
* League

---

## Tournament Registrations

Supports both teams and individual players.

```sql
CREATE TABLE tournament_registrations (
    registration_id UUID PRIMARY KEY,

    tournament_id UUID REFERENCES tournaments(tournament_id),

    team_id UUID REFERENCES teams(team_id),

    user_id UUID REFERENCES users(user_id),

    registration_status VARCHAR(50),

    registered_at TIMESTAMP
);
```

---

## Tournament Fixtures

Generated automatically.

```sql
CREATE TABLE tournament_fixtures (
    fixture_id UUID PRIMARY KEY,

    tournament_id UUID REFERENCES tournaments(tournament_id),

    team1_id UUID REFERENCES teams(team_id),

    team2_id UUID REFERENCES teams(team_id),

    venue_id UUID REFERENCES venues(venue_id),

    scheduled_at TIMESTAMP,

    fixture_status VARCHAR(50)
);
```

---

## Match Results

```sql
CREATE TABLE match_results (
    result_id UUID PRIMARY KEY,

    fixture_id UUID REFERENCES tournament_fixtures(fixture_id),

    winner_team_id UUID REFERENCES teams(team_id),

    score_summary TEXT,

    completed_at TIMESTAMP
);
```

---

# Payment Domain

## Payments

```sql
CREATE TABLE payments (
    payment_id UUID PRIMARY KEY,

    booking_id UUID REFERENCES bookings(booking_id),

    tournament_id UUID REFERENCES tournaments(tournament_id),

    user_id UUID REFERENCES users(user_id),

    amount DECIMAL(12,2),

    currency VARCHAR(10),

    payment_provider VARCHAR(50),

    payment_status VARCHAR(50),

    transaction_reference VARCHAR(255),

    created_at TIMESTAMP
);
```

---

## Refunds

```sql
CREATE TABLE refunds (
    refund_id UUID PRIMARY KEY,

    payment_id UUID REFERENCES payments(payment_id),

    refund_amount DECIMAL(12,2),

    refund_status VARCHAR(50),

    created_at TIMESTAMP
);
```

---

# Reviews and Ratings

## Venue Reviews

```sql
CREATE TABLE venue_reviews (
    review_id UUID PRIMARY KEY,

    venue_id UUID REFERENCES venues(venue_id),

    user_id UUID REFERENCES users(user_id),

    rating INTEGER,

    review_text TEXT,

    created_at TIMESTAMP
);
```

---

## Player Reviews

```sql
CREATE TABLE player_reviews (
    review_id UUID PRIMARY KEY,

    reviewer_id UUID REFERENCES users(user_id),

    reviewed_user_id UUID REFERENCES users(user_id),

    rating INTEGER,

    review_text TEXT,

    created_at TIMESTAMP
);
```

---

# Social Features

## Posts

```sql
CREATE TABLE posts (
    post_id UUID PRIMARY KEY,

    user_id UUID REFERENCES users(user_id),

    content TEXT,

    media_url TEXT,

    created_at TIMESTAMP
);
```

---

## Comments

```sql
CREATE TABLE comments (
    comment_id UUID PRIMARY KEY,

    post_id UUID REFERENCES posts(post_id),

    user_id UUID REFERENCES users(user_id),

    comment_text TEXT,

    created_at TIMESTAMP
);
```

---

## Likes

```sql
CREATE TABLE likes (
    like_id UUID PRIMARY KEY,

    post_id UUID REFERENCES posts(post_id),

    user_id UUID REFERENCES users(user_id),

    created_at TIMESTAMP
);
```

---

## Followers

```sql
CREATE TABLE followers (
    follower_id UUID PRIMARY KEY,

    follower_user_id UUID REFERENCES users(user_id),

    following_user_id UUID REFERENCES users(user_id),

    followed_at TIMESTAMP
);
```

---

# Notifications

## Notifications

```sql
CREATE TABLE notifications (
    notification_id UUID PRIMARY KEY,

    user_id UUID REFERENCES users(user_id),

    notification_type VARCHAR(100),

    title VARCHAR(255),

    message TEXT,

    is_read BOOLEAN,

    created_at TIMESTAMP
);
```

---

# Analytics & Audit

## Audit Logs

```sql
CREATE TABLE audit_logs (
    audit_id UUID PRIMARY KEY,

    entity_type VARCHAR(100),

    entity_id UUID,

    action VARCHAR(100),

    performed_by UUID,

    created_at TIMESTAMP
);
```

---

## Final High-Level ER Relationships

[Database Entities and Relations](./images/erd_sports_mgmt.png)

```text
Users
 ├── UserProfiles (1:1)
 ├── UserSports (M:N)
 ├── Bookings (1:N)
 ├── Matches (1:N Organizer)
 ├── MatchParticipants (M:N)
 ├── Teams (1:N Owner)
 ├── TeamMembers (M:N)
 ├── Payments (1:N)
 ├── Reviews (1:N)
 ├── Posts (1:N)
 └── Notifications (1:N)

Sports
 ├── Courts
 ├── Teams
 ├── Matches
 └── Tournaments

Venues
 ├── Addresses
 ├── Courts
 ├── Matches
 ├── Fixtures
 └── Reviews

Courts
 └── Slots

Slots
 └── Bookings

Bookings
 ├── Participants
 └── Payments

Teams
 ├── Members
 ├── Tournament Registrations
 └── Fixtures

Tournaments
 ├── Registrations
 ├── Fixtures
 └── Payments

Posts
 ├── Comments
 └── Likes
```

This schema covers roughly **90–95% of the entities required for a production-grade Playo/Hudle-style sports management platform**, including venue booking, player matchmaking, team management, tournaments, payments, social networking, ratings, notifications, and analytics.

---

