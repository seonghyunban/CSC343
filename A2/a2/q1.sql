-- Route fullness

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO AirTravel;
DROP TABLE IF EXISTS q1 CASCADE;

CREATE TABLE q1 (
    airline CHAR(2) NOT NULL,
    flight_num VARCHAR(6) NOT NULL,
	very_low INT NOT NULL,
	low INT NOT NULL,
	fair INT NOT NULL,
	normal INT NOT NULL,
	high INT NOT NULL
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
-- If you do not define any views, you can delete the lines about views.
DROP VIEW IF EXISTS PlaneInfo CASCADE;
DROP VIEW IF EXISTS FlightBookInfo CASCADE;
DROP VIEW IF EXISTS FlightBookNRouteNFullnessInfo CASCADE;
DROP VIEW IF EXISTS FullnessHistogram CASCADE;



-- Define views for your intermediate steps here:

CREATE VIEW PlaneInfo AS (
	SELECT tail_number as pid, count(S.sid) as cap
	FROM Plane P, Seat S
	WHERE P.tail_number = S.plane
	GROUP BY tail_number
);


CREATE VIEW FlightBookInfo AS (
	SELECT F.fid, F.route, F.plane, (D.fid is NOT NULL) as departed, count(B.bid) as num_booked
	FROM Flight F 
		LEFT JOIN Booking B ON F.fid = B.flight
		LEFT JOIN Departure D ON F.fid = D.fid
	GROUP BY F.fid, D.fid
);


CREATE VIEW FlightBookNRouteNFullnessInfo AS (
	SELECT F.fid, F.route, F.departed, F.plane, R.airline, F.num_booked, P.cap, (F.num_booked::FLOAT / P.cap) as fullness
	FROM FlightBookInfo F 
		JOIN Route R ON F.route = R.flight_num
		JOIN PlaneInfo P ON F.plane = P.pid
);


CREATE VIEW FullnessHistogram AS (
	SELECT airline, route as flight_num,
		count(*) FILTER (WHERE fullness < 0.2) as very_low,
		count(*) FILTER (WHERE fullness >= 0.2 AND fullness < 0.4) as low,
		count(*) FILTER (WHERE fullness >= 0.4 AND fullness < 0.6) as fair,
		count(*) FILTER (WHERE fullness >= 0.6 AND fullness < 0.8) as normal,
		count(*) FILTER (WHERE fullness >= 0.8) as high
	FROM FlightBookNRouteNFullnessInfo F
	GROUP BY route, airline
);


-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q1
	SELECT * FROM FullnessHistogram
