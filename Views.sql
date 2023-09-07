



------- VIEWING HISTORY OF LOANS
		CREATE VIEW vw_LoanHistory
		AS
		SELECT l.LoanID, m.MembershipID, iv.InventoryID, lc.ItemTitle, it.TypeDescription, 
			   l.DueDate, l.ReturnDate, o.OverdueFine, o.OverdueBalanceRemaining
		FROM LoanHistory AS l
		RIGHT JOIN Members AS m ON l.MembershipID = m.MembershipID
		LEFT JOIN OverdueFine AS o ON l.LoanID = o.LoanID
		JOIN Inventory AS iv ON l.InventoryID = iv.InventoryID
		JOIN LibraryCatalogue AS lc ON iv.CatalogueNo = lc.CatalogueNo
		JOIN ItemType AS it ON it.ItemTypeID = lc.ItemTypeID;
		



----- VIEWING MEMBER DETAILS
		CREATE VIEW vw_MemberDetails 
		AS
		SELECT m.MembershipID, m.FirstName, m.LastName, m.Email, m.Telephone, m.UserName, 
		A.AddressLine1, A.AddressLine2, A.City, A.PostalCode, m.MembershipStartDate, m.MembershipStatus, m.MembershipEndDate
		FROM Members m
		INNER JOIN Address A ON m.AddressID = A.AddressID;



----- VIEWING AVAILABLE ITEMS IN LIBRARY
		CREATE VIEW AvailableItems 
		AS
		SELECT i.InventoryID, lc.CatalogueNo, lc.ItemTitle, lc.AuthorID, lc.YearOfPublication
		FROM Inventory i
		INNER JOIN LibraryCatalogue lc ON i.CatalogueNo = lc.CatalogueNo
		WHERE i.CurrentStatus = 'Available'



