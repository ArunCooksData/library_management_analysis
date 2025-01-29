--LIBRARY MANAGEMENT PROJECT TASKS QUERIES 

-- Task 1 : Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"

INSERT INTO books
(isbn,book_title,category,rental_price,status,author,publisher)
VALUES 
('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');
SELECT * FROM books;




-- Task 2: Update an Existing Member's Address

UPDATE members
SET member_address = '125 Main St'
WHERE member_id = 'C101';
SELECT * FROM members;




-- Task 3: Delete a Record from the Issued Status Table 
-- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.

SELECT * FROM issued_status
WHERE issued_id = 'IS121';

DELETE FROM issued_status
WHERE issued_id = 'IS121'


-- Task 4: Retrieve All Books Issued by a Specific Employee -- 
--Objective: Select all books issued by the employee with emp_id = 'E101'.

SELECT * FROM issued_status
WHERE issued_emp_id = 'E101'


-- Task 5: List Members Who Have Issued More Than One Book 
-- Objective: Use GROUP BY to find members who have issued more than one book.


SELECT issued_emp_id,emp_name,COUNT(issued_book_name) as NO_OF_BOOKS
FROM employees a
JOIN issued_status b
ON a.emp_id = b.issued_emp_id
GROUP BY 1,2
HAVING COUNT(issued_id)>1
ORDER BY 3 DESC


-- CTAS (CREATE TABLE AS SELECT)
-- Task 6: Create Summary Tables: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt**

CREATE TABLE book_counts
AS    
SELECT b.isbn,b.book_title,COUNT(a.issued_id) as no_issued
FROM books as b
JOIN issued_status as a
ON a.issued_book_isbn = b.isbn
GROUP BY 1, 2;

SELECT * FROM
book_counts;



-- Task 7: Retrieve All Books in a Specific Category:

SELECT * FROM books
WHERE category = 'History'


-- Task 8: Find Total Rental Income by Category:

SELECT category,SUM(rental_price) as Total_Rental_Income
FROM books a
JOIN issued_status b
ON a.isbn = b.issued_book_isbn
GROUP BY 1
ORDER BY 2 DESC



--TASK 9: List Members Who Registered in the Last 300 Days:

SELECT * FROM  members
WHERE  reg_date >= CURRENT_DATE - INTERVAL '300 days'  



-- task 10: List Employees with Their Branch Manager's Name and their branch details:

SELECT a.*,b.manager_id,c.emp_name as manager
FROM employees as a
JOIN branch as b
ON b.branch_id = a.branch_id
JOIN employees as c
ON b.manager_id = c.emp_id

-- Task 11: Create a Table of Books with Rental Price Above a Certain Threshold 7USD:

CREATE TABLE Book_rent_above_7
AS
SELECT book_title,rental_price AS Total_rent
FROM books
WHERE rental_price>7.00

SELECT * FROM Book_rent_above_7


--Task 12: Retrieve the List of Books Not Yet Returned

SELECT DISTINCT a.issued_Id,issued_book_name,b.return_id
FROM issued_status a
LEFT JOIN return_status b
on a.issued_id = b.return_id
WHERE b.return_id IS NULL

-- TASK 13 : Write a query to identify members who have overdue books (assume a 30-day return period).
--Display the member's_id, member's name, book title, issue date, and days overdue.

SELECT 
    a.issued_member_id,
    b.member_name,
    c.book_title,
    a.issued_date,
    d.return_date,
    CURRENT_DATE - a.issued_date as over_dues_days
FROM issued_status as a
JOIN 
members as b
    ON b.member_id = a.issued_member_id
JOIN 
books as c
ON c.isbn = a.issued_book_isbn
LEFT JOIN 
return_status as d
ON d.issued_id = a.issued_id
WHERE 
    d.return_date IS NULL
    AND
    (CURRENT_DATE - a.issued_date) > 30
ORDER BY 1


-- TASK 14 : Write a query to update the status of books in the books table to "Yes" 
--when they are returned (based on entries in the return_status table).



CREATE OR REPLACE PROCEDURE add_return_records(p_return_id VARCHAR(10), p_issued_id VARCHAR(10), p_book_quality VARCHAR(10))
LANGUAGE plpgsql
AS $$

DECLARE
    v_isbn VARCHAR(50);
    v_book_name VARCHAR(80);
    
BEGIN
    -- all your logic and code
    -- inserting into returns based on users input
    INSERT INTO return_status(return_id, issued_id, return_date, book_quality)
    VALUES
    (p_return_id, p_issued_id, CURRENT_DATE, p_book_quality);

    SELECT 
        issued_book_isbn,
        issued_book_name
        INTO
        v_isbn,
        v_book_name
    FROM issued_status
    WHERE issued_id = p_issued_id;

    UPDATE books
    SET status = 'yes'
    WHERE isbn = v_isbn;

    RAISE NOTICE 'Thank you for returning the book: %', v_book_name;
    
END;
$$


-- Testing FUNCTION add_return_records

issued_id = IS135
ISBN = WHERE isbn = '978-0-307-58837-1'

SELECT * FROM books
WHERE isbn = '978-0-307-58837-1';

SELECT * FROM issued_status
WHERE issued_book_isbn = '978-0-307-58837-1';

SELECT * FROM return_status
WHERE issued_id = 'IS135';

-- calling function 
CALL add_return_records('RS138', 'IS135', 'Good');

-- calling function 
CALL add_return_records('RS148', 'IS140', 'Good');


-- TASK 15: Create a query that generates a performance report for each branch, 
--showing the number of books issued, the number of books returned, and
--the total revenue generated from book rentals.


CREATE TABLE Branch_wise_performancee
AS
SELECT a.branch_id,f.manager_id,
	COUNT(b.issued_book_name) AS Total_issued_books,
	COUNT(c.return_id) AS Total_returned_books,
	SUM(d.rental_price) AS Total_revenue
	
FROM employees a
JOIN issued_status b
	ON a.emp_id = b.issued_emp_id
JOIN branch as f
	ON a.branch_id = f.branch_id
JOIN books d
	ON b.issued_book_isbn = d.isbn
LEFT JOIN return_status c
	ON b.issued_id = c.issued_Id
GROUP BY 1,2
ORDER BY 4 DESC
	
SELECT * FROM Branch_wise_performancee



--TASK 16 : Use the CREATE TABLE AS (CTAS) statement to create a new table active_members 
--containing members who have issued at least one book in the last 9 months.


CREATE TABLE active_memberss
AS
SELECT * FROM members
WHERE member_id IN (SELECT 
                        DISTINCT issued_member_id   
                    FROM issued_status
                    WHERE 
                        issued_date >= CURRENT_DATE - INTERVAL '9 month'
                    );
SELECT * FROM active_memberss;



--TASK17 : Write a query to find the top 3 employees who have processed the most book issues. 
--Display the employee name, number of books processed, and their branch.


with emp AS(
SELECT 
	a.emp_name,
	COUNT(issued_book_name) AS Total_no_of_books,
	c.branch_id,
	DENSE_RANK() over (ORDER BY COUNT(issued_book_name)DESC) as dense_rankk
	
FROM employees a
JOIN issued_status b
	ON a.emp_id = b.issued_emp_id
JOIN branch c
	ON a.branch_id = c.branch_id
	
GROUP BY 1,3
ORDER BY 2 DESC
	
)

SELECT * FROM emp
WHERE dense_rankk in (1,2,3)


--TASK18 :Write a query to identify members who have issued books more than twice with the status "NO" in the books table.
--Display the member name, book title, status

WITH MY AS(
SELECT a.member_name,c.book_title,c.status,COUNT(*) OVER (PARTITION BY a.member_name) AS issue_count
FROM members a
JOIN issued_status b
ON a.member_id = b.issued_member_id
JOIN books c
ON b.issued_book_isbn = c.isbn
WHERE c.status = 'no'
)
SELECT member_name,book_title,status
FROM MY 
WHERE issue_count>'2'


--TASK19 : Stored Procedure Objective: Create a stored procedure to manage the status of books in a library system. 
--Description: Write a stored procedure that updates the status of a book in the library based on its issuance. 
--The procedure should function as follows: 
--The stored procedure should take the book_id as an input parameter. 
--The procedure should first check if the book is available (status = 'yes'). 
--If the book is available, it should be issued, and the status in the books table should be updated to 'no'. 
--If the book is not available (status = 'no'), 
--the procedure should return an error message indicating that the book is currently not available.


CREATE OR REPLACE PROCEDURE issued_book(p_issued_id VARCHAR(10),
										 p_issued_member_id VARCHAR(30),
										 p_issued_book_isbn  VARCHAR(50),
										 p_issued_emp_id  VARCHAR(10))
LANGUAGE plpgsql
AS $$

DECLARE
-- all the variable declaration
	v_status VARCHAR(10);


BEGIN
-- all the code

	--checking if the is available 'yes'
	SELECT status INTO V_status
	FROM books
	WHERE isbn = p_issued_book_isbn;
	
	IF v_status = 'yes' THEN
	
		INSERT INTO issued_status(issued_id,issued_member_id,issued_date,issued_book_isbn,issued_emp_id)
		VALUES(p_issued_id,
			   p_issued_member_id,
			   CURRENT_DATE,
			   p_issued_book_isbn,
			   p_issued_emp_id);
		
		UPDATE books
			SET status = 'no'
		WHERE isbn = p_issued_book_isbn;
		
		RAISE NOTICE 'Book Records added successfully for book isbn : %',p_issued_book_isbn;
		
	ELSE
		RAISE NOTICE 'Sorry to inform you that,the book you have requested is unavailable,book isbn : %',p_issued_book_isbn;
	END IF;	


END;
$$


-- Testing The function

SELECT * FROM books;

-- "978-0-553-29698-2" -- yes
-- "978-0-375-41398-8" -- no

SELECT * FROM issued_status;

CALL issued_book('IS155','C108','978-0-553-29698-2','E104')
CALL issued_book('IS156','C108','978-0-375-41398-8','E104')



-- VERIFYING THE STATUS:

SELECT * FROM books
WHERE isbn = '978-0-553-29698-2'


-- TASK 20 : 
--Description: Write a CTAS query to create a new table that lists each member and 
--the books they have issued but not returned within 30 days. 
--The table should include: The number of overdue books. 
--The total fines, with each day's fine calculated at $0.50. 
--The number of books issued by each member. 
--The resulting table should show: Member ID Number of overdue books Total fines

CREATE TABLE overdue_books_summary AS
SELECT 
    b.member_id,
    COUNT(c.book_title) AS no_of_overdue_books,
    SUM(CASE 
            WHEN d.return_date IS NULL THEN (CURRENT_DATE - a.issued_date - 30) * 0.50
            WHEN (d.return_date - a.issued_date) > 30 THEN (d.return_date - a.issued_date - 30) * 0.50
            ELSE 0
        END) AS total_fines,
    COUNT(a.issued_id) AS total_books_issued
FROM 
    issued_status AS a
JOIN 
    members AS b
    ON b.member_id = a.issued_member_id
JOIN 
    books AS c
    ON c.isbn = a.issued_book_isbn
LEFT JOIN 
    return_status AS d
    ON d.issued_id = a.issued_id
WHERE 
    (d.return_date IS NULL AND (CURRENT_DATE - a.issued_date) > 30) 
    OR ((d.return_date - a.issued_date) > 30)
GROUP BY 
    b.member_id
ORDER BY 
    no_of_overdue_books DESC;

SELECT * FROM overdue_books_summary;

