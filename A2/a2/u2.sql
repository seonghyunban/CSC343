SET SEARCH_PATH TO AirTravel;

DROP VIEW IF EXISTS ToBeDeletedPlanes CASCADE;
CREATE VIEW ToBeDeletedPlanes AS (
    (SELECT tail_number FROM Plane)
    EXCEPT
    (SELECT F.plane
    FROM Flight F 
        JOIN Arrival A ON F.fid = A.fid
    GROUP BY F.Plane
    Having MAX(A.date_time) > '2021-12-31 23:59:59')
);

DROP VIEW IF EXISTS ToBeDeletedFlights CASCADE;
CREATE VIEW ToBeDeletedFlights AS (
    SELECT fid
    FROM Flight
    WHERE plane IN (SELECT * FROM ToBeDeletedPlanes)
);

DROP VIEW IF EXISTS ToBeDeletedDepartures CASCADE;
CREATE VIEW ToBeDeletedDepartures AS (
    SELECT fid
    FROM Departure
    WHERE fid IN (SELECT * FROM ToBeDeletedFlights)
);


DELETE FROM Booking
WHERE flight IN (SELECT * FROM ToBeDeletedFlights)
;

DELETE FROM FlightPrice
WHERE fid IN (SELECT * FROM ToBeDeletedFlights)
;

DELETE FROM Arrival
WHERE fid IN (SELECT * FROM ToBeDeletedDepartures)
;

DELETE FROM Departure
WHERE fid IN (SELECT * FROM ToBeDeletedFlights)
;

DELETE FROM Flight
WHERE plane IN (SELECT * FROM ToBeDeletedPlanes)
;

DELETE FROM Seat
WHERE plane IN (SELECT * FROM ToBeDeletedPlanes)
;

DELETE FROM Plane
WHERE tail_number IN (SELECT * FROM ToBeDeletedPlanes)
;