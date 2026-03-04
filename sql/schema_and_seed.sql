-- =========================================
-- AIRLINE PORTFOLIO DATABASE (PostgreSQL)
-- =========================================

-- Limpieza (por si re-ejecutas)
DROP TABLE IF EXISTS fact_tickets;
DROP TABLE IF EXISTS fact_bookings;
DROP TABLE IF EXISTS fact_flights;
DROP TABLE IF EXISTS dim_customers;
DROP TABLE IF EXISTS dim_aircraft;
DROP TABLE IF EXISTS dim_routes;
DROP TABLE IF EXISTS dim_airports;

-- ==============
-- DIMENSIONS
-- ==============

CREATE TABLE dim_airports (
  airport_code CHAR(3) PRIMARY KEY,
  airport_name VARCHAR(120) NOT NULL,
  city         VARCHAR(80)  NOT NULL,
  country      VARCHAR(80)  NOT NULL
);

CREATE TABLE dim_routes (
  route_id      SERIAL PRIMARY KEY,
  origin_code   CHAR(3) NOT NULL REFERENCES dim_airports(airport_code),
  destination_code CHAR(3) NOT NULL REFERENCES dim_airports(airport_code),
  route_group   VARCHAR(20) NOT NULL CHECK (route_group IN ('Domestic','International')),
  distance_km   INT NOT NULL CHECK (distance_km > 0),
  CONSTRAINT uq_route UNIQUE (origin_code, destination_code)
);

CREATE TABLE dim_aircraft (
  aircraft_id   SERIAL PRIMARY KEY,
  tail_number   VARCHAR(10) NOT NULL UNIQUE,         -- matrícula
  aircraft_type VARCHAR(30) NOT NULL,                -- 737MAX, 787, etc.
  seats_total   INT NOT NULL CHECK (seats_total > 0),
  status        VARCHAR(20) NOT NULL CHECK (status IN ('Active','Maintenance','Retired'))
);

CREATE TABLE dim_customers (
  customer_id   SERIAL PRIMARY KEY,
  full_name     VARCHAR(120) NOT NULL,
  email         VARCHAR(120) UNIQUE,
  loyalty_tier  VARCHAR(20) NOT NULL CHECK (loyalty_tier IN ('None','Silver','Gold','Platinum')),
  join_date     DATE NOT NULL,
  is_active     BOOLEAN NOT NULL DEFAULT TRUE
);

-- ==============
-- FACT TABLES
-- ==============

CREATE TABLE fact_flights (
  flight_id       SERIAL PRIMARY KEY,
  flight_number   VARCHAR(10) NOT NULL,
  flight_date     DATE NOT NULL,
  route_id        INT NOT NULL REFERENCES dim_routes(route_id),
  aircraft_id     INT NOT NULL REFERENCES dim_aircraft(aircraft_id),

  scheduled_dep   TIMESTAMP NOT NULL,
  actual_dep      TIMESTAMP NULL,
  scheduled_arr   TIMESTAMP NOT NULL,
  actual_arr      TIMESTAMP NULL,

  flight_status   VARCHAR(15) NOT NULL CHECK (flight_status IN ('OnTime','Delayed','Cancelled')),
  delay_minutes   INT NULL CHECK (delay_minutes >= 0),
  cancellation_reason VARCHAR(120) NULL
);

CREATE TABLE fact_bookings (
  booking_id     SERIAL PRIMARY KEY,
  customer_id    INT NOT NULL REFERENCES dim_customers(customer_id),
  booking_date   DATE NOT NULL,
  channel        VARCHAR(20) NOT NULL CHECK (channel IN ('Web','App','Agency','CallCenter')),
  payment_method VARCHAR(20) NOT NULL CHECK (payment_method IN ('Card','Cash','Transfer')),
  booking_status VARCHAR(15) NOT NULL CHECK (booking_status IN ('Confirmed','Cancelled','Refunded'))
);

CREATE TABLE fact_tickets (
  ticket_id      SERIAL PRIMARY KEY,
  booking_id     INT NOT NULL REFERENCES fact_bookings(booking_id),
  flight_id      INT NOT NULL REFERENCES fact_flights(flight_id),

  fare_class     VARCHAR(15) NOT NULL CHECK (fare_class IN ('Basic','Classic','Flex','Business')),
  base_fare      NUMERIC(10,2) NOT NULL CHECK (base_fare >= 0),
  taxes          NUMERIC(10,2) NOT NULL CHECK (taxes >= 0),
  ancillaries    NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (ancillaries >= 0),
  total_amount   NUMERIC(10,2) NOT NULL CHECK (total_amount >= 0),

  ticket_status  VARCHAR(15) NOT NULL CHECK (ticket_status IN ('Flown','NoShow','Refunded'))
);

-- ==================
-- SEED DATA (DEMO)
-- ==================

INSERT INTO dim_airports (airport_code, airport_name, city, country) VALUES
('MEX','Aeropuerto Internacional Benito Juárez','Ciudad de México','México'),
('GDL','Aeropuerto Internacional Miguel Hidalgo','Guadalajara','México'),
('MTY','Aeropuerto Internacional Mariano Escobedo','Monterrey','México'),
('CUN','Aeropuerto Internacional de Cancún','Cancún','México'),
('TIJ','Aeropuerto Internacional de Tijuana','Tijuana','México'),
('QRO','Aeropuerto Intercontinental de Querétaro','Querétaro','México'),
('LAX','Los Angeles International Airport','Los Ángeles','Estados Unidos'),
('JFK','John F. Kennedy International Airport','Nueva York','Estados Unidos');

INSERT INTO dim_aircraft (tail_number, aircraft_type, seats_total, status) VALUES
('XA-AAA','737MAX',174,'Active'),
('XA-AAB','737-800',160,'Active'),
('XA-AAC','787-8',243,'Active'),
('XA-AAD','E190',99,'Maintenance');

-- Rutas (algunas domésticas y dos internacionales)
INSERT INTO dim_routes (origin_code, destination_code, route_group, distance_km) VALUES
('MEX','GDL','Domestic', 460),
('MEX','MTY','Domestic', 700),
('MEX','CUN','Domestic', 1280),
('GDL','TIJ','Domestic', 1880),
('MTY','CUN','Domestic', 1470),
('MEX','QRO','Domestic', 210),
('MEX','LAX','International', 2500),
('MEX','JFK','International', 3350);

INSERT INTO dim_customers (full_name, email, loyalty_tier, join_date, is_active) VALUES
('Miguel García','miguel.garcia@email.com','Silver','2025-08-15',TRUE),
('Andrea López','andrea.lopez@email.com','None','2025-09-02',TRUE),
('Carlos Hernández','carlos.h@email.com','Gold','2024-12-10',TRUE),
('Sofía Ramírez','sofia.r@email.com','Platinum','2023-05-20',TRUE),
('Luis Torres','luis.t@email.com','None','2026-01-05',TRUE),
('Mariana Pérez','mariana.p@email.com','Silver','2025-11-01',FALSE);

-- Vuelos (marzo 2026, con on-time, delayed y cancelled)
-- Nota: delay_minutes NULL para Cancelled (para practicar NULL handling)
INSERT INTO fact_flights (
  flight_number, flight_date, route_id, aircraft_id,
  scheduled_dep, actual_dep, scheduled_arr, actual_arr,
  flight_status, delay_minutes, cancellation_reason
) VALUES
('AM101','2026-03-01', 1, 1, '2026-03-01 08:00','2026-03-01 08:05','2026-03-01 09:10','2026-03-01 09:12','OnTime', 0, NULL),
('AM202','2026-03-01', 2, 2, '2026-03-01 09:00','2026-03-01 09:50','2026-03-01 10:40','2026-03-01 11:25','Delayed', 50, NULL),
('AM303','2026-03-02', 3, 2, '2026-03-02 14:00','2026-03-02 14:10','2026-03-02 16:10','2026-03-02 16:18','Delayed', 10, NULL),
('AM404','2026-03-02', 7, 3, '2026-03-02 12:30',NULL,'2026-03-02 15:10',NULL,'Cancelled', NULL, 'Weather'),
('AM505','2026-03-03', 4, 1, '2026-03-03 07:20','2026-03-03 07:20','2026-03-03 09:55','2026-03-03 09:52','OnTime', 0, NULL),
('AM606','2026-03-03', 8, 3, '2026-03-03 23:30','2026-03-03 23:45','2026-03-04 05:20','2026-03-04 05:55','Delayed', 15, NULL);

-- Reservas
INSERT INTO fact_bookings (customer_id, booking_date, channel, payment_method, booking_status) VALUES
(1,'2026-02-20','App','Card','Confirmed'),
(2,'2026-02-25','Web','Card','Confirmed'),
(3,'2026-02-10','Agency','Transfer','Confirmed'),
(4,'2026-02-28','CallCenter','Card','Cancelled'),
(5,'2026-03-01','Web','Cash','Confirmed'),
(6,'2026-02-05','App','Card','Refunded');

-- Boletos (tickets) ligados a reservas y vuelos
INSERT INTO fact_tickets (
  booking_id, flight_id, fare_class, base_fare, taxes, ancillaries, total_amount, ticket_status
) VALUES
(1, 1, 'Classic', 1200, 450, 250, 1900, 'Flown'),
(1, 2, 'Basic',   900, 400,   0, 1300, 'Flown'),
(2, 3, 'Flex',   1600, 520, 200, 2320, 'Flown'),
(3, 5, 'Basic',   800, 380, 250, 1430, 'NoShow'),
(4, 4, 'Business',5000, 900,   0, 5900, 'Refunded'),
(6, 2, 'Classic', 1100, 430, 250, 1780, 'Refunded');

-- Listo: esquema + datos de ejemplo para arrancar.
