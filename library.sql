-- Enable foreign key constraint enforcement
PRAGMA foreign_keys = ON;

-- ====================================================================
-- ENTITY TABLES
-- ====================================================================

-- Create the Book table
CREATE TABLE Book (
    ISBN TEXT PRIMARY KEY,
    Title TEXT NOT NULL,
    Author TEXT,
    Page_count INTEGER,
    Genre TEXT,
    Edition TEXT,
    Quantity INTEGER NOT NULL CHECK (Quantity >= 0)
);

-- Create the Magazine table
CREATE TABLE Magazine (
    ISBN TEXT PRIMARY KEY,
    Title TEXT NOT NULL,
    Issue INTEGER,
    Publisher TEXT,
    Page_count INTEGER
);

-- Create the DVD table
CREATE TABLE DVD (
    DVD_ID INTEGER PRIMARY KEY, 
    Title TEXT NOT NULL,
    Genre TEXT,
    Length INTEGER,
    Actor TEXT,
    Director TEXT
);

-- Create the CD table
CREATE TABLE CD (
    CD_ID INTEGER PRIMARY KEY, 
    Title TEXT NOT NULL,
    Tracks INTEGER,
    Author TEXT
);

-- Create the LibraryUser table
CREATE TABLE LibraryUser (
    User_ID INTEGER PRIMARY KEY AUTOINCREMENT,
    FirstName TEXT NOT NULL,
    LastName TEXT NOT NULL,
    Start_date TEXT,
    end_date TEXT,
    ID TEXT NOT NULL UNIQUE
);

-- Create the LibraryStaff table
CREATE TABLE LibraryStaff (
    Staff_ID INTEGER PRIMARY KEY AUTOINCREMENT,
    FirstName TEXT NOT NULL,
    LastName TEXT NOT NULL,
    Start_date TEXT,
    end_date TEXT,
    ID TEXT NOT NULL UNIQUE,
    Position TEXT
);

-- Create the VideoGames table
CREATE TABLE VideoGames (
    Name TEXT PRIMARY KEY,
    Genre TEXT,
    Rating TEXT,
    Release_date TEXT
);

-- Create the Book_Checkout table
CREATE TABLE Book_Checkout (
    User_UID TEXT,
    Book_ISBN TEXT,
    Checkout_Number INTEGER CHECK (Checkout_Number > 0),
    Checkout_Date TEXT,
    Due_Date TEXT,
    PRIMARY KEY (User_UID, Book_ISBN, Checkout_Number),
    FOREIGN KEY (User_UID) REFERENCES LibraryUser(ID),
    FOREIGN KEY (Book_ISBN) REFERENCES Book(ISBN)
);

-- Create the CD_Checkout table
CREATE TABLE CD_Checkout (
    User_UID TEXT,
    CD_ID INTEGER,
    Checkout_Number INTEGER CHECK (Checkout_Number > 0),
    Checkout_Date TEXT,
    Due_Date TEXT,
    PRIMARY KEY (User_UID, CD_ID, Checkout_Number),
    FOREIGN KEY (User_UID) REFERENCES LibraryUser(ID),
    FOREIGN KEY (CD_ID) REFERENCES CD(CD_ID)
);

-- Create the DVD_Checkout table
CREATE TABLE DVD_Checkout (
    User_UID TEXT, 
    DVD_ID INTEGER,
    Checkout_Number INTEGER CHECK (Checkout_Number > 0),
    Checkout_Date TEXT,
    Due_Date TEXT,
    PRIMARY KEY (User_UID, DVD_ID, Checkout_Number),
    FOREIGN KEY (User_UID) REFERENCES LibraryUser(ID),
    FOREIGN KEY (DVD_ID) REFERENCES DVD(DVD_ID)
);

-- Create the VideoGame_Checkout table
CREATE TABLE VideoGame_Checkout (
    User_UID TEXT, 
    Game_Name TEXT,
    Checkout_Number INTEGER CHECK (Checkout_Number > 0),
    Checkout_Date TEXT,
    Due_Date TEXT,
    PRIMARY KEY (User_UID, Game_Name, Checkout_Number),
    FOREIGN KEY (User_UID) REFERENCES LibraryUser(ID),
    FOREIGN KEY (Game_Name) REFERENCES VideoGames(Name)
);

-- Create the Magazine_Checkout table -- ADDED
CREATE TABLE Magazine_Checkout (
    User_UID TEXT,
    Magazine_ISBN TEXT,
    Checkout_Number INTEGER CHECK (Checkout_Number > 0),
    Checkout_Date TEXT,
    Due_Date TEXT,
    PRIMARY KEY (User_UID, Magazine_ISBN, Checkout_Number),
    FOREIGN KEY (User_UID) REFERENCES LibraryUser(ID),
    FOREIGN KEY (Magazine_ISBN) REFERENCES Magazine(ISBN)
);

-- Create the Staff_Reshelves table
CREATE TABLE Staff_Reshelves (
    Reshelve_ID INTEGER PRIMARY KEY AUTOINCREMENT,
    Staff_UID TEXT, 
    Book_ISBN TEXT,
    DVD_ID INTEGER,
    CD_ID INTEGER,
    Game_Name TEXT,
    Magazine_ISBN TEXT,
    Reshelve_Date TEXT,
    FOREIGN KEY (Staff_UID) REFERENCES LibraryStaff(ID),
    FOREIGN KEY (Book_ISBN) REFERENCES Book(ISBN),
    FOREIGN KEY (DVD_ID) REFERENCES DVD(DVD_ID),
    FOREIGN KEY (CD_ID) REFERENCES CD(CD_ID),
    FOREIGN KEY (Game_Name) REFERENCES VideoGames(Name),
    FOREIGN KEY (Magazine_ISBN) REFERENCES Magazine(ISBN)
);