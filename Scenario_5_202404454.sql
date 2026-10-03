--Scenario 5 Engineering Workshop Tool Loans 

-- ============================================================
-- PART 1: CREATE TABLES
-- ============================================================

-- Tools table

CREATE TABLE tools (
    tool_id SERIAL PRIMARY KEY,
    tool_name VARCHAR(50),
    available_quantity INT
);

-- Tool loans table

CREATE TABLE tool_loans (
    loan_id SERIAL PRIMARY KEY,
    student_number VARCHAR(20),
    tool_id INT,
    quantity INT,
    loan_status VARCHAR(20) DEFAULT 'Borrowed',
    loan_date DATE DEFAULT CURRENT_DATE,
    FOREIGN KEY (tool_id) REFERENCES tools(tool_id)
);

-- Add tools

INSERT INTO tools (tool_name, available_quantity)
VALUES
('Hammer', 10),
('Screwdriver Set', 5),
('Spanner', 8);

-- Show tools

SELECT * FROM tools;



-- ============================================================
-- PART 2: IF ELSIF ELSE
-- ============================================================

DO $$
DECLARE
    v_quantity INT;
BEGIN

    SELECT available_quantity
    INTO v_quantity
    FROM tools
    WHERE tool_id = 2;

    IF v_quantity = 0 THEN

        RAISE NOTICE 'Tool is unavailable';

    ELSIF v_quantity <= 5 THEN

        RAISE NOTICE 'Tool is low on stock';

    ELSE

        RAISE NOTICE 'Tool is readily available';

    END IF;

END $$;



-- ============================================================
-- PART 3: LOOPS
-- ============================================================

DO $$
DECLARE
    v_day INT := 1;
BEGIN

    -- Safety reminders

    WHILE v_day <= 3 LOOP

        RAISE NOTICE 'Safety Reminder %', v_day;

        v_day := v_day + 1;

    END LOOP;

    -- Tool inspections

    FOR i IN 1..3 LOOP

        RAISE NOTICE 'Tool Inspection %', i;

    END LOOP;

END $$;



-- ============================================================
-- PART 4: ISSUE TOOL
-- ============================================================

CREATE OR REPLACE PROCEDURE issue_tool(
    p_tool_id INT,
    p_student_number VARCHAR,
    p_quantity INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_quantity INT;
BEGIN

    -- Check quantity

    IF p_quantity <= 0 THEN

        RAISE EXCEPTION
        'Invalid quantity. Quantity must be greater than zero.';

    END IF;

    -- Get available quantity

    SELECT available_quantity
    INTO v_quantity
    FROM tools
    WHERE tool_id = p_tool_id;

    -- Check stock

    IF v_quantity < p_quantity THEN

        RAISE NOTICE 'Not enough tools available.';
        RETURN;

    END IF;

    -- Reduce quantity

    UPDATE tools
    SET available_quantity = available_quantity - p_quantity
    WHERE tool_id = p_tool_id;

    -- Record loan

    INSERT INTO tool_loans(
        student_number,
        tool_id,
        quantity
    )
    VALUES(
        p_student_number,
        p_tool_id,
        p_quantity
    );

    RAISE NOTICE 'Tool loan recorded successfully.';

END;
$$;




-- ============================================================
-- PART 5: TEST TOOL LOANS
-- ============================================================

-- First loan

CALL issue_tool(1, 'STU001', 3);

-- Second loan

CALL issue_tool(2, 'STU002', 2);

-- Exceeds stock

CALL issue_tool(2, 'STU003', 10);

-- Show tools

SELECT
    tool_id,
    tool_name,
    available_quantity
FROM tools
ORDER BY tool_id;

-- Show tool loans

SELECT
    loan_id,
    student_number,
    tool_id,
    quantity,
    loan_status
FROM tool_loans
ORDER BY loan_id;



-- ============================================================
-- PART 6: RETURN TOOL
-- ============================================================

CREATE OR REPLACE PROCEDURE return_tool(
    p_loan_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_tool_id INT;
    v_quantity INT;
    v_status VARCHAR(20);
BEGIN

    -- Get loan details

    SELECT tool_id, quantity, loan_status
    INTO v_tool_id, v_quantity, v_status
    FROM tool_loans
    WHERE loan_id = p_loan_id;

    -- Check if already returned

    IF v_status = 'Returned' THEN

        RAISE NOTICE 'Tool already returned.';
        RETURN;

    END IF;

    -- Restore stock

    UPDATE tools
    SET available_quantity = available_quantity + v_quantity
    WHERE tool_id = v_tool_id;

    -- Update loan

    UPDATE tool_loans
    SET loan_status = 'Returned'
    WHERE loan_id = p_loan_id;

    RAISE NOTICE 'Tool returned successfully.';

END;
$$;

-- Return loan 1

CALL return_tool(1);

-- Try again

CALL return_tool(1);



-- ============================================================
-- PART 7: EXPLICIT CURSOR
-- ============================================================

DO $$
DECLARE

    tool_cursor CURSOR FOR
        SELECT tool_id, tool_name, available_quantity
        FROM tools
        WHERE available_quantity <= 5;

    v_tool_id INT;
    v_tool_name VARCHAR(50);
    v_quantity INT;

BEGIN

    OPEN tool_cursor;

    LOOP

        FETCH tool_cursor
        INTO v_tool_id, v_tool_name, v_quantity;

        EXIT WHEN NOT FOUND;

        RAISE NOTICE
        'Tool ID: %, Tool: %, Quantity: %',
        v_tool_id,
        v_tool_name,
        v_quantity;

    END LOOP;

    CLOSE tool_cursor;

END $$;



-- ============================================================
-- PART 8: EXCEPTION HANDLING
-- ============================================================

DO $$
BEGIN

    CALL issue_tool(1, 'STU004', 0);

EXCEPTION
    WHEN OTHERS THEN

        RAISE NOTICE
        'Error: %',
        SQLERRM;

END $$;




-- ============================================================
-- PART 9: FINAL RESULTS
-- ============================================================

-- Show tools

SELECT
    tool_id,
    tool_name,
    available_quantity
FROM tools
ORDER BY tool_id;

-- Show tool loans

SELECT
    loan_id,
    student_number,
    tool_id,
    quantity,
    loan_status
FROM tool_loans
ORDER BY loan_id;



