

--- Address table
CREATE TABLE Address (
    AddressID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    AddressLine1 NVARCHAR(50) NOT NULL,
	AddressLine2 NVARCHAR(50) NULL,
    City NVARCHAR(50) NOT NULL,
    PostalCode NVARCHAR(20) NOT NULL);



--- Item type table
CREATE TABLE ItemType (
	ItemTypeID INT IDENTITY(1,1) PRIMARY KEY,
	TypeDescription VARCHAR(50) NOT NULL UNIQUE CHECK (TypeDescription IN ('Book', 'Journal', 'DVD', 'Other Media')),
	Volume INT NOT NULL DEFAULT 0);



--- Author table
CREATE TABLE Author (
    AuthorID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL
	CONSTRAINT UQ_Author UNIQUE (FirstName, LastName));



--- Library catalogue table																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																									
CREATE TABLE LibraryCatalogue (
	  CatalogueNo INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
	  ItemTitle NVARCHAR(255) NOT NULL,
	  ItemTypeID INT NOT NULL,
	  AuthorID INT NOT NULL,
	  YearOfPublication INT NOT NULL,
	  ISBN INT NULL,
	  NumberofCopies INT NOT NULL,
	  CONSTRAINT FK_ItemType FOREIGN KEY (ItemTypeID) REFERENCES ItemType(ItemTypeID),
	  CONSTRAINT CK_BookOnlyISBN CHECK (ItemTypeID = 1 OR ISBN IS NULL),
	  CONSTRAINT fk_author FOREIGN KEY (AuthorID) REFERENCES Author(AuthorID));



--- Inventory table
CREATE TABLE Inventory (
	  Inventoryid INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	  CatalogueNo INT NOT NULL,
	  DateAdded DATE NOT NULL CHECK ([DateAdded] <= GETDATE()),
	  Dateremoved date null,
	  CurrentStatus VARCHAR(20) NOT NULL CHECK (CurrentStatus IN ('on loan', 'overdue', 'available', 'lost', 'removed')),
	  CONSTRAINT fk_catalogue FOREIGN KEY (CatalogueNo) REFERENCES LibraryCatalogue(CatalogueNo));


--- Members table
CREATE TABLE Members (
	MembershipID INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
	FirstName NVARCHAR(50) NOT NULL,
	LastName NVARCHAR(50) NOT NULL,
	DateOfBirth DATE NOT NULL,
	AddressID INT NOT NULL,
	Email NVARCHAR(50) UNIQUE,
	Telephone NVARCHAR(20) UNIQUE,
	MembershipStartDate DATE DEFAULT(GETDATE()) NOT NULL,
	MembershipStatus NVARCHAR(20) not null  CHECK (MembershipStatus IN ('Active', 'Inactive')),
	MembershipEndDate DATE NULL,
	UserName NVARCHAR(50) NOT NULL UNIQUE,
	PasswordHash BINARY(64) not null,
	Salt UNIQUEIDENTIFIER,
	CONSTRAINT CK_MembershipEndDate CHECK (MembershipEndDate >= MembershipStartDate OR MembershipEndDate IS NULL),
	CONSTRAINT CK_Email CHECK (Email LIKE '%_@_%._%'),
	CONSTRAINT CK_Telephone CHECK (LEN(Telephone) = 11),
	CONSTRAINT CK_DateOfBirth CHECK (DATEDIFF(YEAR, DateOfBirth, GETDATE()) >= 14),
	CONSTRAINT FK_Address FOREIGN KEY (AddressID) REFERENCES Address(AddressID),
	CONSTRAINT CK_Password CHECK (LEN(PasswordHash) >= 8 AND 
									PasswordHash LIKE '%[A-Z]%' AND 
									PasswordHash LIKE '%[a-z]%' AND 
									PasswordHash LIKE '%[0-9]%'));


--- LoanHistory table
CREATE TABLE LoanHistory (
    LoanID INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    MembershipID INT NOT NULL,
    InventoryId INT NOT NULL,
    LoanDate DATE NOT NULL,
    DueDate DATE NOT NULL,
    ReturnDate DATE,
    CONSTRAINT FK_LoanHistory_MembershipID FOREIGN KEY (MembershipID) REFERENCES Members(MembershipID),
    CONSTRAINT FK_LoanHistory_InventoryId FOREIGN KEY (InventoryId) REFERENCES Inventory(InventoryId),
    CONSTRAINT CHK_LoanHistory_LoanDate CHECK (LoanDate <= DueDate),
    CONSTRAINT CK_LoanHistory_DueDate CHECK (DueDate >= LoanDate),
    CONSTRAINT CHK_LoanHistory_ReturnDate CHECK (ReturnDate IS NULL OR LoanDate <= ReturnDate));



--- OverdueFine table
CREATE TABLE OverdueFine (
	MembershipID INT NOT NULL,
    LoanID INT NOT NULL,
    NumberofDaysOverdue INT NOT NULL,
    Overduefine DECIMAL(10,2) NOT NULL,
    OverdueBalanceRemaining DECIMAL(10,2) NULL,
    CONSTRAINT FK_OverdueFine_Loan FOREIGN KEY (LoanID) REFERENCES LoanHistory(LoanID),
    CONSTRAINT FK_OverdueFine_Membership FOREIGN KEY (MembershipID) REFERENCES Members (MembershipID),
    CONSTRAINT CHK_OverdueFine_NumberofDaysOverdue CHECK (NumberofDaysOverdue >= 0),
    CONSTRAINT CHK_OverdueFine_Overduefine CHECK (Overduefine >= 0),
    CONSTRAINT CHK_OverdueFine_Overduebalanceremaining CHECK (Overduebalanceremaining >= 0));



--- Repayment table
CREATE TABLE Repayment (
    RepaymentID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    LoanID INT NOT NULL,
    RepaymentMethod VARCHAR(50) NOT NULL CHECK (RepaymentMethod IN ('Cash', 'Card')),
    RepaymentAmount DECIMAL(10, 2) NOT NULL CHECK (RepaymentAmount >= 0),
	RepaymentDateTime DATETIME DEFAULT GETDATE() NOT NULL,
	CONSTRAINT FK_Repayment_Loan FOREIGN KEY (LoanID) REFERENCES LoanHistory(LoanID));


