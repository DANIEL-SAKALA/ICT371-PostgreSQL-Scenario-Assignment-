-- ============================================================
-- SCENARIO 1: UNIVERSITY LIBRARY BOOK LOANS
-- ============================================================

-- PART 1.

-- CREATING THE BOOKS TABLE

CREATE TABLE books (
    book_id SERIAL PRIMARY KEY,
    book_title VARCHAR(150) NOT NULL,
    available_copies INT NOT NULL
);



-- CREATING THE BOOK_LOANS TABLE

CREATE TABLE book_loans (
    loan_id SERIAL PRIMARY KEY,
    book_id INT NOT NULL,
    student_number VARCHAR(30) NOT NULL,
    quantity INT NOT NULL,
    loan_status VARCHAR(20) NOT NULL DEFAULT 'Borrowed',
    CONSTRAINT fk_book
        FOREIGN KEY (book_id)
        REFERENCES books(book_id),
        CONSTRAINT check_quantity
        CHECK (quantity > 0)
);



-- INSERTING THREE BOOKS INTO BOOKS TABLE

INSERT INTO books (book_title, available_copies)
VALUES
    ('Database Systems', 5),
    ('Computer Networks', 3),
    ('Operating Systems', 8);


--  DISPLAYING INSERTED BOOKS

SELECT * FROM books;



-- DISPLAY BOOK LOANS
-- At this stage, no books have been borrowed yet.

SELECT * FROM book_loans;




-- ============================================================
-- PART 2: CHECK BOOK STOCK USING IF, ELSIF AND ELSE
-- ============================================================
-- We will check the book with book_id = 1.
-- The number of available copies is stored in the variable
-- called available_stock.

DO $$
DECLARE
    available_stock INT;
BEGIN

    -- Get the available copies for book number 1
    SELECT available_copies
    INTO available_stock
    FROM books
    WHERE book_id = 1;

    IF available_stock = 0 THEN

        RAISE NOTICE 'Book is unavailable.';

    ELSIF available_stock <= 2 THEN

        RAISE NOTICE 'Book has low copies. Only % copies remaining.',
                     available_stock;

    ELSE

        RAISE NOTICE 'Book is sufficiently stocked. % copies available.',
                     available_stock;

    END IF;

END $$;



-- ============================================================
-- PART 3: LOOPS
-- ============================================================
-- This section demonstrates two types of PL/pgSQL loops:
--
-- 1. WHILE loop
--    Used to display three overdue reminder numbers.
--
-- 2. Numeric FOR loop
--    Used to display three library shelf numbers.
-- ============================================================

-- 1. WHILE LOOP


DO $$
DECLARE
    reminder_number INT := 1;
BEGIN

    WHILE reminder_number <= 3 LOOP

        RAISE NOTICE 'Overdue Reminder Number: %',
                     reminder_number;

        -- Increase the reminder number by 1
        reminder_number := reminder_number + 1;

    END LOOP;

END $$;




-- 2. NUMERIC FOR LOOP

DO $$
BEGIN

    FOR shelf_number IN 1..3 LOOP

        RAISE NOTICE 'Library Shelf Number: %',
                     shelf_number;

    END LOOP;

END $$;





-- ============================================================
-- PART 4: BORROW_BOOK PROCEDURE
-- ============================================================
-- This procedure:
-- 1. Checks that the quantity is valid.
-- 2. Checks that the book exists.
-- 3. Checks whether enough copies are available.
-- 4. Reduces the available copies.
-- 5. Records the loan.
-- ============================================================


-- ------------------------------------------------------------
-- CREATING THE BORROW_BOOK PROCEDURE
-- ------------------------------------------------------------

CREATE OR REPLACE PROCEDURE borrow_book(
    p_book_id INT,
    p_student_number VARCHAR(30),
    p_quantity INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_available_copies INT;
BEGIN

    -- Check that the quantity is greater than zero
    IF p_quantity <= 0 THEN

        RAISE EXCEPTION
            'Invalid quantity. Quantity must be greater than zero.';

    END IF;


    -- Get the number of available copies
    SELECT available_copies
    INTO v_available_copies
    FROM books
    WHERE book_id = p_book_id
    FOR UPDATE;


    -- Check whether the book exists
    IF NOT FOUND THEN

        RAISE EXCEPTION
            'Book with ID % does not exist.',
            p_book_id;

    END IF;


    -- Check whether enough copies are available
    IF v_available_copies < p_quantity THEN

        RAISE NOTICE
            'Loan not recorded. Only % copies are available, but % were requested.',
            v_available_copies,
            p_quantity;

        RETURN;

    END IF;


    -- Reduce the number of available copies
    UPDATE books
    SET available_copies = available_copies - p_quantity
    WHERE book_id = p_book_id;


    -- Record the loan
    INSERT INTO book_loans (
        book_id,
        student_number,
        quantity,
        loan_status
    )
    VALUES (
        p_book_id,
        p_student_number,
        p_quantity,
        'Borrowed'
    );


    -- Display success message
    RAISE NOTICE
        'Loan recorded successfully for student %.',
        p_student_number;

END;
$$;



-- ============================================================
-- PART 5
-- ============================================================


-- First valid loan
CALL borrow_book(1, 'STU001', 2);


-- Second valid loan
CALL borrow_book(2, 'STU002', 1);


-- Request exceeds available copies
CALL borrow_book(2, 'STU003', 5);


-- ============================================================
-- DISPLAY THE RESULTS
-- ============================================================

-- Show remaining copies
SELECT
    book_id,
    book_title,
    available_copies
FROM books
ORDER BY book_id;


-- Show recorded loans
SELECT
    loan_id,
    book_id,
    student_number,
    quantity,
    loan_status
FROM book_loans
ORDER BY loan_id;



-- ============================================================
-- PART 6: RETURN BOOK
-- ============================================================

-- Create a procedure to return a borrowed book

CREATE OR REPLACE PROCEDURE return_book(
    p_loan_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_book_id INT;
    v_quantity INT;
    v_status VARCHAR(20);
BEGIN

    -- Get the loan details
    SELECT book_id, quantity, loan_status
    INTO v_book_id, v_quantity, v_status
    FROM book_loans
    WHERE loan_id = p_loan_id;

    -- Check if the loan exists
    IF NOT FOUND THEN

        RAISE NOTICE 'Loan does not exist.';

        RETURN;

    END IF;


    -- Check if the book was already returned
    IF v_status = 'Returned' THEN

        RAISE NOTICE 'This book has already been returned.';

        RETURN;

    END IF;


    -- Add the copies back to the books table
    UPDATE books
    SET available_copies = available_copies + v_quantity
    WHERE book_id = v_book_id;


    -- Mark the loan as returned
    UPDATE book_loans
    SET loan_status = 'Returned'
    WHERE loan_id = p_loan_id;


    -- Show success message
    RAISE NOTICE 'Book returned successfully.';

END;
$$;



-- ============================================================
-- TEST THE PROCEDURE
-- ============================================================

-- Return loan number 1
CALL return_book(1);


-- Try to return the same loan again
CALL return_book(1);


-- ============================================================
-- SHOW THE RESULTS
-- ============================================================

-- Show book stock
SELECT
    book_id,
    book_title,
    available_copies
FROM books
ORDER BY book_id;


-- Show loan status
SELECT
    loan_id,
    book_id,
    student_number,
    quantity,
    loan_status
FROM book_loans
ORDER BY loan_id;



-- ============================================================
-- PART 7: EXPLICIT CURSOR
-- ============================================================

-- Create a cursor to find books with few copies

DO $$
DECLARE
    book_cursor CURSOR FOR
        SELECT book_id, book_title, available_copies
        FROM books
        WHERE available_copies <= 2;

    v_book_id INT;
    v_book_title VARCHAR(150);
    v_available_copies INT;

BEGIN

    -- Open the cursor
    OPEN book_cursor;

    -- Read each book
    LOOP

        FETCH book_cursor
        INTO v_book_id, v_book_title, v_available_copies;

        -- Stop when there are no more books
        EXIT WHEN NOT FOUND;

        -- Display the book
        RAISE NOTICE
            'Book ID: %, Title: %, Copies: %',
            v_book_id,
            v_book_title,
            v_available_copies;

    END LOOP;

    -- Close the cursor
    CLOSE book_cursor;

END $$;




-- ============================================================
-- PART 8: EXCEPTION HANDLING
-- ============================================================

-- Try to borrow zero copies

DO $$
BEGIN

    CALL borrow_book(1, 'STU004', 0);

EXCEPTION
    WHEN OTHERS THEN

        RAISE NOTICE
            'Error: %',
            SQLERRM;

END $$;


-- ============================================================
-- PART 9: FINAL RESULTS
-- ============================================================

-- Show all books

SELECT
    book_id,
    book_title,
    available_copies
FROM books
ORDER BY book_id;


-- Show all loans

SELECT
    loan_id,
    book_id,
    student_number,
    quantity,
    loan_status
FROM book_loans
ORDER BY loan_id; 

