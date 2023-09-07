

--- IDENTIFYING LOANS DUE IN FIVE DAYS
		CREATE FUNCTION UpcomingDues()
			RETURNS @UpcomingDues 
			TABLE (LoanID INT,
				   ItemTitle VARCHAR(100),
				   DueDate DATE)
			AS
			BEGIN
				INSERT INTO @UpcomingDues (LoanID, ItemTitle, DueDate)
				SELECT lh.LoanID, lc.ItemTitle, lh.DueDate
				FROM LoanHistory lh
				JOIN Inventory iv ON lh.InventoryID = iv.InventoryID
				JOIN LibraryCatalogue lc ON iv.CatalogueNo = lc.CatalogueNo
				WHERE lh.ReturnDate IS NULL 
					AND lh.DueDate > GETDATE() 
					AND lh.DueDate <= DATEADD(day, 5, GETDATE())
				RETURN
			END




-----  CALCULATING TOTAL LOANS ON SPECIFIC DATES
		CREATE FUNCTION dbo.LoanCount (@loanDate DATE)
		RETURNS INT
		AS
		BEGIN
			DECLARE @totalLoans INT
			SELECT @totalLoans = COUNT(*)
			FROM LoanHistory
			WHERE CONVERT(DATE, LoanDate) = @loanDate
			RETURN @totalLoans
		END





--- RETRIEVING LOAN HISTORY OF MEMBERS
		CREATE FUNCTION LoanHistoryFunc(@MembershipID INT)
		RETURNS TABLE
		AS
		RETURN (
			SELECT lc.ItemTitle AS ItemTitle, lc.CatalogueNo, l.LoanDate, l.DueDate, l.ReturnDate
			FROM LoanHistory l
			INNER JOIN Inventory i ON l.InventoryID = i.InventoryID
			INNER JOIN LibraryCatalogue lc ON i.CatalogueNo = lc.CatalogueNo
			WHERE l.MembershipID = @MembershipID);




