


----- SEARCHING ITEMS WITH MATCHING CHARACTER STRINGS
		CREATE PROCEDURE CatalogueSearch
		@ItemSearch nvarchar(100)
		AS
		BEGIN
		BEGIN TRY
		BEGIN TRANSACTION
			SELECT * FROM LibraryCatalogue
			WHERE ItemTitle LIKE '%' + @ItemSearch + '%'
			ORDER BY YearOfPublication DESC
		COMMIT TRANSACTION
		END TRY
		BEGIN CATCH
		ROLLBACK TRANSACTION
		THROW
		END CATCH
		END


		


----- ADDING A NEW MEMBER
		CREATE PROCEDURE InsertMember
			@FirstName NVARCHAR(50), @LastName NVARCHAR(50), @DateOfBirth DATE, @Email  NVARCHAR(100), @Telephone NVARCHAR(20),
			@AddressLine1 NVARCHAR(50), @AddressLine2 VARCHAR(50), @City NVARCHAR(50), @PostalCode NVARCHAR(20),
			@UserName NVARCHAR(50), @PasswordHash NVARCHAR(50)
		AS
		DECLARE @salt UNIQUEIDENTIFIER=NEWID()
		BEGIN
		SET NOCOUNT ON;
		BEGIN TRY
		BEGIN TRANSACTION;
			-- Check if address already in database
			DECLARE @AddressID INT;
			SELECT @AddressID = AddressID FROM [dbo].[Address] WHERE AddressLine1 = @AddressLine1 AND PostalCode = @PostalCode;

			-- Else, insert a new row into the Address table
			IF @AddressID IS NULL
		BEGIN
			INSERT INTO Address (AddressLine1, AddressLine2, City, PostalCode)
			VALUES (@AddressLine1,@AddressLine2,@City, @PostalCode);
			SET @AddressID = SCOPE_IDENTITY();
		END;

			-- Insert new member with the assigned addressID and set MembershipStatus as active
			INSERT INTO Members (FirstName, LastName, DateOfBirth, AddressID, Email, Telephone, UserName, PasswordHash, Salt, MembershipStatus)
			VALUES (@FirstName, @LastName, @DateOfBirth, @AddressID, @Email, @Telephone, @UserName, 
			HASHBYTES('SHA2_512', @PasswordHash + CAST(@salt AS NVARCHAR(36))), @Salt, 'Active');
		COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
		ROLLBACK TRANSACTION;
		THROW;
		END CATCH
		END





----- INSERTING NEW CATALOGUE ITEM
		CREATE PROCEDURE InsertCatalogue
		@ItemTitle NVARCHAR(255), @ItemTypeID INT, @YearOfPublication INT, @ISBN INT,
		@NumberofCopies INT, @AuthorFirstName VARCHAR(50), @AuthorLastName VARCHAR(50) 
		AS
		BEGIN
		SET NOCOUNT ON;
		BEGIN TRY
		BEGIN TRANSACTION;
			-- Check if the author already exists
				DECLARE @AuthorID INT;
				SELECT @AuthorID = AuthorID FROM Author WHERE FirstName = @AuthorFirstName AND LastName = @AuthorLastName;
			-- If the author doesn't exist, insert a new row into the Author table
				IF @AuthorID IS NULL
		BEGIN
				INSERT INTO Author (FirstName, LastName)
				VALUES (@AuthorFirstName, @AuthorLastName);
				SET @AuthorID = SCOPE_IDENTITY();
		END
			-- Check if the record already exists in the LibraryCatalogue table
				IF EXISTS (SELECT * FROM [dbo].[LibraryCatalogue] WHERE ItemTitle = @ItemTitle AND ItemTypeID = @ItemTypeID AND AuthorID = @AuthorID)
		BEGIN
				RAISERROR ('This catalog item already exists.', 16, 1);
				RETURN;
		END;
			-- Insert new library catalogue with the assigned author ID and current date
				DECLARE @CatalogueNo INT;
				INSERT INTO LibraryCatalogue (ItemTitle, ItemTypeID, AuthorID, YearOfPublication, ISBN, NumberofCopies)
				VALUES (@ItemTitle, @ItemTypeID, @AuthorID, @YearOfPublication, @ISBN, @NumberofCopies);
				SET @CatalogueNo = SCOPE_IDENTITY();
			
			-- Insert new inventory records for each copy
				DECLARE @i INT = 1;
				WHILE (@i <= @NumberofCopies)
		BEGIN
				INSERT INTO Inventory (CatalogueNo, DateAdded, CurrentStatus)
				VALUES (@CatalogueNo, GETDATE(), 'Available');
				SET @i += 1;
		END;
		COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
		ROLLBACK TRANSACTION;
		THROW;
		END CATCH
		END;




----- ENDING MEMBERSHIP
		CREATE PROCEDURE EndLibraryMembership
			@MembershipID int
		AS
		BEGIN
		BEGIN TRANSACTION;
		BEGIN TRY
		SET NOCOUNT ON;
			-- Update the MembershipStatus and MembershipEndDate for the given MembershipID
			UPDATE Members
			SET MembershipStatus = 'Inactive', MembershipEndDate = GETDATE()
			WHERE MembershipID = @MembershipID;
			-- Display a message indicating that the membership has been ended
			Print 'Library membership ended';
		COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
		ROLLBACK TRANSACTION;
		THROW;
		END CATCH;
		END





----- REACTIVATING MEMBERSHIP 
		CREATE PROCEDURE ReactivateMembership
		@MembershipID INT
		AS
		BEGIN
		SET NOCOUNT ON;
		BEGIN TRY
		BEGIN TRANSACTION;
			IF EXISTS 
			(SELECT * FROM Members WHERE MembershipID = @MembershipID AND MembershipStatus = 'Inactive')
			BEGIN
			UPDATE Members SET MembershipStatus = 'Active', MembershipEndDate = NULL 
			WHERE MembershipID = @MembershipID;
			PRINT 'Membership reactivated successfully.';
			END
			ELSE
			BEGIN
			RAISERROR('This member is either already active or does not exist.', 16, 1);
			ROLLBACK TRANSACTION;
			RETURN;
		END
		COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
		ROLLBACK TRANSACTION;
		THROW;
		END CATCH
		END





----- UPDATING MEMBER DETAILS
		CREATE PROCEDURE UpdateMemberDetails
		@MembershipID INT, @Email NVARCHAR(50) = NULL, @Telephone NVARCHAR(20) = NULL
		AS
		BEGIN
		SET NOCOUNT ON;
		BEGIN TRY
			BEGIN TRANSACTION;
			UPDATE Members
			SET
			Email = COALESCE(@Email, Email),
			Telephone = COALESCE(@Telephone, Telephone)
			WHERE
			MembershipID = @MembershipID;
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
		ROLLBACK TRANSACTION;
		THROW;
		END CATCH;
		END




----- INSERTING NEW COPIES OF ITEM
		CREATE PROCEDURE InsertingInventory
		 @CatalogueNo INT, @NumCopies INT
		AS
		BEGIN
		DECLARE @InventoryId INT;
		BEGIN TRANSACTION;
		BEGIN TRY
			INSERT INTO Inventory (CatalogueNo, DateAdded, CurrentStatus)
			VALUES (@CatalogueNo, GETDATE(), 'Available');
			SET @InventoryId = SCOPE_IDENTITY();
			DECLARE @counter INT = 1;
			WHILE (@counter < @NumCopies)
		BEGIN
			INSERT INTO Inventory (CatalogueNo, DateAdded, CurrentStatus)
			VALUES (@CatalogueNo, GETDATE(), 'Available');
			SET @InventoryId = SCOPE_IDENTITY();
			SET @counter = @counter + 1;
		END
		COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
		ROLLBACK TRANSACTION;
		THROW;
		END CATCH
		END






----- RECORDING MEMBER LOANS
		CREATE PROCEDURE RecordingLoans
			@MembershipID INT, @InventoryID INT
		AS
		BEGIN
		SET NOCOUNT ON;
		BEGIN TRY
		BEGIN TRANSACTION;
			-- Check if the inventory item is available
			DECLARE @InventoryStatus VARCHAR(20);
			SELECT @InventoryStatus = CurrentStatus FROM Inventory WHERE InventoryID = @InventoryID;
			IF @InventoryStatus = 'On Loan'
		BEGIN
			RAISERROR('Item is already on loan.', 16, 1)
			RETURN
		END
			ELSE IF @InventoryStatus IN ('Lost', 'Removed')
		BEGIN
			RAISERROR('This item is no longer available in the library.', 16, 1)
			RETURN
		END
			ELSE
		BEGIN
			-- Insert new loan record
			INSERT INTO LoanHistory (MembershipID, InventoryID, LoanDate, DueDate)
			VALUES (@MembershipID, @InventoryID,  GETDATE(),  DATEADD(DAY, 7, GETDATE()));

			-- Update inventory status to 'Loaned'
			UPDATE Inventory SET CurrentStatus = 'On Loan' WHERE InventoryID = @InventoryID;
		COMMIT TRANSACTION;
			PRINT 'Item loaned successfully.';
		END
		END TRY
			BEGIN CATCH
			ROLLBACK TRANSACTION;
			THROW;
			END CATCH
		END





----- MAKING AN OVERDUE REPAYMENT
		CREATE PROCEDURE sp_MakePayment
		@LoanID int,
		@RepaymentMethod nvarchar(20),
		@RepaymentAmount decimal(10,2)
		AS
		BEGIN
		SET NOCOUNT ON;
		BEGIN TRANSACTION;
			DECLARE @OverdueBalanceRemaining decimal(10,2);
		BEGIN TRY
			-- Calculate the new OverdueBalance
			SELECT @OverdueBalanceRemaining = 
			CASE WHEN r.LoanID IS NOT NULL 
			THEN o.OverdueBalanceRemaining - @RepaymentAmount
			ELSE o.OverdueFine - @RepaymentAmount
		END
			FROM OverdueFine o
			LEFT JOIN Repayment r ON o.LoanID = r.LoanID AND r.RepaymentID = (SELECT MAX(RepaymentID) FROM Repayment WHERE LoanID = @LoanID)
			WHERE o.LoanID = @LoanID;

			-- Check if repayment amount is greater than the overdue balance remaining
			IF (@RepaymentAmount > @OverdueBalanceRemaining)
		BEGIN
			RAISERROR('Repayment amount cannot be greater than the overdue fine.', 16, 1)
			ROLLBACK TRANSACTION;
				RETURN
		END
			-- Insert the new repayment record
			INSERT INTO Repayment (LoanID, RepaymentMethod, RepaymentAmount)
			VALUES (@LoanID, @RepaymentMethod, @RepaymentAmount);
			-- Update the OverdueBalanceRemaining in the OverdueFines table
			UPDATE OverdueFine
			SET OverdueBalanceRemaining = @OverdueBalanceRemaining
			WHERE LoanID = @LoanID;
			
			-- Display a message indicating that the repayment has been recorded
			PRINT 'Repayment recorded successfully'

			COMMIT TRANSACTION;
		END TRY
			BEGIN CATCH
			ROLLBACK TRANSACTION;
			RETURN;
			END CATCH;
		END
	



----- UPDATING WHEN AN ITEM IS RETURNED
		CREATE PROCEDURE ReturnItem
		@LoanID int
		AS
		BEGIN
		BEGIN TRANSACTION;
		BEGIN TRY
			-- Update return date in loan history table
			UPDATE LoanHistory
			SET ReturnDate = GETDATE()
			WHERE LoanID = @LoanID;
		COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
		ROLLBACK TRANSACTION;
		THROW;
		END CATCH;
		END;










