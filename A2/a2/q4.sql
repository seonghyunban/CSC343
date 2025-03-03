-- Airline information

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO AirTravel;
DROP TABLE IF EXISTS q4 CASCADE;

CREATE TABLE q4 (
    airline CHAR(2) NOT NULL,
    num_planes INT NOT NULL,
    num_routes INT NOT NULL,
    avg_flights REAL DEFAULT NULL,
    avg_delay INTERVAL DEFAULT NULL,
    avg_first_price REAL DEFAULT NULL,
    avg_business_price REAL DEFAULT NULL,
    avg_economy_price REAL DEFAULT NULL   
);

--- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
-- If you do not define any views, you can delete the lines about views.
DROP VIEW IF EXISTS intermediate_step CASCADE;

-- Define views for your intermediate steps here:
DROP VIEW IF EXISTS PlaneInfo CASCADE;
CREATE VIEW PlaneInfo AS (
    SELECT A.code as airline, COUNT(DISTINCT P.tail_number) AS num_planes
    FROM Airline A LEFT JOIN Plane P ON A.code = P.airline
    GROUP BY A.code
);

DROP VIEW IF EXISTS RouteInfo CASCADE;
CREATE VIEW RouteInfo AS (
    SELECT A.code as airline, COUNT(DISTINCT R.flight_num) AS num_routes
    FROM Airline A LEFT JOIN Route R ON A.code = R.airline
    GROUP BY A.code
);

DROP VIEW IF EXISTS FlightInfo CASCADE;
CREATE VIEW FlightInfo AS (
    SELECT A.code, F.route, count(distinct F.fid) as num_flights
    FROM Airline A 
        LEFT JOIN Route R ON A.code = R.airline
        LEFT JOIN Flight F ON F.route = R.flight_num
    GROUP BY A.code, F.route
);

DROP VIEW IF EXISTS AvgFlightInfo CASCADE;
CREATE VIEW AvgFlightInfo AS (
    SELECT F.code, (CASE WHEN AVG(F.num_flights) > 0 THEN AVG(F.num_flights) ELSE NULL END) as avg_flights
    FROM FlightInfo F
    GROUP BY F.code
);

DROP VIEW IF EXISTS DelayInfo CASCADE;
CREATE VIEW DelayInfo AS (
    SELECT A.code, (D.date_time - F.sched_dept) as delay
    FROM Airline A
        LEFT JOIN Route R ON A.code = R.airline
        LEFT JOIN Flight F ON R.flight_num = F.route
        LEFT JOIN Departure D ON F.fid = D.fid
);

DROP VIEW IF EXISTS AvgDelayInfo CASCADE;
CREATE VIEW AvgDelayInfo AS (
    SELECT D.code, (CASE WHEN AVG(D.delay) IS NOT NULL THEN AVG(D.delay) ELSE NULL END) as avg_delay
    FROM DelayInfo D
    GROUP BY D.code
);

DROP VIEW IF EXISTS AvgPriceInfo CASCADE;
CREATE VIEW AvgPriceInfo AS (
    SELECT A.code,
        AVG(B.price) FILTER (WHERE S.class = 'first') as avg_first_price,
        AVG(B.price) FILTER (WHERE S.class = 'business') as avg_business_price,
        AVG(B.price) FILTER (WHERE S.class = 'economy') as avg_economy_price
    FROM Airline A
        LEFT JOIN Route R ON A.code = R.airline
        LEFT JOIN Flight F ON R.flight_num = F.route
        LEFT JOIN Booking B ON F.fid = B.flight
        LEFT JOIN Seat S ON B.seat = S.sid
    GROUP BY A.code
);

DROP VIEW IF EXISTS AirlineInfo CASCADE;
CREATE VIEW AirlineInfo AS (
    SELECT A.code, P.num_planes, R.num_routes, F.avg_flights, D.avg_delay, B.avg_first_price, B.avg_business_price, B.avg_economy_price
    FROM Airline A
        LEFT JOIN PlaneInfo P ON A.code = P.airline
        LEFT JOIN RouteInfo R ON A.code = R.airline
        LEFT JOIN AvgFlightInfo F ON A.code = F.code
        LEFT JOIN AvgDelayInfo D ON A.code = D.code
        LEFT JOIN AvgPriceInfo B ON A.code = B.code
);

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q4
    SELECT * FROM AirlineInfo
