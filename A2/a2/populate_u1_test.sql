-- =========================================================
-- 1) City
-- =========================================================
INSERT INTO City (cid, name, country)
VALUES
    (1, 'Toronto',   'Canada'),
    (2, 'Vancouver', 'Canada');

-- =========================================================
-- 2) Airline
-- =========================================================
INSERT INTO Airline (code, name)
VALUES
    ('AC', 'Air Canada');

-- =========================================================
-- 3) Passenger
-- =========================================================
INSERT INTO Passenger (pid, first_name, last_name, email)
VALUES
    (1, 'Firstname 1', 'Lastname 1', 'passenger1@email.com');

-- =========================================================
-- 4) Plane
-- =========================================================
INSERT INTO Plane (tail_number, model, airline)
VALUES
    (1, 'Something', 'AC');

-- =========================================================
-- 5) Seat
--    We'll only have 3 seats (first, business, economy)
-- =========================================================
INSERT INTO Seat (sid, plane, row, letter, class)
VALUES
    (1, 1, 1, 'A', 'first'),
    (2, 1, 2, 'A', 'business'),
    (3, 1, 3, 'A', 'economy');

-- =========================================================
-- 6) Airport
-- =========================================================
INSERT INTO Airport (code, name, city)
VALUES
    ('YVR', 'YVR Airport', 2),
    ('YYZ', 'YYZ Airport', 1);

-- =========================================================
-- 7) Route
--    Only one route (#1) from YYZ -> YVR
-- =========================================================
INSERT INTO Route (flight_num, airline, source, destination)
VALUES
    (1, 'AC', 'YYZ', 'YVR');

-- =========================================================
-- 8) Flight
--    Two flights (fid=1, fid=2) using route=1, plane=1.
--    #1 departs 2025-06-01, arrives 2025-06-02
--    #2 departs 2025-08-31, arrives 2025-09-01
-- =========================================================
INSERT INTO Flight (fid, route, plane, sched_dept, sched_arrival)
VALUES
    (1, 1, 1, '2025-06-01 10:00', '2025-06-02 08:00'),
    (2, 1, 1, '2025-08-31 10:00', '2025-09-01 08:00');

-- =========================================================
-- 9) Departure
--    Matches each flight's departure time
-- =========================================================
INSERT INTO Departure (fid, date_time)
VALUES
    (1, '2025-06-01 10:00'),
    (2, '2025-08-31 10:00');

-- =========================================================
-- 10) Arrival
--    Matches each flight's arrival time
-- =========================================================
INSERT INTO Arrival (fid, date_time)
VALUES
    (1, '2025-06-02 08:00'),
    (2, '2025-09-01 08:00');

-- =========================================================
-- 11) FlightPrice
--    BEFORE the discount sale:
--    Flight #1: business=600, economy=300, first=1000
--    Flight #2: business=200, economy=100, first=300
-- =========================================================
INSERT INTO FlightPrice (fid, class, price)
VALUES
    (1, 'business', 600.0),
    (1, 'economy',  300.0),
    (1, 'first',    1000.0),
    (2, 'business', 200.0),
    (2, 'economy',  100.0),
    (2, 'first',    300.0);

-- =========================================================
-- 12) Booking
--    2 bookings for passenger #1:
--      * flight=1, seat=1 (first class), price=1000, date_time=2024-12-25 09:30
--      * flight=2, seat=1 (first class), price=300,  date_time=2024-12-25 09:30
-- =========================================================
INSERT INTO Booking (bid, passenger, seat, flight, price, date_time)
VALUES
    (1, 1, 1, 1, 1000.0, '2024-12-25 09:30'),
    (2, 1, 1, 2, 300.0,  '2024-12-25 09:30');