CREATE TABLE "USERS" (
  "user_id" bigint PRIMARY KEY,
  "name" varchar,
  "email" varchar,
  "mobile" varchar,
  "password_hash" varchar,
  "created_at" timestamp,
  "updated_at" timestamp
);

CREATE TABLE "PASSENGERS" (
  "passenger_id" bigint PRIMARY KEY,
  "user_id" bigint,
  "full_name" varchar,
  "age" int,
  "gender" varchar,
  "nationality" varchar,
  "berth_preference" varchar,
  "created_at" timestamp
);

CREATE TABLE "STATIONS" (
  "station_id" bigint PRIMARY KEY,
  "station_code" varchar,
  "station_name" varchar,
  "city" varchar,
  "state" varchar,
  "zone" varchar,
  "latitude" decimal,
  "longitude" decimal
);

CREATE TABLE "TRAINS" (
  "train_id" bigint PRIMARY KEY,
  "train_number" varchar,
  "train_name" varchar,
  "train_type" varchar,
  "source_station_id" bigint,
  "destination_station_id" bigint,
  "is_active" boolean
);

CREATE TABLE "TRAIN_ROUTES" (
  "route_id" bigint PRIMARY KEY,
  "train_id" bigint,
  "station_id" bigint,
  "stop_number" int,
  "arrival_time" time,
  "departure_time" time,
  "distance_from_source" int
);

CREATE TABLE "COACHES" (
  "coach_id" bigint PRIMARY KEY,
  "train_id" bigint,
  "coach_number" varchar,
  "coach_type" varchar,
  "total_seats" int
);

CREATE TABLE "SEATS" (
  "seat_id" bigint PRIMARY KEY,
  "coach_id" bigint,
  "seat_number" varchar,
  "berth_type" varchar,
  "seat_position" varchar
);

CREATE TABLE "JOURNEY_INSTANCES" (
  "journey_id" bigint PRIMARY KEY,
  "train_id" bigint,
  "journey_date" date,
  "status" varchar,
  "created_at" timestamp
);

CREATE TABLE "JOURNEY_SEAT_INVENTORY" (
  "inventory_id" bigint PRIMARY KEY,
  "journey_id" bigint,
  "seat_id" bigint,
  "current_status" varchar,
  "quota" varchar,
  "last_updated" timestamp
);

CREATE TABLE "QUOTAS" (
  "quota_id" bigint PRIMARY KEY,
  "quota_code" varchar,
  "quota_name" varchar
);

CREATE TABLE "JOURNEY_QUOTA_ALLOCATION" (
  "allocation_id" bigint PRIMARY KEY,
  "journey_id" bigint,
  "quota_id" bigint,
  "total_seats" int,
  "available_seats" int
);

CREATE TABLE "BOOKINGS" (
  "booking_id" bigint PRIMARY KEY,
  "pnr_number" varchar,
  "user_id" bigint,
  "journey_id" bigint,
  "source_station_id" bigint,
  "destination_station_id" bigint,
  "boarding_station_id" bigint,
  "booking_status" varchar,
  "booking_time" timestamp,
  "total_fare" decimal
);

CREATE TABLE "BOOKING_PASSENGERS" (
  "booking_passenger_id" bigint PRIMARY KEY,
  "booking_id" bigint,
  "passenger_id" bigint,
  "seat_id" bigint,
  "passenger_status" varchar,
  "coach_number" varchar,
  "seat_number" varchar
);

CREATE TABLE "TICKETS" (
  "ticket_id" bigint PRIMARY KEY,
  "booking_id" bigint,
  "ticket_number" varchar,
  "issued_at" timestamp,
  "ticket_status" varchar
);

CREATE TABLE "PAYMENTS" (
  "payment_id" bigint PRIMARY KEY,
  "booking_id" bigint,
  "amount" decimal,
  "payment_method" varchar,
  "gateway_transaction_id" varchar,
  "payment_status" varchar,
  "paid_at" timestamp
);

CREATE TABLE "REFUNDS" (
  "refund_id" bigint PRIMARY KEY,
  "payment_id" bigint,
  "refund_amount" decimal,
  "refund_reason" varchar,
  "refund_status" varchar,
  "refunded_at" timestamp
);

CREATE TABLE "RAC_QUEUE" (
  "rac_id" bigint PRIMARY KEY,
  "journey_id" bigint,
  "booking_passenger_id" bigint,
  "rac_position" int,
  "created_at" timestamp
);

CREATE TABLE "WAITLIST_QUEUE" (
  "waitlist_id" bigint PRIMARY KEY,
  "journey_id" bigint,
  "booking_passenger_id" bigint,
  "waitlist_number" int,
  "created_at" timestamp
);

CREATE TABLE "NOTIFICATIONS" (
  "notification_id" bigint PRIMARY KEY,
  "user_id" bigint,
  "booking_id" bigint,
  "notification_type" varchar,
  "status" varchar,
  "sent_at" timestamp
);

CREATE TABLE "AUDIT_LOGS" (
  "audit_id" bigint PRIMARY KEY,
  "entity_type" varchar,
  "entity_id" bigint,
  "action" varchar,
  "old_value" text,
  "new_value" text,
  "performed_by" varchar,
  "created_at" timestamp
);

ALTER TABLE "PASSENGERS" ADD FOREIGN KEY ("user_id") REFERENCES "USERS" ("user_id");

ALTER TABLE "TRAINS" ADD FOREIGN KEY ("source_station_id") REFERENCES "STATIONS" ("station_id");

ALTER TABLE "TRAINS" ADD FOREIGN KEY ("destination_station_id") REFERENCES "STATIONS" ("station_id");

ALTER TABLE "TRAIN_ROUTES" ADD FOREIGN KEY ("train_id") REFERENCES "TRAINS" ("train_id");

ALTER TABLE "TRAIN_ROUTES" ADD FOREIGN KEY ("station_id") REFERENCES "STATIONS" ("station_id");

ALTER TABLE "COACHES" ADD FOREIGN KEY ("train_id") REFERENCES "TRAINS" ("train_id");

ALTER TABLE "SEATS" ADD FOREIGN KEY ("coach_id") REFERENCES "COACHES" ("coach_id");

ALTER TABLE "JOURNEY_INSTANCES" ADD FOREIGN KEY ("train_id") REFERENCES "TRAINS" ("train_id");

ALTER TABLE "JOURNEY_SEAT_INVENTORY" ADD FOREIGN KEY ("journey_id") REFERENCES "JOURNEY_INSTANCES" ("journey_id");

ALTER TABLE "JOURNEY_SEAT_INVENTORY" ADD FOREIGN KEY ("seat_id") REFERENCES "SEATS" ("seat_id");

ALTER TABLE "JOURNEY_QUOTA_ALLOCATION" ADD FOREIGN KEY ("journey_id") REFERENCES "JOURNEY_INSTANCES" ("journey_id");

ALTER TABLE "JOURNEY_QUOTA_ALLOCATION" ADD FOREIGN KEY ("quota_id") REFERENCES "QUOTAS" ("quota_id");

ALTER TABLE "BOOKINGS" ADD FOREIGN KEY ("user_id") REFERENCES "USERS" ("user_id");

ALTER TABLE "BOOKINGS" ADD FOREIGN KEY ("journey_id") REFERENCES "JOURNEY_INSTANCES" ("journey_id");

ALTER TABLE "BOOKINGS" ADD FOREIGN KEY ("source_station_id") REFERENCES "STATIONS" ("station_id");

ALTER TABLE "BOOKINGS" ADD FOREIGN KEY ("destination_station_id") REFERENCES "STATIONS" ("station_id");

ALTER TABLE "BOOKINGS" ADD FOREIGN KEY ("boarding_station_id") REFERENCES "STATIONS" ("station_id");

ALTER TABLE "BOOKING_PASSENGERS" ADD FOREIGN KEY ("booking_id") REFERENCES "BOOKINGS" ("booking_id");

ALTER TABLE "BOOKING_PASSENGERS" ADD FOREIGN KEY ("passenger_id") REFERENCES "PASSENGERS" ("passenger_id");

ALTER TABLE "BOOKING_PASSENGERS" ADD FOREIGN KEY ("seat_id") REFERENCES "SEATS" ("seat_id");

ALTER TABLE "TICKETS" ADD FOREIGN KEY ("booking_id") REFERENCES "BOOKINGS" ("booking_id");

ALTER TABLE "PAYMENTS" ADD FOREIGN KEY ("booking_id") REFERENCES "BOOKINGS" ("booking_id");

ALTER TABLE "REFUNDS" ADD FOREIGN KEY ("payment_id") REFERENCES "PAYMENTS" ("payment_id");

ALTER TABLE "RAC_QUEUE" ADD FOREIGN KEY ("journey_id") REFERENCES "JOURNEY_INSTANCES" ("journey_id");

ALTER TABLE "RAC_QUEUE" ADD FOREIGN KEY ("booking_passenger_id") REFERENCES "BOOKING_PASSENGERS" ("booking_passenger_id");

ALTER TABLE "WAITLIST_QUEUE" ADD FOREIGN KEY ("journey_id") REFERENCES "JOURNEY_INSTANCES" ("journey_id");

ALTER TABLE "WAITLIST_QUEUE" ADD FOREIGN KEY ("booking_passenger_id") REFERENCES "BOOKING_PASSENGERS" ("booking_passenger_id");

ALTER TABLE "NOTIFICATIONS" ADD FOREIGN KEY ("user_id") REFERENCES "USERS" ("user_id");

ALTER TABLE "NOTIFICATIONS" ADD FOREIGN KEY ("booking_id") REFERENCES "BOOKINGS" ("booking_id");
