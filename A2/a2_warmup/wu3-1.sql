-- Warmup Query 3

-- You must not change the next 2 lines or the table or type definition.
SET SEARCH_PATH TO AirTravelWarmup;
DROP TABLE IF EXISTS wu3 CASCADE;

DROP TYPE IF EXISTS size_type CASCADE;
CREATE TYPE AirTravelWarmup.size_type AS ENUM (
    'large', 'medium', 'small'
);

CREATE TABLE wu3 (
    airline_code CHAR(2),
    size size_type NOT NULL,
    num_planes int NOT NULL
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
-- If you do not define any views, you can delete the lines about views.
DROP VIEW IF EXISTS PlaneConfig CASCADE;
DROP VIEW IF EXISTS PlaneSize CASCADE;

-- Define views for your intermediate steps here:
CREATE VIEW PlaneConfig AS
    SELECT s.plane, count(distinct s.row) as row_count, count(distinct s.class) as class_count
    FROM Seat s JOIN PLANE p ON s.plane = p.tail_number
    GROUP BY s.plane
    ORDER BY s.plane
;

CREATE VIEW PlaneSize AS
    SELECT pc.plane, CAST(CASE
                                     WHEN  pc.class_count = 3 and pc.row_count >= 45 THEN 'large'
                                     WHEN pc.class_count >= 2 and pc.row_count >= 30 THEN 'medium'
                                     ELSE 'small'
                                END
                                AS AirTravelWarmup.size_type
                        ) AS size
    FROM Plane p JOIN PlaneConfig pc ON p.tail_number = pc.plane
    ORDER BY pc.plane
;

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO wu3
    SELECT airline as airline_code, size as size_type, count(plane) as num_planes
    FROM PlaneSize ps JOIN Plane p ON ps.plane = p.tail_number
    GROUP BY airline, size
