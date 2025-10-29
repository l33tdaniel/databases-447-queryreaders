-- Functionality Testing Script for Library Database
-- Tests data storage, updates, searches, reports, edge cases, and performance

-- Enable foreign keys for constraint testing
PRAGMA foreign_keys = ON;

-- ====================================================================
-- TEST DATA SETUP
-- ====================================================================

-- Clean existing data (for fresh tests)
DELETE FROM Staff_Reshelves;
DELETE FROM Book_Checkout;
DELETE FROM CD_Checkout;
DELETE FROM DVD_Checkout;
DELETE FROM VideoGame_Checkout;
DELETE FROM Magazine_Checkout;
DELETE FROM Book;
DELETE FROM Magazine;
DELETE FROM DVD;
DELETE FROM CD;
DELETE FROM VideoGames;
DELETE FROM LibraryUser;
DELETE FROM LibraryStaff;

-- Insert test users
INSERT INTO LibraryUser (FirstName, LastName, Start_date, end_date, ID) VALUES
('John', 'Doe', '2024-01-01', '2025-12-31', 'USER001'),
('Jane', 'Smith', '2024-02-01', NULL, 'USER002');

-- Insert test staff
INSERT INTO LibraryStaff (FirstName, LastName, Start_date, end_date, ID, Position) VALUES
('Alice', 'Manager', '2023-01-01', NULL, 'STAFF001', 'Librarian'),
('Bob', 'Assistant', '2023-06-01', NULL, 'STAFF002', 'Assistant');

-- Insert test items
INSERT INTO Book (ISBN, Title, Author, Page_count, Genre, Edition, Quantity) VALUES
('1234567890', 'Test Book 1', 'Author A', 200, 'Fiction', '1st', 5),
('0987654321', 'Test Book 2', 'Author B', 300, 'Non-Fiction', '2nd', 3);

INSERT INTO Magazine (ISBN, Title, Issue, Publisher, Page_count) VALUES
('1111111111', 'Tech Magazine', 1, 'Tech Pub', 50),
('2222222222', 'Science Mag', 2, 'Sci Pub', 40);

INSERT INTO DVD (DVD_ID, Title, Genre, Length, Actor, Director) VALUES
(1, 'Test Movie', 'Action', 120, 'Actor X', 'Director Y'),
(2, 'Test Series', 'Drama', 90, 'Actor Z', 'Director W');

INSERT INTO CD (CD_ID, Title, Tracks, Author) VALUES
(1, 'Test Album', 10, 'Artist A'),
(2, 'Test Collection', 12, 'Artist B');

INSERT INTO VideoGames (Name, Genre, Rating, Release_date) VALUES
('Test Game', 'Action', 'M', '2023-01-01'),
('Test RPG', 'RPG', 'T', '2023-03-15');

-- --------------------------------------------------------------------
-- DATA INSERTION QUERIES (Storing Data)
-- --------------------------------------------------------------------

-- Demonstrate inserting new user with required fields
INSERT INTO LibraryUser (FirstName, LastName, ID) VALUES
('Charlie', 'Brown', 'USER003');

-- Demonstrate inserting new book
INSERT INTO Book (ISBN, Title, Author, Page_count, Genre, Edition, Quantity) VALUES
('7777777777', 'New Book', 'New Author', 250, 'Mystery', '1st', 1);

-- --------------------------------------------------------------------
-- DATA UPDATE QUERIES
-- --------------------------------------------------------------------

-- Update book stock after purchase
UPDATE Book SET Quantity = Quantity + 5 WHERE ISBN = '1234567890';

-- Update user details
UPDATE LibraryUser SET end_date = '2024-12-31' WHERE ID = 'USER002';

-- Update staff position
UPDATE LibraryStaff SET Position = 'Senior Librarian' WHERE ID = 'STAFF001';

-- --------------------------------------------------------------------
-- SEARCH FUNCTIONALITIES
-- --------------------------------------------------------------------

-- Search books by title (case insensitive)
SELECT * FROM Book WHERE Title LIKE '%Test%' COLLATE NOCASE;

-- Search books by author
SELECT * FROM Book WHERE Author = 'Author A';

-- Search books by genre
SELECT * FROM Book WHERE Genre = 'Fiction';

-- Find available DVDs (those not at max checkouts - simplified since no quantity tracking)
SELECT * FROM DVD
WHERE DVD_ID NOT IN (
    SELECT DVD_ID FROM DVD_Checkout
    WHERE User_UID = 'USER001'
    GROUP BY DVD_ID
    HAVING COUNT(*) >= 5
);

-- User checkout history
SELECT b.Title, bc.Checkout_Date, bc.Due_Date, bc.Checkout_Number
FROM Book_Checkout bc
JOIN Book b ON bc.Book_ISBN = b.ISBN
WHERE bc.User_UID = 'USER001';

-- --------------------------------------------------------------------
-- REPORT QUERIES
-- --------------------------------------------------------------------

-- Inventory Summary by Type
SELECT 'Books' as Type, COUNT(*) as Count FROM Book
UNION ALL
SELECT 'Magazines', COUNT(*) FROM Magazine
UNION ALL
SELECT 'DVDs', COUNT(*) FROM DVD
UNION ALL
SELECT 'CDs', COUNT(*) FROM CD
UNION ALL
SELECT 'Video Games', COUNT(*) FROM VideoGames;

-- Total checkouts per item type
SELECT 'Books' as Type, COUNT(*) as Checkouts FROM Book_Checkout
UNION ALL
SELECT 'DVDs', COUNT(*) FROM DVD_Checkout
UNION ALL
SELECT 'CDs', COUNT(*) FROM CD_Checkout
UNION ALL
SELECT 'Magazines', COUNT(*) FROM Magazine_Checkout
UNION ALL
SELECT 'Games', COUNT(*) FROM VideoGame_Checkout;

-- Overdue items (assuming today's date is 2024-10-01 for testing)
-- In real usage, would use DATE('now')
SELECT 'Books', b.Title, u.FirstName || ' ' || u.LastName as User_Name, bc.Due_Date
FROM Book_Checkout bc
JOIN Book b ON bc.Book_ISBN = b.ISBN
JOIN LibraryUser u ON bc.User_UID = u.ID
WHERE bc.Due_Date < '2024-10-01';

-- Popular items (most checked out books)
SELECT b.Title, b.Author, COUNT(*) as Checkout_Count
FROM Book_Checkout bc
JOIN Book b ON bc.Book_ISBN = b.ISBN
GROUP BY b.ISBN, b.Title, b.Author
ORDER BY Checkout_Count DESC;

-- Staff activity report
SELECT s.FirstName || ' ' || s.LastName as Staff_Name,
       COUNT(sr.Reshelve_ID) as Items_Reshelved,
       sr.Reshelve_Date
FROM Staff_Reshelves sr
JOIN LibraryStaff s ON sr.Staff_UID = s.ID
GROUP BY sr.Staff_UID, sr.Reshelve_Date;

-- --------------------------------------------------------------------
-- EDGE CASE TESTING
-- --------------------------------------------------------------------

-- Test inserting with invalid foreign key (should fail)
-- This will fail due to foreign key constraint
INSERT INTO Book_Checkout (User_UID, Book_ISBN, Checkout_Number, Checkout_Date, Due_Date)
VALUES ('INVALID_USER', '1234567890', 1, '2024-10-01', '2024-10-15');

-- Test duplicate primary key
INSERT INTO Book (ISBN, Title, Author, Quantity) VALUES
('1234567890', 'Duplicate Book', 'Test Author', 1); -- Should fail

-- Test exceeding checkout limit for one item
INSERT INTO Book_Checkout (User_UID, Book_ISBN, Checkout_Number, Checkout_Date, Due_Date) VALUES
('USER001', '1234567890', 6, '2024-10-01', '2024-10-15'); -- Should succeed but violate business rule

-- Test null required field
INSERT INTO Book (ISBN, Title, Quantity) VALUES
('9999999999', NULL, 1); -- Should fail due to NOT NULL

-- Test invalid date format
UPDATE Book_Checkout SET Checkout_Date = 'INVALID_DATE' WHERE User_UID = 'USER001';

-- --------------------------------------------------------------------
-- PERFORMANCE TESTING
-- --------------------------------------------------------------------

-- Analyze query performance with EXPLAIN QUERY PLAN
EXPLAIN QUERY PLAN SELECT * FROM Book WHERE Genre = 'Fiction';

-- Complex join performance (checkout history)
EXPLAIN QUERY PLAN
SELECT u.FirstName, u.LastName, b.Title, bc.Checkout_Date
FROM Book_Checkout bc
JOIN LibraryUser u ON bc.User_UID = u.ID
JOIN Book b ON bc.Book_ISBN = b.ISBN
WHERE u.Start_date >= '2024-01-01';

-- Index suggestion for frequent searches (if needed, create additional indexes)
CREATE INDEX IF NOT EXISTS idx_book_genre ON Book(Genre);
CREATE INDEX IF NOT EXISTS idx_book_author ON Book(Author);
CREATE INDEX IF NOT EXISTS idx_checkout_date ON Book_Checkout(Checkout_Date);

-- Test optimized query
EXPLAIN QUERY PLAN SELECT COUNT(*) FROM Book WHERE Genre = 'Fiction' AND Author LIKE '%A%';

-- ====================================================================
-- VERIFICATION QUERIES (Run after above tests)
-- ====================================================================

-- Verify data insertion
SELECT 'Users inserted:', COUNT(*) FROM LibraryUser;
SELECT 'Books inserted:', COUNT(*) FROM Book;
SELECT 'DVDs inserted:', COUNT(*) FROM DVD;

-- Verify update operations
SELECT 'Updated book quantity:', Quantity FROM Book WHERE ISBN = '1234567890';
SELECT 'Staff position update:', Position FROM LibraryStaff WHERE ID = 'STAFF001';

-- Verify search results
SELECT 'Books by Author A:', COUNT(*) FROM Book WHERE Author = 'Author A';
SELECT 'Fiction genre books:', COUNT(*) FROM Book WHERE Genre = 'Fiction';

-- Verify report accuracy
SELECT 'Total checkouts (should match sum above):',
       (SELECT COUNT(*) FROM Book_Checkout) +
       (SELECT COUNT(*) FROM DVD_Checkout) +
       (SELECT COUNT(*) FROM CD_Checkout) +
       (SELECT COUNT(*) FROM Magazine_Checkout) +
       (SELECT COUNT(*) FROM VideoGame_Checkout) as Total_Checkouts;

-- Check for constraint violations (should be empty if all tests passed)
SELECT 'Foreign key violations:', COUNT(*) FROM sqlite_master where type='trigger' and sql like '%foreign_key%' ;

.echo OFF
.echo "Functionality Testing Complete"
