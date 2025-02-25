-- Warmup Query 2

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO AirTravelWarmup;
DROP TABLE IF EXISTS wu2 CASCADE;

CREATE TABLE wu2 (
    country_name VARCHAR(200) NOT NULL,
    operational_airports INT NOT NULL
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
-- If you do not define any views, you can delete the lines about views.
DROP VIEW IF EXISTS CountryWith2Airport CASCADE;
DROP VIEW IF EXISTS RouteExpanded CASCADE;
DROP VIEW IF EXISTS OperationalAirports CASCADE;

-- Define views for your intermediate steps here:
CREATE VIEW CountryWith2Airport AS
    SELECT c.country, count(a.code)
    FROM City c JOIN Airport a ON c.cid = a.city
    GROUP BY c.country
    HAVING count(a.code) >= 2
;


CREATE VIEW RouteExpanded AS
    SELECT r.flight_num, sa.code as srcport, sc.country as src, da.code as destport, dc.country as dest
    FROM Route r JOIN Airport sa ON r.source = sa.code 
                 JOIN Airport da ON r.destination = da.code 
                 JOIN City sc    ON sa.city = sc.cid
                 JOIN City dc    ON da.city = dc.cid
                 JOIN Flight f   ON r.flight_num = f.route
;

CREATE VIEW OperationalAirports AS
    SELECT c.country, count(tmp.port) as count
    FROM CountryWith2Airport c LEFT JOIN 
                             ((SELECT src as country, srcport as port FROM RouteExpanded) UNION (SELECT dest as country, destport as port FROM RouteExpanded)) AS Tmp
                             ON c.country = tmp.country
    GROUP BY c.country
;


-- Your query that answers the question goes below the "insert into" line:
INSERT INTO wu2
    SELECT country as country_name, count as operational_airports
    FROM OperationalAirports
;
