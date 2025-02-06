-- Warmup Query 1

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO AirTravelWarmup;
DROP TABLE IF EXISTS wu1 CASCADE;

CREATE TABLE wu1 (
    last_name VARCHAR(200) NOT NULL,
    p1_first_name VARCHAR(200) NOT NULL,
    p2_first_name VARCHAR(200) NOT NULL
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
-- If you do not define any views, you can delete the lines about views.
DROP VIEW IF EXISTS PassengerBooks CASCADE;

-- Define views for your intermediate steps here:
CREATE VIEW PassengerBooks AS
    SELECT b.bid, b.seat, b.flight, p.pid, p.first_name, p.last_name, b.date_time
    FROM Passenger p JOIN BOOKING b ON p.pid = b.Passenger
;

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO wu1
    SELECT p1.last_name as last_name, p1.first_name as p1_first_name, p2.first_name as p2_first_name
    FROM PassengerBooks p1, PassengerBooks p2
    WHERE 
        p1.pid != p2.pid and
        p1.last_name = p2.last_name and
        p1.flight = p2.flight and
        p1.date_time - p2.date_time BETWEEN INTERVAL '0 seconds' AND INTERVAL '1 hour'
;