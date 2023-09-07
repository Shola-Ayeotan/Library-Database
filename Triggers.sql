


SELECT name, create_date, modify_date
FROM sys.triggers;



------ TRIGGERING UPDATE OF CURRENT STATUS UPON LOAN RETURN
		CREATE TRIGGER trig_LoanReturn
		ON LoanHistory
		AFTER UPDATE
		AS
		BEGIN
			SET NOCOUNT ON;
		BEGIN TRY
		BEGIN TRANSACTION;
			-- if the ReturnDate has been updated
			IF UPDATE(ReturnDate)
		BEGIN
			-- Then Update the current status in inventory table
			UPDATE Inventory
			SET CurrentStatus = 'Available'
			FROM inserted i
			WHERE Inventory.InventoryID = i.InventoryID;
		END
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
		ROLLBACK TRANSACTION;
		END CATCH;
		END;





------ TRIGGERING INSERT OF OVERDUE FINE RECORD
		CREATE TRIGGER trig_OverdueFines
		ON LoanHistory
		AFTER INSERT, UPDATE
		AS
		BEGIN
		SET NOCOUNT ON;
		BEGIN TRY
		BEGIN TRANSACTION;
			IF GETDATE() > (SELECT DueDate FROM inserted)
		BEGIN
			INSERT INTO OverdueFine (MembershipID, LoanID, NumberofDaysOverdue, OverdueFine)
			SELECT MembershipID, LoanID, DATEDIFF(day, DueDate, GETDATE()) AS NumberofDaysOverdue, 
			(DATEDIFF(day, DueDate, GETDATE()) * 0.1) AS OverdueFine
			FROM inserted
			WHERE ReturnDate IS NULL;

			UPDATE Inventory 
			SET CurrentStatus = 'Overdue' 
			WHERE InventoryID IN 
			(SELECT l.inventoryid from inserted i 
			JOIN Loanhistory l 
			ON i.loanid = l.loanid);

		COMMIT TRANSACTION;
		END
		END TRY
		BEGIN CATCH
		ROLLBACK TRANSACTION;
		THROW;
		END CATCH;
		END;







------ TRIGGERING UPDATE OF NUMBER OF COPIES
		CREATE TRIGGER trig_NumberofCopies
		ON Inventory
		AFTER INSERT, UPDATE, DELETE
		AS
		BEGIN
		BEGIN TRY
		BEGIN TRANSACTION
			DECLARE @CatalogueNo INT
			DECLARE @CopyCount INT
				-- get the CatalogueNo from the Inventory table
			SELECT @CatalogueNo = CatalogueNo FROM inserted
				
				-- count the number of copies for the CatalogueNo in the Inventory table
			SELECT @CopyCount = COUNT(*) FROM Inventory WHERE CatalogueNo = @CatalogueNo

				-- update the LibraryCatalogue table with the most recent copy count
			UPDATE LibraryCatalogue SET NumberofCopies = @CopyCount WHERE CatalogueNo = @CatalogueNo
		COMMIT TRANSACTION
		END TRY
		BEGIN CATCH
		ROLLBACK TRANSACTION;
		THROW;
		END CATCH
		END




------ UPDATING VOLUME OF ITEM TYPES
		CREATE TRIGGER trig_VolumeCount
		ON Inventory
		AFTER INSERT, UPDATE, DELETE
		AS
		BEGIN
		SET NOCOUNT ON;
		BEGIN TRY
		BEGIN TRANSACTION;
			UPDATE ItemType
			SET Volume = (SELECT COUNT(*) 
			FROM Inventory i
			JOIN LibraryCatalogue lc
			ON i.CatalogueNo = lc.CatalogueNo
			WHERE i.CurrentStatus NOT IN ('lost', 'removed')
			AND ItemType.ItemTypeID = lc.ItemTypeID);

		COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
		ROLLBACK TRANSACTION;
		END CATCH;
		END;

