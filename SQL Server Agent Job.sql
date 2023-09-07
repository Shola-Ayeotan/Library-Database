

--- DAILY INSERT OF ONLY FRESHLY DUE FINES
	INSERT INTO OverdueFine (MembershipID, LoanID, NumberofDaysOverdue, Overduefine)
	SELECT MembershipID, LoanID, DATEDIFF(day, DueDate, GETDATE()) AS NumberofDaysOverdue, 
				(DATEDIFF(day, DueDate, GETDATE()) * 0.1) AS OverdueFine
	FROM LoanHistory lh
	WHERE ReturnDate IS NULL
	AND NOT EXISTS (SELECT 1 FROM OverdueFine o WHERE o.LoanID = lh.LoanID);



--- DAILY UPDATE OF OVERDUE STATUS (IF NOT ALREADY UPDATED)
	UPDATE Inventory
	SET CurrentStatus = 'Overdue'
	FROM Inventory i
	LEFT JOIN 
	(SELECT DISTINCT InventoryID
	FROM LoanHistory
	WHERE DueDate < GETDATE()
	AND ReturnDate IS NULL) as lh
	ON i.InventoryID = lh.InventoryID
	WHERE i.CurrentStatus != 'Overdue'
	AND lh.InventoryID IS NOT NULL;



--- CALCULATING DAILY OVERDUE FINES
	UPDATE OverdueFine
	SET OverdueFine = DATEDIFF(day, L.DueDate, GETDATE()) * 0.1,
		OverdueBalanceRemaining = (DATEDIFF(day, L.DueDate, GETDATE()) * 0.1) - (SELECT SUM(RepaymentAmount) FROM Repayment WHERE LoanID = L.LoanID)
	FROM LoanHistory L 
	JOIN OverdueFine O ON L.LoanID = O.LoanID
	WHERE L.ReturnDate IS NULL;


--- UPDATING THE NUMBER OF DAYS DAILY 
	UPDATE OverdueFine
	SET NumberofDaysOverdue = DATEDIFF(day, DueDate, GETDATE())
	FROM loanhistory L JOIN OVERDUEFINE O
	ON L.LOANID = O.LOANID
	WHERE ReturnDate IS NULL


