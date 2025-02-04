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

-- Define views for your intermediate steps here:
CREATE VIEW CountryWith2Airport AS
    SELECT c.country, count(a.code)
    FROM City c JOIN Airport a ON c.cid = a.city
    GROUP BY c.country
    HAVING count(a.code) >= 2
;

CREATE VIEW RouteExpanded AS
    SELECT r.flight_num, sc.country as src, dc.country as dest
    FROM Route r JOIN Airport sa ON r.source = sa.code 
                 JOIN Airport da ON r.destination = da.code 
                 JOIN City sc    ON sa.city = sc.cid
                 JOIN City dc    ON da.city = dc.cid
;
-- Your query that answers the question goes below the "insert into" line:
INSERT INTO wu2
    SELECT c.country, count(f.fid)
    FROM Flight f JOIN RouteExpanded r ON f.route = r.flight_num
                  CROSS JOIN CountryWith2Airport c
    WHERE r.src = c.country or r.dest = c.country
    GROUP BY c.country
;
