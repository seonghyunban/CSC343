"""CSC343 Assignment 2

=== CSC343 Winter 2025 ===
Department of Computer Science,
University of Toronto

This code is provided solely for the personal and private use of
students taking the CSC343 course at the University of Toronto.
Copying for purposes other than this use is expressly prohibited.
All forms of distribution of this code, whether as given or with
any changes, are expressly prohibited.

Authors: Jacqueline Smith, Marina Tawfik and Akshay Arun Bapat

All of the files in this directory and all subdirectories are:
Copyright (c) 2025

=== Module Description ===

This file contains the AirTravel class and some simple testing functions.
"""
from typing import Optional
from datetime import date, datetime, timedelta
import psycopg2 as pg
import psycopg2.extensions as pg_ext
import os


class AirTravel:
    """A class that can work with data conforming to the schema used in A2.

    === Instance Attributes ===
    connection: connection to a PostgreSQL database of Markus-related
        information.

    Representation invariants:
    - The database to which <connection> holds a reference conforms to the
      schema used in A2.
    """
    connection: Optional[pg_ext.connection]

    def __init__(self) -> None:
        """Initialize this VetClinic instance, with no database connection
        yet.
        """
        self.connection = None

    def connect(self, dbname: str, username: str, password: str) -> bool:
        """Establish a connection to the database <dbname> using the
        username <username> and password <password>, and assign it to the
        instance attribute <connection>. In addition, set the search path
        to AirTravel.

        Return True if the connection was made successfully, False otherwise.
        I.e., do NOT throw an error if making the connection fails.

        >>> a2 = AirTravel()
        >>> # The following example will only work if you change the dbname
        >>> # and password to your own credentials.
        >>> a2.connect("csc343h-bapataks", "bapataks", "")
        True
        >>> # In this example, the connection cannot be made.
        >>> a2.connect("invalid", "nonsense", "incorrect")
        False
        """
        try:
            self.connection = pg.connect(
                dbname=dbname, user=username, password=password,
                options="-c search_path=AirTravel"
            )
            self.connection.set_client_encoding("UTF8")
            return True
        except pg.Error:
            return False

    def disconnect(self) -> bool:
        """Close this instance's connection to the database.

        Return True if closing the connection was successful, False otherwise.
        I.e., do NOT throw an error if closing the connection fails.

        >>> a2 = AirTravel()
        >>> # The following example will only work if you change the dbname
        >>> # and password to your own credentials.
        >>> a2.connect("csc343h-bapataks", "bapataks", "")
        True
        >>> a2.disconnect()
        True
        """
        try:
            if self.connection and not self.connection.closed:
                self.connection.close()
            return True
        except pg.Error:
            return False


    def make_booking(
        self, pid: int, seat: tuple[int, str], fid: int, timestamp: datetime
    ) -> bool:
        """Create a booking for the passenger identified by <pid> for the
        flight identified by <fid>. <seat> is a tuple of the row and letter of
        the seat selected by the passenger. <timestamp> is the timestamp of the
        booking.

        Set the booking's bid to be the maximum current existing bid + 1.
        Set the price paid by the passenger to be the current price recorded
        in FlightPrice for the seating class for <seat>.

        Return True if the booking is successful, and False otherwise i.e.,
        your method should NOT throw an exception.

        A booking is not successful if any of the following is True:
            * <pid> is invalid.
            * <fid> is invalid.
            * <seat> doesn't exist on the plane used by <fid> or is already
              booked.
            * <timestamp> is later than 1 hour before <fid>'s scheduled
              departure.
        """
        
        try:
            with self.connection.cursor() as cursor:

                # Check if passenger exists
                cursor.execute("SELECT COUNT(*) FROM Passenger WHERE pid = %s;", (pid,))
                pid_exists = cursor.fetchone()[0]
                if pid_exists == 0:
                    return False

                # Check if flight exists
                cursor.execute("SELECT COUNT(*) FROM Flight WHERE fid = %s;", (fid,))
                if cursor.fetchone()[0] == 0:
                    return False

                # Get next booking ID
                cursor.execute("SELECT COALESCE(MAX(bid), 0) FROM Booking;")
                bid = cursor.fetchone()[0] + 1

                # Get plane for the flight
                cursor.execute("SELECT plane FROM Flight WHERE fid = %s;", (fid,))
                plane = cursor.fetchone()

                # Get seat ID and class
                cursor.execute(
                    """
                    SELECT sid, class
                    FROM Seat
                    WHERE plane = %s AND row = %s AND letter = %s;
                    """,
                    (plane, seat[0], seat[1])
                )
                seat_info = cursor.fetchone()
                if not seat_info:
                    return False
                sid, seat_class = seat_info

                # Check if seat is already booked
                cursor.execute("SELECT COUNT(*) FROM Booking WHERE seat = %s AND flight = %s;", (sid, fid))
                if cursor.fetchone()[0] > 0:
                    return False

                # Get flight scheduled departure
                cursor.execute("SELECT sched_dept FROM Flight WHERE fid = %s;", (fid,))
                sched_dept = cursor.fetchone()
                if not sched_dept:
                    return False
                sched_dept = sched_dept[0]

                # Check if booking time is too late
                if timestamp > (sched_dept - timedelta(hours=1)):
                    return False

                # Get current price for the seat class
                cursor.execute(
                    "SELECT price FROM FlightPrice WHERE fid = %s AND class = %s;",
                    (fid, seat_class)
                )
                price = cursor.fetchone()
                if not price:
                    return False
                price = price[0]

                # Insert new booking
                cursor.execute(
                    """
                    INSERT INTO Booking (bid, passenger, seat, flight, price, date_time)
                    VALUES (%s, %s, %s, %s, %s, %s);
                    """,
                    (bid, pid, sid, fid, price, timestamp)
                )

                # Commit the transaction
                self.connection.commit()
                return True

        except pg.Error:
            self.connection.rollback()  # Rollback changes if an error occurs
            return False
        


    def find_unreachable_from(self, airport: str) -> Optional[list[str]]:
        """Return a list of unique airport IATA code(s) that are not
        reachable from the airport identified by the IATA code <airport>.
        Don't include <airport> in the result.

        An airport A2 is considered to be reachable from another airport A1 if:
            * There is a route from A1 to A2.
            * There is a route from a third airport A3 to A2, where A3 is
              reachable from A1.

        Note that the above specification uses "route" and not "flight".

        If <airport> is not a valid IATA code, return None i.e., your method
        should NOT throw an exception.
        If <airport> is a valid IATA code, but is reachable from all airports,
        you should return an empty list.
        """
        # TODO: Write the function definition according to the defined criteria
        # NOTE: Check the 'WITH RECURSIVE' clause of Postgres.
        #       You do not have to necessarily use it but it can be helpful.
        try:
            with self.connection.cursor() as cursor:

                # Check if airport exists
                cursor.execute("SELECT COUNT(*) FROM Airport WHERE code = %s;", (airport,))
                if cursor.fetchone()[0] == 0:
                    return None  # Invalid airport code

                # Find reachable airports using WITH RECURSIVE
                cursor.execute("""
                    WITH RECURSIVE Reachable AS (
                        SELECT destination FROM Route WHERE source = %s
                        UNION
                        SELECT R.destination FROM Reachable RE
                        JOIN Route R ON RE.destination = R.source
                    )
                    SELECT DISTINCT destination 
                    FROM Reachable;
                """, (airport,))

                reachable_airports = {row[0] for row in cursor.fetchall()}

                # Get all airports excluding the reachable ones
                cursor.execute("SELECT code FROM Airport WHERE code <> %s;", (airport,))
                all_airports = {row[0] for row in cursor.fetchall()}

                # Compute unreachable airports
                unreachable = sorted(all_airports - reachable_airports)

                return unreachable

        except pg.Error:
            return None  # Ensure we don't crash
        
        

    def reassign_plane(
        self, tail_number: str, start: date, end: date
    ) -> list[int]:
        """Reassign planes to flights scheduled to depart between the
        <start> and <end> dates (inclusive), that are currently using the plane
        identified by <tail_number> as indicated below.

        Consider flights with scheduled departures between <start> and <end>
        days (inclusive) that use the plane <tail_number> i.e., you should
        account for flights departing on <start> and <end>, as well as any day
        in between regardless of the exact time of departure.

        Consider the target flights in order of departure date, giving higher
        priority to flights that are scheduled to depart earlier.

        For each flight, pick a replacement plane that satisfies the following
        criteria:
            * It is not the original plane <tail_number>.
            * The plane must be owned by the same airline as the original
              plane <tail_number>.
            * The plane can't have a flight that overlaps with the current
              flight, accounting for a 2 hours gap between flights i.e.,
              for a flight scheduled from 13:00 to 14:00, you should select a
              plane with no flights in the interval (11:00, 16:00).
            * The plane must have enough seating to satisfy the current number
              of bookings for the flight i.e., if the current flight has 5
              bookings for economy seats, and 10 booking for first class, then
              the replacement plane must have at least 5 economy seats and 10
              first class seats.
        
        From all candidate planes, give priority to planes that have fewer trips
        during <start> to <finish>, and break possible ties by ordering by
        tail_number in ascending order.

        Update the Flight relation accordingly for flights where a replacement
        plane was found, but make sure NOT to make changes for flights where
        a replacement is not available.

        Return a list of the flight ids where a replacement was NOT found.

        Your method should NOT throw an error. For cases such as an empty
        interval or no flights within interval, simply return an empty list.

        Note: You may assume that planes do not have overlapping flights.
        In your implementation, you make sure that this continues to hold
        (as specified above).

        Note: While it does not make sense in real life, we may call your
        method with dates in the past. You may assume however that the flights
        in the range from <start> to <end> have not departed.
        """

        # TODO: Write the function definition according to the defined criteria
        
        try:
            with self.connection.cursor() as cursor:
                
                cursor.execute( 
                    """
                    SELECT fid, sched_dept, sched_arrival
                    FROM Flight
                    WHERE plane = %s 
                        AND DATE(sched_dept) >= %s
                        AND DATE(sched_dept) <= %s
                    ORDER BY sched_dept
                    ;
                    """,
                    (tail_number, start, end))
                target_flights = cursor.fetchall()
                failed_flights = []
                
                for (t_fid, t_sched_depart, t_sched_arrival) in target_flights:

                    cursor.execute(
                        """ 
                        SELECT count(bid) FILTER (WHERE class = 'first') AS first_count,
                            count(bid) FILTER (WHERE class = 'business') AS business_count,
                            count(bid) FILTER (WHERE class = 'economy') AS economy_count
                        FROM Booking B JOIN Seat S ON B.seat = S.sid
                        WHERE B.flight = %s;
                        """,
                        (t_fid,)
                    )
                    first_count, business_count, economy_count = cursor.fetchone()
                    
                    # pin
                    # Step 1: Find planes with no overlapping flights
                    non_overlapping_query = """
                        WITH OverlappingFlights AS (
                            SELECT DISTINCT P.tail_number
                            FROM Flight F 
                            JOIN Plane P ON F.plane = P.tail_number
                            WHERE (F.sched_dept <= %s AND F.sched_arrival >= %s)
                        )
                        SELECT * FROM OverlappingFlights;
                    """
                    cursor.execute(non_overlapping_query, (t_sched_arrival + timedelta(hours=2), t_sched_depart - timedelta(hours=2)))
                    non_overlapping_results = cursor.fetchall()
                    print("Non-Overlapping Flights:", non_overlapping_results)

                    # Step 2: Check planes that meet seat capacity requirements
                    capacity_okay_query = """
                        WITH CapacityOkay AS (
                            SELECT P.tail_number
                            FROM Plane P 
                            JOIN SEAT S ON P.tail_number = S.plane
                            GROUP BY P.tail_number
                            HAVING COUNT(S.sid) FILTER (WHERE S.class = 'first') >= %s
                                AND COUNT(S.sid) FILTER (WHERE S.class = 'business') >= %s
                                AND COUNT(S.sid) FILTER (WHERE S.class = 'economy') >= %s
                        )
                        SELECT * FROM CapacityOkay;
                    """
                    cursor.execute(capacity_okay_query, (first_count, business_count, economy_count))
                    capacity_results = cursor.fetchall()
                    print("Planes with Required Seat Capacity:", capacity_results)
                    # pin
                    
                    cursor.execute(
                        """
                        WITH OverlappingFlights AS (
                            SELECT distinct P.tail_number
                            FROM Flight F JOIN Plane P ON F.plane = P.tail_number
                            WHERE (F.sched_dept <= %s AND F.sched_arrival >= %s)
                        ),
                        CapacityOkay AS (
                        SELECT P.tail_number
                        FROM Plane P JOIN SEAT S ON P.tail_number = S.plane
                        GROUP BY P.tail_number
                        HAVING COUNT(S.sid) FILTER (WHERE S.class = 'first') >= %s
                            AND COUNT(S.sid) FILTER (WHERE S.class = 'business') >= %s
                            AND COUNT(S.sid) FILTER (WHERE S.class = 'economy') >= %s
                        )
                        SELECT P.tail_number
                        FROM Plane P 
                            LEFT JOIN Flight F ON P.tail_number = F.plane
                        WHERE P.tail_number <> %s 
                            AND P.airline IN (SELECT airline FROM Plane WHERE tail_number = %s)
                            AND P.tail_number NOT IN (SELECT * FROM OverlappingFlights)
                            AND P.tail_number IN (SELECT * FROM CapacityOkay)
                        Group BY P.tail_number
                        ORDER BY COUNT(DISTINCT F.fid) FILTER (WHERE DATE(sched_dept) BETWEEN %s AND %s),
                        P.tail_number
                        
                        """,
                        (t_sched_arrival + timedelta(hours=2), t_sched_depart - timedelta(hours=2),
                         first_count, business_count, economy_count,
                         tail_number, tail_number, start, end)
                    )
                    new_plane = cursor.fetchone()
                    
                    if new_plane:
                        cursor.execute(
                            """
                            UPDATE Flight
                            SET plane = %s
                            WHERE fid = %s;
                            """,
                            (new_plane, t_fid)
                        )
                    else:
                        failed_flights.append(t_fid)
                    
                self.connection.commit()
                return failed_flights
        
        except pg.Error as e:
            print(e)
            self.connection.rollback()
            return []

        
def setup(
        dbname: str, username: str, password: str, schema_path: str,
        data_path: str
) -> None:
    """Set up the testing environment for the database <dbname> using the
    username <username> and password <password> by importing the schema file
    at <schema_path> and the file containing the data at <data_path>.

    <schema_path> and <data_path> are the relative/absolute paths to the files
    containing the schema and the data respectively.
    """
    connection, cursor, schema_file, data_file = None, None, None, None
    try:
        connection = pg.connect(
            dbname=dbname, user=username, password=password,
            options="-c search_path=AirTravel"
        )
        connection.set_client_encoding("UTF8")
        cursor = connection.cursor()

        with open(schema_path, "r") as schema_file:
            cursor.execute(schema_file.read())

        with open(data_path, "r") as info_file:
            for line in info_file:
                line_elems = line.split()
                table_name = line_elems[1].lower()
                file_path = line_elems[3].strip("'")
                with open(file_path, "r", encoding='utf-8') as data_file:
                    cursor.copy_from(data_file, table_name, sep=",")
        connection.commit()
    except Exception as ex:
        connection.rollback()
        raise Exception(f"Couldn't set up environment for tests: \n{ex}")
    finally:
        if cursor and not cursor.closed:
            cursor.close()
        if connection and not connection.closed:
            connection.close()


def setup_custom(
        dbname: str, username: str, password: str, schema_path: str,
        data_path: str
) -> None:
    """Set up the testing environment for the database <dbname> using the
    username <username> and password <password> by importing the schema file
    at <schema_path> and the file containing the data at <data_path>.

    <schema_path> and <data_path> are the relative/absolute paths to the files
    containing the schema and the data respectively.
    """
    connection, cursor, schema_file, data_file = None, None, None, None
    try:
        connection = pg.connect(
            dbname=dbname, user=username, password=password,
            options="-c search_path=AirTravel"
        )
        connection.set_client_encoding("UTF8")
        cursor = connection.cursor()

        with open(schema_path, "r") as schema_file:
            cursor.execute(schema_file.read())

        with open(data_path, 'r', encoding='utf-8') as f:
            sql_script = f.read()
            try:
                cursor.execute(sql_script)
                connection.commit()
            except pg.Error as ex:
                connection.rollback()
                print(f"Error executing {data_path}:\n{ex}")
                
    
        connection.commit()
    except Exception as ex:
        connection.rollback()
        raise Exception(f"Couldn't set up environment for tests: \n{ex}")
    finally:
        if cursor and not cursor.closed:
            cursor.close()
        if connection and not connection.closed:
            connection.close()

def test_basics() -> None:
    """Test basic aspects of the A2 methods.
    """
    # TODO: Change the values of the following variables to connect to your
    #  own database:
    dbname = "csc343"
    user = "csc343"
    password = "Qksalsdn98!"
    
    # The following uses the relative paths to the schema file and the data file
    # we have provided. For your own tests, you will want to make your own data
    # files to use for testing.
    schema_file = "./a2_airtravel_schema.ddl"
    data_file = "./populate_data.sql"
    a2 = AirTravel()
    try:
        connected = a2.connect(dbname, user, password)
        print("Current Working Directory:", os.getcwd())
        # The following is an assert statement. It checks that the value for
        # connected is True. The message after the comma will be printed if
        # that is not the case (that is, if connected is False).
        # Use the same notation throughout your testing.
        assert connected, f"[Connect] Expected True | Got {connected}."

        # The following function call will set up the testing environment by
        # loading a fresh copy of the schema and the sample data we have
        # provided into your database. You can create more sample data files
        # and call the same function to load them into your database.
        setup(dbname, user, password, schema_file, data_file)

        # [TODO] Note: these results are for the provided generated data -
        #   Remember to change if you end up modifying the data.

        # ----------------------- Testing make_booking ----------------------- #

        # Note: These results assume that the instance has already been
        # populated with the provided data e.g., using the setup function.
        # You will also need to manually check the contents of your instance to
        # make sure it was updated correctly.

        # Invalid pid
        expected = False
        booked = a2.make_booking(39, (6, 'A'), 8, datetime(2025, 1, 15, 10, 0))
        assert booked == expected, \
            f"[make_booking] Expected {expected} - Got {booked}."

        # Valid booking
        expected = True
        booked = a2.make_booking(17, (6, 'A'), 8, datetime(2025, 1, 15, 10, 0))
        assert booked == expected, \
            f"[make_booking] Expected {expected} - Got {booked}."

        # Seat is already occupied
        expected = False
        booked = a2.make_booking(7, (6, 'A'), 8, datetime(2025, 3, 2, 10, 0))
        assert booked == expected, \
            f"[make_booking] Expected {expected} - Got {booked}"

        # ------------------ Testing find_unreachable_from ------------------- #

        # Note: These results assume that the instance has already been
        # populated with the provided data e.g., using the setup function.
        # Since we run all tests in the same function, the instance has been
        # changed by the above tests.

        # invalid IATA code.
        expected = None
        unreachable = a2.find_unreachable_from("ABC")
        assert unreachable is expected, \
            f"[find_unreachable_from] Expected {expected} - Got {unreachable}"

        # valid IATA code, not reachable from some airports.
        # Note that we use sorted, since we are not enforcing a specific
        # order on the return value.
        expected = sorted([
            "YTZ", "ATL", "LAX", "DFW", "DEN", "JFK",
            "SFO", "SEA", "LAS", "MIA", "AMS", "DXB", "SIN",
            "HKG", "ICN", "SYD", "PEK", "DEL", "GRU", "MEX", "JNB", "BKK",
            "KUL", "IST"
        ])
        unreachable = sorted(a2.find_unreachable_from("YYZ"))
        assert unreachable == expected, \
            f"[find_unreachable_from] Expected {expected} - Got {unreachable}"

        # ---------------------- Testing reassign_plane ---------------------- #

        # Note: These results assume that the instance has already been
        # populated with the provided data e.g., using the setup function.
        # Since we run all tests in the same function, the instance has been
        # changed by the above tests.
        # Note that you will still need to inspect the database to ensure that
        # the changes are reflected there.

        # Two flights to re-schedule.
        expected = []
        unscheduled = sorted(a2.reassign_plane(
            'D84KL', date(2024, 1, 1), date(2024, 8, 12)))
        assert unscheduled == expected, \
            f"[reassign_plane] Expected {expected} - Got {unscheduled}"
            
        expected = [19, 20]
        unscheduled = sorted(a2.reassign_plane(
            'D52RM', date(2024, 8, 8), date(2024, 9, 22)))
        assert unscheduled == expected, \
            f"[reassign_plane] Expected {expected} - Got {unscheduled}"
        print("test basic succesful")
    finally:
        a2.disconnect()



def test_custom() -> None:
    """Test basic aspects of the A2 methods.
    """
    # TODO: Change the values of the following variables to connect to your
    #  own database:
    dbname = "csc343"
    user = "csc343"
    password = "Qksalsdn98!"
    
    # The following uses the relative paths to the schema file and the data file
    # we have provided. For your own tests, you will want to make your own data
    # files to use for testing.
    schema_file = "./a2_airtravel_schema.ddl"
    data_file = "./populate_e3_test.sql"
    a2 = AirTravel()
    try:
        connected = a2.connect(dbname, user, password)
        print("Current Working Directory:", os.getcwd())
        # The following is an assert statement. It checks that the value for
        # connected is True. The message after the comma will be printed if
        # that is not the case (that is, if connected is False).
        # Use the same notation throughout your testing.
        assert connected, f"[Connect] Expected True | Got {connected}."

        # The following function call will set up the testing environment by
        # loading a fresh copy of the schema and the sample data we have
        # provided into your database. You can create more sample data files
        # and call the same function to load them into your database.
        setup_custom(dbname, user, password, schema_file, data_file)

        # [TODO] Note: these results are for the provided generated data -
        #   Remember to change if you end up modifying the data.

        # ----------------------- Testing make_booking ----------------------- #

        # # Note: These results assume that the instance has already been
        # # populated with the provided data e.g., using the setup function.
        # # You will also need to manually check the contents of your instance to
        # # make sure it was updated correctly.

        # # Invalid pid
        # expected = False
        # booked = a2.make_booking(39, (6, 'A'), 8, datetime(2025, 1, 15, 10, 0))
        # assert booked == expected, \
        #     f"[make_booking] Expected {expected} - Got {booked}."

        # # Valid booking
        # expected = True
        # booked = a2.make_booking(17, (6, 'A'), 8, datetime(2025, 1, 15, 10, 0))
        # assert booked == expected, \
        #     f"[make_booking] Expected {expected} - Got {booked}."

        # # Seat is already occupied
        # expected = False
        # booked = a2.make_booking(7, (6, 'A'), 8, datetime(2025, 3, 2, 10, 0))
        # assert booked == expected, \
        #     f"[make_booking] Expected {expected} - Got {booked}"

        # ------------------ Testing find_unreachable_from ------------------- #

        # # Note: These results assume that the instance has already been
        # # populated with the provided data e.g., using the setup function.
        # # Since we run all tests in the same function, the instance has been
        # # changed by the above tests.

        # # invalid IATA code.
        # expected = None
        # unreachable = a2.find_unreachable_from("ABC")
        # assert unreachable is expected, \
        #     f"[find_unreachable_from] Expected {expected} - Got {unreachable}"

        # # valid IATA code, not reachable from some airports.
        # # Note that we use sorted, since we are not enforcing a specific
        # # order on the return value.
        # expected = sorted([
        #     "YTZ", "ATL", "LAX", "DFW", "DEN", "JFK",
        #     "SFO", "SEA", "LAS", "MIA", "AMS", "DXB", "SIN",
        #     "HKG", "ICN", "SYD", "PEK", "DEL", "GRU", "MEX", "JNB", "BKK",
        #     "KUL", "IST"
        # ])
        # unreachable = sorted(a2.find_unreachable_from("YYZ"))
        # assert unreachable == expected, \
        #     f"[find_unreachable_from] Expected {expected} - Got {unreachable}"

        # ---------------------- Testing reassign_plane ---------------------- #
            
        expected = []
        unscheduled = sorted(a2.reassign_plane(
            '1', date(2025, 6, 8), date(2025, 9, 1)))
        assert unscheduled == expected, \
            f"[reassign_plane] Expected {expected} - Got {unscheduled}"
        print("test custom succesful")
    finally:
        
        a2.disconnect()


if __name__ == "__main__":
    # Un comment-out the next two lines if you would like to run the doctest
    # examples (see ">>>" in the methods connect and disconnect)
    # import doctest
    # doctest.testmod()
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    # TODO: Put your testing code here, or call testing functions such as
    #   this one which has been provided as a sample for you to write more tests:
    test_basics()
    test_custom()
