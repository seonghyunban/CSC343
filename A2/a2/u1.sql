SET SEARCH_PATH TO AirTravel;

DROP VIEW IF EXISTS DiscountFlights CASCADE;
CREATE VIEW DiscountFlights AS (
    SELECT F.fid 
    FROM Flight F 
        JOIN Route R ON F.route = R.flight_num 
        JOIN Airport A ON R.destination = A.code
        JOIN City C ON A.city = C.cid
    WHERE
        R.airline = 'AC'
        AND F.sched_dept >= '2025-06-01 00:00:00' 
        AND F.sched_dept < '2025-09-01 00:00:00'
        AND C.country = 'Canada' OR C.country = 'United States'
);

UPDATE FlightPrice
SET price = price * 0.8
WHERE fid IN (SELECT fid FROM DiscountFlights) AND class = 'first';

UPDATE FlightPrice
SET price = price * 0.7
WHERE fid IN (SELECT fid FROM DiscountFlights) AND class = 'business';

UPDATE FlightPrice
SET price = price * 0.6
WHERE fid IN (SELECT fid FROM DiscountFlights) AND class = 'economy';