-- Additional tests for checkout limits and business logic

PRAGMA foreign_keys = ON;

-- Test checkout limits per item type (max 5 per user per item)

-- Insert some checkouts for testing
INSERT INTO Book_Checkout (User_UID, Book_ISBN, Checkout_Number, Checkout_Date, Due_Date) VALUES
('USER001', '1234567890', 1, '2024-10-01', '2024-10-15'),
('USER001', '1234567890', 2, '2024-10-01', '2024-10-15'),
('USER001', '1234567890', 3, '2024-10-01', '2024-10-15'),
('USER001', '1234567890', 4, '2024-10-01', '2024-10-15'),
('USER001', '1234567890', 5, '2024-10-01', '2024-10-15');

-- This should be allowed (exactly 5)
SELECT 'Allowed: User has exactly 5 checkouts for this book',
       COUNT(*) as Checkout_Count
FROM Book_Checkout
WHERE User_UID = 'USER001' AND Book_ISBN = '1234567890';

-- Test attempting 6th checkout (this would need application-level check)
INSERT INTO Book (ISBN, Title, Author, Quantity) VALUES
('5555555555', 'Another Book', 'Another Author', 10);

INSERT INTO Book_Checkout (User_UID, Book_ISBN, Checkout_Number, Checkout_Date, Due_Date) VALUES
('USER001', '5555555555', 1, '2024-10-01', '2024-10-15');

-- Check business rule: user has 6 different books out (some multiple copies)
SELECT 'User checkout summary by book:',
       b.Title,
       COUNT(bc.Checkout_Number) as Instances,
       SUM(CASE WHEN bc.Due_Date < '2024-10-10' THEN 1 ELSE 0 END) as Overdue_Count
FROM Book_Checkout bc
JOIN Book b ON bc.Book_ISBN = b.ISBN
WHERE bc.User_UID = 'USER001'
GROUP BY b.ISBN, b.Title;

-- Test reshelving (staff returns items)
INSERT INTO Staff_Reshelves (Staff_UID, Book_ISBN, Reshelve_Date) VALUES
('STAFF001', '1234567890', '2024-10-05');

-- Check if reshelving updates availability (quantity) - but schema doesn't auto-update, would need trigger

-- Test reports work with actual data
SELECT 'Available books (Quantity > checkouts):',
       b.Title,
       b.Quantity - COALESCE(checkout_count.Checkout_Count, 0) as Available
FROM Book b
LEFT JOIN (
    SELECT Book_ISBN, COUNT(*) as Checkout_Count
    FROM Book_Checkout
    GROUP BY Book_ISBN
) checkout_count ON b.ISBN = checkout_count.Book_ISBN
WHERE b.Quantity - COALESCE(checkout_count.Checkout_Count, 0) > 0;

-- Performance test with larger data simulation
EXPLAIN QUERY PLAN
SELECT u.FirstName, u.LastName, b.Title, bc.Checkout_Date, s.FirstName as Staff_First
FROM Book_Checkout bc
JOIN LibraryUser u ON bc.User_UID = u.ID
JOIN Book b ON bc.Book_ISBN = b.ISBN
LEFT JOIN Staff_Reshelves sr ON bc.Book_ISBN = sr.Book_ISBN
LEFT JOIN LibraryStaff s ON sr.Staff_UID = s.ID;
