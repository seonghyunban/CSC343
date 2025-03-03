-- Frequent flyers

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO AirTravel;
DROP TABLE IF EXISTS q5 CASCADE;

CREATE TABLE q5 (
    pid INT NOT NULL,
    email VARCHAR(500) NOT NULL
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
-- If you do not define any views, you can delete the lines about views.
DROP VIEW IF EXISTS intermediate_step CASCADE;

-- Define views for your intermediate steps here:
DROP VIEW IF EXISTS Visits CASCADE;
CREATE VIEW Visits AS (
    SELECT B.passenger AS pid
    FROM Booking B
        JOIN Flight F ON B.flight = F.fid
        JOIN Arrival A ON F.fid = A.fid
        JOIN Route R ON F.route = R.flight_num
        JOIN Airport P ON R.destination = P.code
        JOIN City C ON P.city = C.cid
    GROUP BY B.passenger
    HAVING COUNT(DISTINCT C.country) >= 5
);

DROP VIEW IF EXISTS Book2023 CASCADE;
CREATE VIEW Book2023 AS (
    SELECT B.passenger AS pid
    FROM Booking B
    WHERE B.date_time BETWEEN '2023-01-01 00:00:00' AND '2023-12-31 23:59:59'
    GROUP BY B.passenger
    HAVING COUNT(DISTINCT B.flight) >= 10
);

DROP VIEW IF EXISTS Book2024 CASCADE;
CREATE VIEW Book2024 AS (
    SELECT B.passenger AS pid
    FROM Booking B
    WHERE B.date_time BETWEEN '2024-01-01 00:00:00' AND '2024-12-31 23:59:59'
    GROUP BY B.passenger
    HAVING COUNT(DISTINCT B.flight) > 
            (SELECT count(DISTINCT B2.flight) 
            FROM Booking B2
            WHERE B2.date_time BETWEEN '2023-01-01 00:00:00' AND '2023-12-31 23:59:59'
                AND B2.passenger = B.passenger )
           
);

DROP VIEW IF EXISTS Book2025 CASCADE;
CREATE VIEW Book2025 AS (
    SELECT B.passenger AS pid
    FROM Passenger P
        LEFT JOIN Booking B ON P.pid = B.passenger
    GROUP BY B.passenger
    HAVING COUNT(DISTINCT B.flight) 
            FILTER (WHERE B.date_time BETWEEN '2025-01-01 00:00:00' AND '2025-12-31 23:59:59') = 0
);

DROP VIEW IF EXISTS FrequentFlyers CASCADE;
CREATE VIEW FrequentFlyers AS (
    
    WITH F AS (
        SELECT pid FROM Visits
        INTERSECT
        SELECT pid FROM Book2023
        INTERSECT
        SELECT pid FROM Book2024
        INTERSECT
        SELECT pid FROM Book2025
    )
    SELECT F.pid, P.email
    FROM
    F JOIN Passenger P ON F.pid = P.pid
);


-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q5
    SELECT * FROM FrequentFlyers;
