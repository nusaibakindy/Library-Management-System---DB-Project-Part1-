use [DB Project Part 2 ]
-- Create Library Table
CREATE TABLE Library (
    LibraryID INT PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,
    Location VARCHAR(255),
    ContactNumber VARCHAR(15),
    EstablishedYear INT
);

-- creat book Table
CREATE TABLE Book (
    BookID INT PRIMARY KEY,
    ISBN VARCHAR(20) UNIQUE NOT NULL,
    Title VARCHAR(255) NOT NULL,
    Genre VARCHAR(50) CHECK (Genre IN ('Fiction', 'Non-fiction', 'Reference', 'Children')),
    Price DECIMAL(10, 2) CHECK (Price > 0),
    AvailabilityStatus BIT DEFAULT 1, -- 1 represents TRUE
    ShelfLocation VARCHAR(50),
    LibraryID INT,
    FOREIGN KEY (LibraryID) REFERENCES Library(LibraryID) ON DELETE CASCADE
);

-- -- creat Member Table
CREATE TABLE Member (
    MemberID INT PRIMARY KEY,
    FullName VARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL,
    PhoneNumber VARCHAR(20),
    MembershipStartDate DATE,
    BookID INT, 
    FOREIGN KEY (BookID) REFERENCES Book(BookID) ON DELETE SET NULL
);

-- Create Staff Table
CREATE TABLE Staff (
    StaffID INT PRIMARY KEY,
    FullName VARCHAR(100) NOT NULL,
    Position VARCHAR(100),
    ContactNumber VARCHAR(20),
    LibraryID INT,
    FOREIGN KEY (LibraryID) REFERENCES Library(LibraryID) ON DELETE CASCADE
);

-- Create Transaction Table
CREATE TABLE Transactions (
   paymentID INT PRIMARY KEY,
    MemberID INT NOT NULL,
    BookID INT NOT NULL,
    Amount DECIMAL(10, 2) CHECK (Amount >= 0),
    Method VARCHAR(50) CHECK (Method IN ('Cash', 'Card', 'Online')),
    PaymentDate DATE NOT NULL,
    FOREIGN KEY (MemberID) REFERENCES Member(MemberID) ON DELETE CASCADE,
    FOREIGN KEY (BookID) REFERENCES Book(BookID) ON DELETE CASCADE
);


--creat review table 
CREATE TABLE Review (
    MemberID INT NOT NULL,
    BookID INT NOT NULL,
    Rating INT CHECK (Rating BETWEEN 1 AND 5),
    Comment TEXT,
    ReviewDate DATE DEFAULT GETDATE(),
    PRIMARY KEY (MemberID, BookID),
    FOREIGN KEY (MemberID) REFERENCES Member(MemberID) ON DELETE CASCADE,
    FOREIGN KEY (BookID) REFERENCES Book(BookID) ON DELETE CASCADE
);

-- Create Loan Table
CREATE TABLE Loan (
    MemberID INT NOT NULL,
    BookID INT NOT NULL,
    paymentID INT NOT NULL,
    LoanDate DATE NOT NULL,
    DueDate DATE NOT NULL,
    ReturnDate DATE,
    Status VARCHAR(20) CHECK (Status IN ('On Loan', 'Returned', 'Overdue')),
    PRIMARY KEY (MemberID, BookID, paymentID),
    FOREIGN KEY (MemberID) REFERENCES Member(MemberID) ON DELETE CASCADE,
    FOREIGN KEY (BookID) REFERENCES Book(BookID) ON DELETE CASCADE,
    FOREIGN KEY (paymentID) REFERENCES Transactions(paymentID)
        ON DELETE NO ACTION  -- avoids cycle / multiple cascade path error
);
--  Libraries
INSERT INTO Library (LibraryID, Name, Location) VALUES
(1, 'Downtown Public Library', '123 Main St'),
(2, 'Westside Community Library', '456 Oak Ave'),
(3, 'East End Library', '789 Pine Rd');

--books
INSERT INTO Book (BookID, Title, ISBN, LibraryID) VALUES
(101, '1984', '9780451524935', 1),
(102, 'To Kill a Mockingbird', '9780061120084', 1),
(103, 'The Great Gatsby', '9780743273565', 1),
(104, 'Moby Dick', '9781503280786', 2),
(105, 'Pride and Prejudice', '9781503290563', 2),
(106, 'The Catcher in the Rye', '9780316769488', 2),
(107, 'Brave New World', '9780060850524', 3),
(108, 'The Hobbit', '9780547928227', 3),
(109, 'Fahrenheit 451', '9781451673319', 3),
(110, 'Jane Eyre', '9780141441146', 1);

--members
INSERT INTO Member (MemberID, fullname, Email) VALUES
(201, 'Alice Johnson', 'alice@example.com'),
(202, 'Bob Smith', 'bob@example.com'),
(203, 'Charlie Davis', 'charlie@example.com'),
(204, 'Diana Evans', 'diana@example.com'),
(205, 'Ethan Brown', 'ethan@example.com'),
(206, 'Fiona Clark', 'fiona@example.com');


-- staff 
INSERT INTO Staff (StaffID, FullName, Position, LibraryID) VALUES
(501, 'Grace Harper', 'Librarian', 1),
(502, 'Henry Wells', 'Assistant', 1),
(503, 'Isla King', 'Librarian', 2),
(504, 'Jake Long', 'Technician', 3);

--transaction 
INSERT INTO Transactions (PaymentID, MemberID, Amount, PaymentDate, BookID) VALUES
(401, 201, 5.00, '2025-04-25', 101),
(402, 202, 2.50, '2025-05-01', 102),
(403, 203, 3.75, '2025-05-05', 103),
(404, 204, 1.25, '2025-05-10', 104);

--review
INSERT INTO Review (BookID, MemberID, Rating, Comment) VALUES
(101, 201, 5, 'Thought-provoking and intense.'),
(102, 202, 4, 'A timeless classic.'),
(103, 203, 3, 'Interesting, but a bit slow.'),
(104, 204, 5, 'Absolutely loved it!'),
(105, 205, 4, 'Well-written and engaging.'),
(106, 206, 2, 'Didn’t connect with the characters.');

--loans 

INSERT INTO Loan (BookID, MemberID, paymentID, LoanDate, DueDate, ReturnDate, Status) VALUES
(101, 201, 401, '2025-05-01', '2025-05-15', NULL, 'On Loan'),
(102, 202, 402, '2025-04-20', '2025-05-04', '2025-05-03', 'Returned'),
(103, 203, 403, '2025-05-05', '2025-05-19', NULL, 'On Loan'),
(104, 204, 404, '2025-04-15', '2025-04-29', '2025-04-28', 'Returned');

-- GET /books/popular
SELECT TOP 3 B.BookID, B.Title, COUNT(*) AS LoanCount
FROM Loan L
JOIN Book B ON L.BookID = B.BookID
GROUP BY B.BookID, B.Title
ORDER BY LoanCount DESC;

-- GET /members/:id/history
DECLARE @MemberID INT = 1;

SELECT B.Title, L.LoanDate, L.ReturnDate
FROM Loan L
JOIN Book B ON L.BookID = B.BookID
WHERE L.MemberID = @MemberID;

-- GET /members/inactive 
SELECT M.MemberID, M.FullName
FROM Member M
LEFT JOIN Loan L ON M.MemberID = L.MemberID
WHERE L.MemberID IS NULL;

--GET /books/never-loaned
SELECT B.BookID, B.Title
FROM Book B
LEFT JOIN Loan L ON B.BookID = L.BookID
WHERE L.BookID IS NULL;

--GET /payments
SELECT T.paymentID, M.FullName, B.Title, T.Amount, T.Method, T.PaymentDate
FROM Transactions T
JOIN Member M ON T.MemberID = M.MemberID
JOIN Book B ON T.BookID = B.BookID;

-- GET /loans/overdue
SELECT M.FullName, B.Title, L.DueDate
FROM Loan L
JOIN Member M ON L.MemberID = M.MemberID
JOIN Book B ON L.BookID = B.BookID
WHERE L.Status = 'Overdue';

-- GET /books/:id/loan-count
SELECT BookID, COUNT(*) AS LoanCount
FROM Loan
WHERE BookID = 101
GROUP BY BookID;

--GET /members/:id/fines
SELECT SUM(Amount) AS TotalFine
FROM Transactions
WHERE MemberID = 1;

--GET /libraries/:id/book-stats
SELECT
  SUM(CASE WHEN AvailabilityStatus = 1 THEN 1 ELSE 0 END) AS AvailableBooks,
  SUM(CASE WHEN AvailabilityStatus = 0 THEN 1 ELSE 0 END) AS UnavailableBooks
FROM Book
WHERE LibraryID = 1;

-- GET /reviews/top-rated
SELECT B.BookID, B.Title, COUNT(*) AS ReviewCount, AVG(Rating) AS AvgRating
FROM Review R
JOIN Book B ON R.BookID = B.BookID
GROUP BY B.BookID, B.Title
HAVING COUNT(*) > 5 AND AVG(Rating) > 4.5;