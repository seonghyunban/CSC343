-- Recommendation

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO AirTravel;
DROP TABLE IF EXISTS q3 CASCADE;

CREATE TABLE q3 (
    pid INT NOT NULL,
    name VARCHAR(410) NOT NULL,
	city VARCHAR(410) NOT NULL
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
-- If you do not define any views, you can delete the lines about views.
DROP VIEW IF EXISTS intermediate_step CASCADE;

-- Define views for your intermediate steps here:
DROP VIEW IF EXISTS ArrivedBooks CASCADE;
CREATE VIEW ArrivedBooks AS (
    SELECT B.bid, B.flight, B.passenger as pid
    FROM Booking B 
        JOIN Arrival A ON B.flight = A.fid
    WHERE A.date_time < NOW()
);

DROP VIEW IF EXISTS ArrivedBooksAugmented CASCADE;
CREATE VIEW ArrivedBooksAugmented AS (
    SELECT B.bid, B.flight, R.destination, C.name as city, C.country, B.pid, P.first_name, P.last_name
    FROM ArrivedBooks B 
        JOIN Passenger P ON B.pid = P.pid
        JOIN Flight F ON B.flight = F.fid
        JOIN Route R ON F.route = R.flight_num
        JOIN Airport A ON R.destination = A.code
        JOIN City C ON A.city = C.cid
);

DROP VIEW IF EXISTS PassengerPairs CASCADE;
CREATE VIEW PassengerPairs AS (
    SELECT distinct P1.pid as p1_pid, P2.pid as p2_pid, P1.city p1_city, P2.city p2_city, (P1.city = P2.city) AS same_city
    FROM ArrivedBooksAugmented P1, ArrivedBooksAugmented P2
    WHERE P1.pid <> P2.pid
);

DROP VIEW IF EXISTS TravelOverlap CASCADE;
CREATE VIEW TravelOverlap AS (
    SELECT p1_pid, p2_pid, 
        count(*) FILTER (WHERE same_city = TRUE) as same_city_count, 
        count(distinct p1_city) as p1_city_count
    FROM PassengerPairs
    GROUP BY p1_pid, p2_pid
);

DROP VIEW IF EXISTS SimilarTraveler CASCADE;
CREATE VIEW SimilarTraveler AS (
    SELECT p1_pid, p2_pid, (same_city_count::FLOAT / p1_city_count > 0.5) as similar
    FROM TravelOverlap
);

DROP VIEW IF EXISTS Recommendation CASCADE;
CREATE VIEW Recommendation AS (
    SELECT distinct p1_pid as pid, P1.first_name || ' ' || P1.last_name as name, P2.city || ', ' || P2.country as city
    FROM SimilarTraveler S
        JOIN ArrivedBooksAugmented P1 ON S.p1_pid = P1.pid
        JOIN ArrivedBooksAugmented P2 ON S.p2_pid = P2.pid
    WHERE S.similar = TRUE AND
        P2.city NOT IN (SELECT distinct city FROM ArrivedBooksAugmented WHERE pid = P1.pid)

);

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q3
    SELECT * FROM Recommendation
;