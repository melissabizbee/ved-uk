CREATE PROCEDURE GetRecordsBetweenDates
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SELECT * 
    FROM dbo.view_DepositReport_Summary 
    WHERE [History Date] BETWEEN @StartDate AND @EndDate;
END;
