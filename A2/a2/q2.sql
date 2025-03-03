-- Airport type

-- You must not change the next 3 lines or the table or type definition.
SET SEARCH_PATH TO AirTravel;
DROP TABLE IF EXISTS q2 CASCADE;
DROP TYPE IF EXISTS AirportType CASCADE;

CREATE TYPE AirportType AS ENUM (
	'heavy-inbound traffic', 
	'heavy-outbound traffic', 
	'hub',
	'N/A'
);

CREATE TABLE q2 (
    code CHAR(3) NOT NULL,
    name TEXT NOT NULL,
	category AirportType NOT NULL,
	inbound_traffic INT NOT NULL,
	outbound_traffic INT NOT NULL
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
-- If you do not define any views, you can delete the lines about views.
DROP VIEW IF EXISTS intermediate_step CASCADE;
-- Define views for your intermediate steps here:

DROP VIEW IF EXISTS InboundAirport CASCADE;
CREATE VIEW InboundAirport AS (
	SELECT A.code, A.name, F.fid, F.sched_arrival, 
	EXTRACT(YEAR FROM F.sched_arrival) as year,
	EXTRACT(MONTH FROM F.sched_arrival) as month
	FROM Flight F
		JOIN Route R ON F.route = R.flight_num
		RIGHT JOIN Airport A ON R.destination = A.code
	ORDER BY A.code
);

DROP VIEW IF EXISTS OutboundAirport CASCADE;
CREATE VIEW OutboundAirport AS (
	SELECT A.code, A.name, F.fid, F.sched_dept, 
	EXTRACT(YEAR FROM F.sched_dept) as year,
	EXTRACT(MONTH FROM F.sched_dept) as month
	FROM Flight F
		JOIN Route R ON F.route = R.flight_num
		RIGHT JOIN Airport A ON R.source = A.code
	ORDER BY A.code
);

DROP VIEW IF EXISTS InboundTraffic CASCADE;
CREATE VIEW InboundTraffic AS (
	SELECT code, name, count(fid) as inbound_traffic, year, month
	FROM InboundAirport
	GROUP BY code, name, year, month
	ORDER BY code, year, month
);

DROP VIEW IF EXISTS OutboundTraffic CASCADE;
CREATE VIEW OutboundTraffic AS (
	SELECT code, name, count(fid) as outbound_traffic, year, month
	FROM OutboundAirport
	GROUP BY code, name, year, month
	ORDER BY code, year, month
);

DROP VIEW IF EXISTS InboundTrafficAverage CASCADE;
CREATE VIEW InboundTrafficAverage AS (
	SELECT code, name, avg(inbound_traffic) as inbound_traffic, sum(inbound_traffic) as total_inbound_traffic
	FROM InboundTraffic
	GROUP BY code, name
);

DROP VIEW IF EXISTS OutboundTrafficAverage CASCADE;
CREATE VIEW OutboundTrafficAverage AS (
	SELECT code, name, avg(outbound_traffic) as outbound_traffic, sum(outbound_traffic) as total_outbound_traffic
	FROM OutboundTraffic
	GROUP BY code, name
);

DROP VIEW IF EXISTS InboundHeavy CASCADE;
CREATE VIEW InboundHeavy AS (
	SELECT code, name, 
	(inbound_traffic > (SELECT 0.75 * avg(inbound_traffic) as inbound_category FROM InboundTraffic)) as inbound_heavy_traffic,
	total_inbound_traffic
	FROM InboundTrafficAverage
);

DROP VIEW IF EXISTS OutboundHeavy CASCADE;
CREATE VIEW OutboundHeavy AS (
	SELECT code, name, 
	(outbound_traffic > (SELECT 0.75 * avg(outbound_traffic) as outbound_category FROM OutboundTraffic)) as outbound_heavy_traffic,
	total_outbound_traffic
	FROM OutboundTrafficAverage
);

CREATE VIEW AirportClassification AS (
	SELECT InboundHeavy.code, InboundHeavy.name, 
		(CASE 
			WHEN InboundHeavy.inbound_heavy_traffic = TRUE AND OutboundHeavy.outbound_heavy_traffic THEN 'hub':: AirportType
			WHEN InboundHeavy.inbound_heavy_traffic = TRUE THEN 'heavy-inbound traffic':: AirportType
			WHEN OutboundHeavy.outbound_heavy_traffic = TRUE THEN 'heavy-outbound traffic':: AirportType
			ELSE 'N/A':: AirportType
		END) as category,
		InboundHeavy.total_inbound_traffic as inbound_traffic, 
		OutboundHeavy.total_outbound_traffic as outbound_traffic
	FROM InboundHeavy JOIN OutboundHeavy ON InboundHeavy.code = OutboundHeavy.code
);

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q2
	SELECT * FROM AirportClassification
