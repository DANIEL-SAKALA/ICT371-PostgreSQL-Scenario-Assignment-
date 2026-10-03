--Scenario 4 Campus Clinic Medicine Dispensing 

-- ============================================================
-- PART 1: CREATE TABLES
-- ============================================================

-- Medicines table

CREATE TABLE medicines (
    medicine_id SERIAL PRIMARY KEY,
    medicine_name VARCHAR(50),
    stock_quantity INT
);


-- Dispensing records table

CREATE TABLE dispensing_records (
    record_id SERIAL PRIMARY KEY,
    student_number VARCHAR(20),
    medicine_id INT,
    quantity INT,
    dispensing_status VARCHAR(20) DEFAULT 'Dispensed',
    dispensing_date DATE DEFAULT CURRENT_DATE,
    FOREIGN KEY (medicine_id) REFERENCES medicines(medicine_id)
);


-- Add medicines

INSERT INTO medicines (medicine_name, stock_quantity)
VALUES
('Paracetamol', 10),
('Amoxicillin', 5),
('Ibuprofen', 8);


-- Show medicines

SELECT * FROM medicines;


-- ============================================================
-- PART 2: IF ELSIF ELSE
-- ============================================================

DO $$
DECLARE
    v_stock INT;
BEGIN

    SELECT stock_quantity
    INTO v_stock
    FROM medicines
    WHERE medicine_id = 2;

    IF v_stock = 0 THEN

        RAISE NOTICE 'Medicine is out of stock';

    ELSIF v_stock <= 5 THEN

        RAISE NOTICE 'Medicine is low on stock';

    ELSE

        RAISE NOTICE 'Medicine is sufficiently stocked';

    END IF;

END $$;



-- ============================================================
-- PART 3: LOOPS
-- ============================================================

DO $$
DECLARE
    v_day INT := 1;
BEGIN

    -- Stock review days

    WHILE v_day <= 3 LOOP

        RAISE NOTICE 'Stock Review Day %', v_day;

        v_day := v_day + 1;

    END LOOP;

    -- Shelf inspections

    FOR i IN 1..3 LOOP

        RAISE NOTICE 'Shelf Inspection %', i;

    END LOOP;

END $$;



-- ============================================================
-- PART 4: DISPENSE MEDICINE
-- ============================================================

CREATE OR REPLACE PROCEDURE dispense_medicine(
    p_medicine_id INT,
    p_student_number VARCHAR,
    p_quantity INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_stock INT;
BEGIN

    -- Check quantity

    IF p_quantity <= 0 THEN

        RAISE EXCEPTION
        'Invalid quantity. Quantity must be greater than zero.';

    END IF;

    -- Get stock

    SELECT stock_quantity
    INTO v_stock
    FROM medicines
    WHERE medicine_id = p_medicine_id;

    -- Check stock

    IF v_stock < p_quantity THEN

        RAISE NOTICE 'Not enough stock.';
        RETURN;

    END IF;

    -- Reduce stock

    UPDATE medicines
    SET stock_quantity = stock_quantity - p_quantity
    WHERE medicine_id = p_medicine_id;

    -- Record dispensing

    INSERT INTO dispensing_records(
        student_number,
        medicine_id,
        quantity
    )
    VALUES(
        p_student_number,
        p_medicine_id,
        p_quantity
    );

    RAISE NOTICE 'Medicine dispensed successfully.';

END;
$$;




-- ============================================================
-- PART 5: TEST DISPENSING
-- ============================================================

-- Valid dispensing

CALL dispense_medicine(1, 'STU001', 3);

-- Valid dispensing

CALL dispense_medicine(2, 'STU002', 2);

-- Exceeds stock

CALL dispense_medicine(2, 'STU003', 10);


-- Show medicines

SELECT
    medicine_id,
    medicine_name,
    stock_quantity
FROM medicines
ORDER BY medicine_id;


-- Show records

SELECT
    record_id,
    student_number,
    medicine_id,
    quantity,
    dispensing_status
FROM dispensing_records
ORDER BY record_id;



-- ============================================================
-- PART 6: REVERSE DISPENSING
-- ============================================================

CREATE OR REPLACE PROCEDURE reverse_dispensing(
    p_record_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_medicine_id INT;
    v_quantity INT;
    v_status VARCHAR(20);
BEGIN

    -- Get record

    SELECT medicine_id,
           quantity,
           dispensing_status
    INTO v_medicine_id,
         v_quantity,
         v_status
    FROM dispensing_records
    WHERE record_id = p_record_id;

    -- Check if already reversed

    IF v_status = 'Reversed' THEN

        RAISE NOTICE
        'This record has already been reversed.';
        RETURN;

    END IF;

    -- Restore stock

    UPDATE medicines
    SET stock_quantity = stock_quantity + v_quantity
    WHERE medicine_id = v_medicine_id;

    -- Update record

    UPDATE dispensing_records
    SET dispensing_status = 'Reversed'
    WHERE record_id = p_record_id;

    RAISE NOTICE
    'Dispensing reversed successfully.';

END;
$$;


-- First reversal

CALL reverse_dispensing(1);

-- Second reversal

CALL reverse_dispensing(1);



-- ============================================================
-- PART 7: EXPLICIT CURSOR
-- ============================================================

DO $$
DECLARE

    medicine_cursor CURSOR FOR
        SELECT medicine_id,
               medicine_name,
               stock_quantity
        FROM medicines
        WHERE stock_quantity <= 5;

    v_id INT;
    v_name VARCHAR(50);
    v_stock INT;

BEGIN

    OPEN medicine_cursor;

    LOOP

        FETCH medicine_cursor
        INTO v_id, v_name, v_stock;

        EXIT WHEN NOT FOUND;

        RAISE NOTICE
        'Medicine ID: %, Name: %, Stock: %',
        v_id,
        v_name,
        v_stock;

    END LOOP;

    CLOSE medicine_cursor;

END $$;



-- ============================================================
-- PART 8: EXCEPTION HANDLING
-- ============================================================

DO $$
BEGIN

    CALL dispense_medicine(1, 'STU004', -2);

EXCEPTION
    WHEN OTHERS THEN

        RAISE NOTICE
        'Error: %',
        SQLERRM;

END $$;




-- ============================================================
-- PART 9: FINAL RESULTS
-- ============================================================

-- Show medicines

SELECT
    medicine_id,
    medicine_name,
    stock_quantity
FROM medicines
ORDER BY medicine_id;


-- Show dispensing records

SELECT
    record_id,
    student_number,
    medicine_id,
    quantity,
    dispensing_status
FROM dispensing_records
ORDER BY record_id;