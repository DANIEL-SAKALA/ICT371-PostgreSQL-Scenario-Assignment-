-- Scenario 3 Student Hostel Room Allocation 


-- ============================================================
-- PART 1: CREATE TABLES
-- ============================================================

-- Create hostel rooms table

CREATE TABLE hostel_rooms (
    room_id SERIAL PRIMARY KEY,
    room_name VARCHAR(20),
    available_spaces INT
);


-- Create allocations table

CREATE TABLE allocations (
    allocation_id SERIAL PRIMARY KEY,
    student_number VARCHAR(20),
    room_id INT,
    allocation_status VARCHAR(20) DEFAULT 'Allocated',
    allocation_date DATE DEFAULT CURRENT_DATE,
    FOREIGN KEY (room_id) REFERENCES hostel_rooms(room_id)
);


-- Add rooms

INSERT INTO hostel_rooms (room_name, available_spaces)
VALUES
('Room A', 2),
('Room B', 1),
('Room C', 3);


-- Show rooms

SELECT * FROM hostel_rooms;



-- ============================================================
-- PART 2: IF ELSIF ELSE
-- ============================================================

DO $$
DECLARE
    v_spaces INT;
BEGIN

    SELECT available_spaces
    INTO v_spaces
    FROM hostel_rooms
    WHERE room_id = 1;

    IF v_spaces = 0 THEN
        RAISE NOTICE 'Room is full';

    ELSIF v_spaces = 1 THEN
        RAISE NOTICE 'One space left';

    ELSE
        RAISE NOTICE 'Several spaces available';

    END IF;

END $$;



-- ============================================================
-- PART 3: LOOPS
-- ============================================================

DO $$
DECLARE
    v_day INT := 1;
BEGIN

    -- Inspection days

    WHILE v_day <= 3 LOOP

        RAISE NOTICE 'Inspection Day %', v_day;

        v_day := v_day + 1;

    END LOOP;


    -- Room checks

    FOR i IN 1..3 LOOP

        RAISE NOTICE 'Room Check %', i;

    END LOOP;

END $$;



-- ============================================================
-- PART 4: ALLOCATE ROOM
-- ============================================================

-- Create procedure

CREATE OR REPLACE PROCEDURE allocate_room(
    p_room_id INT,
    p_student_number VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_spaces INT;
BEGIN

    -- Check student number

    IF TRIM(p_student_number) = '' THEN
        RAISE EXCEPTION 'Student number cannot be blank.';
    END IF;

    -- Get available spaces

    SELECT available_spaces
    INTO v_spaces
    FROM hostel_rooms
    WHERE room_id = p_room_id;

    -- Check if room exists

    IF NOT FOUND THEN

        RAISE NOTICE 'Room does not exist.';
        RETURN;

    END IF;

    -- Check available space

    IF v_spaces <= 0 THEN

        RAISE NOTICE 'Room is full.';
        RETURN;

    END IF;

    -- Reduce available spaces

    UPDATE hostel_rooms
    SET available_spaces = available_spaces - 1
    WHERE room_id = p_room_id;

    -- Record allocation

    INSERT INTO allocations(
        student_number,
        room_id,
        allocation_status
    )
    VALUES(
        p_student_number,
        p_room_id,
        'Allocated'
    );

    -- Show message

    RAISE NOTICE 'Room allocated successfully.';

END;
$$;



-- ============================================================
-- PART 5: TEST ALLOCATIONS
-- ============================================================

-- First allocation

CALL allocate_room(1, 'STU001');

-- Second allocation

CALL allocate_room(2, 'STU002');

-- Fill Room B

CALL allocate_room(2, 'STU003');

-- Try allocating to full room

CALL allocate_room(2, 'STU004');


-- ============================================================
-- SHOW RESULTS
-- ============================================================

-- Show rooms

SELECT
    room_id,
    room_name,
    available_spaces
FROM hostel_rooms
ORDER BY room_id;


-- Show allocations

SELECT
    allocation_id,
    student_number,
    room_id,
    allocation_status
FROM allocations
ORDER BY allocation_id;



-- ============================================================
-- PART 6: CHECK OUT
-- ============================================================

-- Create procedure

CREATE OR REPLACE PROCEDURE check_out(
    p_allocation_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_room_id INT;
    v_status VARCHAR(20);
BEGIN

    -- Get allocation details

    SELECT room_id, allocation_status
    INTO v_room_id, v_status
    FROM allocations
    WHERE allocation_id = p_allocation_id;

    -- Check if allocation exists

    IF NOT FOUND THEN

        RAISE NOTICE 'Allocation does not exist.';
        RETURN;

    END IF;

    -- Check if already completed

    IF v_status = 'Completed' THEN

        RAISE NOTICE 'Student already checked out.';
        RETURN;

    END IF;

    -- Add back one space

    UPDATE hostel_rooms
    SET available_spaces = available_spaces + 1
    WHERE room_id = v_room_id;

    -- Update allocation

    UPDATE allocations
    SET allocation_status = 'Completed'
    WHERE allocation_id = p_allocation_id;

    -- Message

    RAISE NOTICE 'Check out successful.';

END;
$$;


-- ============================================================
-- TEST CHECK OUT
-- ============================================================

-- Check out allocation 1

CALL check_out(1);

-- Try again

CALL check_out(1);



-- Show rooms

SELECT
    room_id,
    room_name,
    available_spaces
FROM hostel_rooms
ORDER BY room_id;


-- Show allocations

SELECT
    allocation_id,
    student_number,
    room_id,
    allocation_status
FROM allocations
ORDER BY allocation_id;



-- ============================================================
-- PART 7: EXPLICIT CURSOR
-- ============================================================

-- Show full or nearly full rooms

DO $$
DECLARE

    room_cursor CURSOR FOR
        SELECT room_id, room_name, available_spaces
        FROM hostel_rooms
        WHERE available_spaces <= 1;

    v_room_id INT;
    v_room_name VARCHAR(20);
    v_spaces INT;

BEGIN

    -- Open cursor

    OPEN room_cursor;

    LOOP

        -- Get room details

        FETCH room_cursor
        INTO v_room_id, v_room_name, v_spaces;

        -- Stop if no more rooms

        EXIT WHEN NOT FOUND;

        -- Display room

        RAISE NOTICE
        'Room ID: %, Room: %, Available Spaces: %',
        v_room_id,
        v_room_name,
        v_spaces;

    END LOOP;

    -- Close cursor

    CLOSE room_cursor;

END $$;



-- ============================================================
-- PART 8: EXCEPTION HANDLING
-- ============================================================

-- Try a blank student number

DO $$
BEGIN

    CALL allocate_room(1, '');

EXCEPTION
    WHEN OTHERS THEN

        -- Show error

        RAISE NOTICE 'Error: %', SQLERRM;

END $$;




-- ============================================================
-- PART 9: FINAL RESULTS
-- ============================================================

-- Show rooms

SELECT
    room_id,
    room_name,
    available_spaces
FROM hostel_rooms
ORDER BY room_id;


-- Show allocations

SELECT
    allocation_id,
    student_number,
    room_id,
    allocation_status
FROM allocations
ORDER BY allocation_id;