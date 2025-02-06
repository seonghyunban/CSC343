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
DROP VIEW IF EXISTS Large CASCADE;
DROP VIEW IF EXISTS Medium CASCADE;
DROP VIEW IF EXISTS Small CASCADE;

-- Define views for your intermediate steps here:
CREATE VIEW PlaneConfig AS
    SELECT p.tail_number as plane, p.airline as airline, count(distinct s.row) as row_count, count(distinct s.class) as class_count
    FROM Seat s JOIN PLANE p ON s.plane = p.tail_number
    GROUP BY p.tail_number, p.airline
    ORDER BY p.tail_number
;

CREATE VIEW Large AS
    SELECT airline as airline_code, CAST('large' AS airTravelWarmup.size_type) as size_type, count(distinct plane) as num_planes
    FROM PlaneConfig
    WHERE class_count = 3 and row_count >= 45
    GROUP BY airline
;

CREATE VIEW Medium AS
    SELECT airline as airline_code, CAST('medium' AS airTravelWarmup.size_type) as size_type, count(distinct plane) as num_planes
    FROM PlaneConfig
    WHERE class_count >= 2 and row_count >= 30 and NOT (class_count = 3 and row_count >= 45)
    GROUP BY airline
;

CREATE VIEW Small AS
    SELECT airline as airline_code, CAST('small' AS airTravelWarmup.size_type) as size_type, count(distinct plane) as num_planes
    FROM PlaneConfig
    WHERE NOT (class_count >= 2 and row_count >= 30) and NOT (class_count = 3 and row_count >= 45)
    GROUP BY airline
;

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO wu3
    (SELECT * FROM Large) UNION (SELECT * FROM Medium) UNION (SELECT * FROM Small) ORDER BY airline_code
;
