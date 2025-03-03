-- ============================================
-- Populate minimal data for test_reassign_plane
-- ============================================

-- 1) City
INSERT INTO City (cid, name, country)
VALUES
    (1, 'Toronto',   'Canada'),
    (2, 'Vancouver', 'Canada');

-- 2) Airline
INSERT INTO Airline (code, name)
VALUES
    ('AC', 'Air Canada');

-- 3) Passenger
INSERT INTO Passenger (pid, first_name, last_name, email)
VALUES
    (1, 'Firstname 1', 'Lastname 1', 'passenger1@email.com');

-- 4) Plane
INSERT INTO Plane (tail_number, model, airline)
VALUES
    (1, 'Something',      'AC'),
    (2, 'Something Else', 'AC');

-- 5) Seat
--   Plane #1 has 3 seats; Plane #2 has 6 seats
INSERT INTO Seat (sid, plane, row, letter, class)
VALUES
    -- Plane 1
    (1,  1, 1, 'A', 'first'),
    (2,  1, 2, 'A', 'business'),
    (3,  1, 3, 'A', 'economy'),
    -- Plane 2
    (4,  2, 1, 'A', 'first'),
    (5,  2, 1, 'B', 'first'),
    (6,  2, 2, 'A', 'business'),
    (7,  2, 2, 'B', 'business'),
    (8,  2, 3, 'A', 'economy'),
    (9,  2, 3, 'B', 'economy');

-- 6) Airport
INSERT INTO Airport (code, name, city)
VALUES
    ('YVR', 'YVR Airport', 2),
    ('YYZ', 'YYZ Airport', 1);

-- 7) Route
INSERT INTO Route (flight_num, airline, source, destination)
VALUES
    (1, 'AC', 'YYZ', 'YVR');

-- 8) Flight
--   A single flight (fid=1) on plane #1
INSERT INTO Flight (fid, route, plane, sched_dept, sched_arrival)
VALUES
    (1, 1, 1, '2025-07-02 10:00', '2025-07-03 08:00');

-- 9) Departure
INSERT INTO Departure (fid, date_time)
VALUES
    (1, '2025-07-02 10:00');

-- 10) Arrival
INSERT INTO Arrival (fid, date_time)
VALUES
    (1, '2025-07-03 08:00');

-- 11) FlightPrice
--   Three classes for fid=1
INSERT INTO FlightPrice (fid, class, price)
VALUES
    (1, 'business', 600.0),
    (1, 'economy',  300.0),
    (1, 'first',    1000.0);

-- 12) Booking
--   None in this scenario (no rows).

-- Done!