CREATE VIEW NonOverlappingFlights AS (
    SELECT distinct P.tail_number
    FROM Flight F JOIN Plane P ON F.plane = P.tail_number
    WHERE NOT (F.sched_dept <= '2025-06-08' AND F.sched_arrival >= '2025-09-01')
);


CREATE VIEW CapacityOkay AS (
    SELECT P.tail_number
    FROM Plane P JOIN SEAT S ON P.tail_number = S.plane
    GROUP BY P.tail_number
    HAVING COUNT(S.sid) FILTER (WHERE S.class = 'first') >= %s
        AND COUNT(S.sid) FILTER (WHERE S.class = 'business') >= %s
        AND COUNT(S.sid) FILTER (WHERE S.class = 'economy') >= %s
);

SELECT P.tail_number
FROM Plane P 
    JOIN NonOverlappingFlights O ON P.tail_number = O.tail_number
    JOIN CapacityOkay C ON P.tail_number = C.tail_number
    JOIN Flight F ON P.tail_number = F.plane
WHERE P.tail_number <> %s 
    AND P.airline IN (SELECT airline FROM Plane WHERE tail_number = %s)
Group BY P.tail_number
    ORDER BY COUNT(DISTINCT F.fid) FILTER (WHERE DATE(sched_dept) BETWEEN %s AND %s),
    P.tail_number
                    