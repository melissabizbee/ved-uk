

    SELECT top 10
    	CustomerKey,
        [Customer Number],
        [Customer Name],
        [Customer Type],
        [Customer Status],
        [Customer Group],
      --  [Level 2 Customer Name],
     --   [Level 3 Customer Name],
      --  [Level 4 Customer Name],
        [Store Reference],
        [BagNumber],
      --  [CustomerSerialNo],
        [DiscrepancyBankAccountKey],
        [History Date],
        [ProcessingDateKey],
        [SealNumber],       
        [Account Number],
        [Sort code],
        [Bank Short Name],
        [Discrepancy Code],
        [Discrepancy Description],
        [Discrepancy Category],
        [Cash Centre Description With Type],
        
       -- sum(MD.[NoteValue]) AS [Note Value],
      --  sum(MD.[NoteVolume]) As [Note Volume],
        [ForeignValue],
        [ForeignVolume],
      --  sum(MD.[ForgeryValue]) AS [ForgeryValue] ,
      --  sum(MD.[ForgeryVolume]) AS [ForgeryVolume],
      --  sum(MD.[ContentValue]) AS [ContentValue],
      --  sum(MD.[ContentVolume]) AS [ContentVolume],
      --  sum(MD.[CashValue]) AS [CashValue],
       [ChequeValue],
  	   [ChequeVolume],
       [DifferenceValue],
       [Shorts],
       
       [Overs],
       [Shorts]+ [Overs] as [Discrepancy Net Value]
       
       [Credit with Differences],
       CAST((DATEADD(MONTH, DATEDIFF(MONTH, 0, vc.[Date]), 0)) AS DATE) AS [Calendar Month]


from view_DiscrepancyReport_Summary vdrs
inner join VaultexCalendar vc 
on vdrs.[History Date] = vc.[Date] 