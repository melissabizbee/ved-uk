-- CASH TURNOVER ANALYSIS

-- DIMENSIONS / FILTERS

-- Cash order report aggregated by history date for drill-down

WITH customer AS (
  SELECT 
    C.[Customer Group],
    C.[Customer Name],
    C.[Customer Number],
    C.[Customer Status],
    C.[Customer Type],
    C.CustomerKey,
    C.[Store Reference],
    CH.[Level 2 Customer Name],
    CH.[Level 3 Customer Name],
    CH.[Level 4 Customer Name]
  FROM [dbo].[Customer] C
  INNER JOIN [dbo].CustomerHierarchy CH ON C.CustomerKey = CH.CustomerKey
  WHERE [Customer Deleted On] IS NULL
),

bankaccount AS (
  SELECT 
    BA.[Account Number],
    BA.BankAccountKey,
    BA.[Sort code],
    BA.[Bank Name],
    BA.[Bank Short Name]
  FROM [dbo].[BankAccount] BA
),

cal AS (
  SELECT 
    VaultexCalendarID,
    [Date],
    CAST((DATEADD(MONTH, DATEDIFF(MONTH, 0, [Date]), 0)) AS DATE) AS [Date Period]
  FROM VaultexCalendar vc 
  WHERE [Date] >= DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 13, 0)
),

-- AGGREGATED FACT TABLES

cash_base AS (
  SELECT 
    CUS.CustomerKey,
    CUS.[Customer Number],
    CUS.[Customer Name],
    CUS.[Customer Type],
    CUS.[Customer Status],
    CUS.[Customer Group],
    CUS.[Level 2 Customer Name],
    CUS.[Level 3 Customer Name],
    CUS.[Level 4 Customer Name],
    CUS.[Store Reference],
    BA.[BankAccountKey],
    BA.[Account Number],
    BA.[Sort code],     
    BA.[Bank Short Name],
    CONT.ContainerContentGroup,
    C.[Carrier Name] AS [Cash Carrier Name],
    C.[Carrier Code] AS [Cash Carrier Code],
    CAST((DATEADD(MONTH, DATEDIFF(MONTH, 0, OrderDateKey), 0)) AS DATE) AS [Order Period],
    CAST((DATEADD(MONTH, DATEDIFF(MONTH, 0, HistoryDateKey), 0)) AS DATE) AS [History Period], 
    MC.[OrderDateKey],
    MC.[Order Batch Number],
    COA.[Order Channel] AS [Cash Order Channel],
    CC.[Cash Centre Description With Type],
    COUNT(DISTINCT MC.[FactCashOrderId]) AS [Total Cash Orders],
    SUM(MC.[OrderValue]) AS [Cash Out / Order Value], -- Cash out Value
    SUM(MC.[OrderVolume]) AS [Cash Out / Order Volume],
    SUM(MC.[ContentValue]) AS [Cash Content Value],
    SUM(MC.[ContentVolume]) AS [Cash Content Volume],
    SUM(CONT.[GBP Value]) AS [Cash Denomination / GBP Value],
    CASE WHEN ContainerContentGroup = 'Coin' THEN SUM([ContentValue]) END AS [Coin Value],
    CASE WHEN ContainerContentGroup = 'Note' THEN SUM([ContentValue]) END AS [Note Value]
  FROM  MergedCashOrder MC
  INNER JOIN customer CUS ON CUS.CustomerKey = MC.CustomerKey
  INNER JOIN bankaccount BA ON MC.BankAccountKey = BA.BankAccountKey
  INNER JOIN CashCentre CC ON MC.CashCentreKey = CC.CashCentreKey
  INNER JOIN CashOrderAttribute COA ON MC.CashOrderAttributeKey = COA.CashOrderAttributeKey
  INNER JOIN ContainerContent CONT ON MC.ContainerContentKey = CONT.ContainerContentKey
  INNER JOIN Carrier C ON MC.CarrierKey = C.CarrierKey 
  WHERE MC.HistoryDateKey >= DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 13, 0)
  GROUP BY 
    CUS.CustomerKey,
    CUS.[Customer Number],
    CUS.[Customer Name],
    CUS.[Customer Type],
    CUS.[Customer Status],
    CUS.[Customer Group],
    CUS.[Level 2 Customer Name],
    CUS.[Level 3 Customer Name],
    CUS.[Level 4 Customer Name],
    CUS.[Store Reference],
    BA.[BankAccountKey],
    BA.[Account Number],
    BA.[Sort code],     
    BA.[Bank Short Name],
    CONT.ContainerContentGroup,
    C.[Carrier Name],
    C.[Carrier Code],
    MC.HistoryDateKey,  
    MC.[OrderDateKey],
    MC.[Order Batch Number],
    COA.[Order Channel],
    CC.[Cash Centre Description With Type]
),

deposit_base AS (
  SELECT 
    CUS.CustomerKey,
    CUS.[Customer Number],
    CUS.[Customer Name],
    CUS.[Customer Type],
    CUS.[Customer Status],
    CUS.[Customer Group],
    CUS.[Level 2 Customer Name],
    CUS.[Level 3 Customer Name],
    CUS.[Level 4 Customer Name],
    CUS.[Store Reference],
    BA.[BankAccountKey],
    BA.[Account Number],
    BA.[Sort code],     
    BA.[Bank Short Name],
    CAST((DATEADD(MONTH, DATEDIFF(MONTH, 0, MD.ProcessingDateKey), 0)) AS DATE) AS [Processing Period],
    CAST((DATEADD(MONTH, DATEDIFF(MONTH, 0, MD.HistoryDateKey), 0)) AS DATE) AS [History Period],
    MD.[ProcessingDateKey],
    MD.[CustomerSerialNo],
    DC.[Discrepancy Code],
    DC.[Discrepancy Description],
    DC.[Discrepancy Category],
    CC.[Cash Centre Description With Type],
    CONT.ContainerContentGroup,
    CONT.[GBP Value] AS [Deposit Denomination],
    MD.[SealNumber],
    MD.[BagNumber],
    MD.[FactDepositId],
    SUM(MD.[ContentValue]) AS [ContentValue], --- average and sum
    SUM(MD.[ContentVolume]) AS [ContentVolume],
    SUM(MD.[CustomerValue]) AS [CustomerValue], -- average and sum
    SUM(MD.[DifferenceValue]) AS [DifferenceValue],
    SUM(MD.[TotalValue]) AS [TotalValue],
    CASE WHEN MD.CustomerValue < 0 THEN SUM(TotalValue - CustomerValue) END AS Shorts,
    CASE WHEN MD.CustomerValue > 0 THEN SUM(TotalValue - CustomerValue) END AS Overs,
    CASE WHEN MD.DifferenceValue > 0 THEN sum(MD.TotalValue) ELSE 0 END AS [Credit with Differences]
  FROM  mergeddeposit MD 
  INNER JOIN Customer CUS ON CUS.CustomerKey = MD.CustomerKey
  INNER JOIN bankaccount BA ON MD.BankAccountKey = BA.BankAccountKey
  LEFT JOIN BridgeDepositDiscrepancy DISC ON MD.FactDepositId = DISC.FactDepositId
  LEFT JOIN Discrepancy DC ON DISC.DiscrepancyKey = DC.DiscrepancyKey
  INNER JOIN CashCentre CC ON MD.CashCentreKey = CC.CashCentreKey
  INNER JOIN ContainerContent CONT ON MD.ContainerContentKey = CONT.ContainerContentKey
  WHERE MD.HistoryDateKey >= DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 13, 0)
  GROUP BY 
    CUS.CustomerKey,
    CUS.[Customer Number],
    CUS.[Customer Name],
    CUS.[Customer Type],
    CUS.[Customer Status],
    CUS.[Customer Group],
    CUS.[Level 2 Customer Name],
    CUS.[Level 3 Customer Name],
    CUS.[Level 4 Customer Name],
    CUS.[Store Reference],
    BA.[BankAccountKey],
    BA.[Account Number],
    BA.[Sort code],     
    BA.[Bank Short Name],
    MD.HistoryDateKey,
    MD.[ProcessingDateKey], 
    [CustomerSerialNo],
    MD.[FactDepositId],
    [Discrepancy Code],
    [Discrepancy Description],
    [Discrepancy Category],
    [Cash Centre Description With Type],
    [ContainerContentGroup],
    CONT.[GBP Value],
    [SealNumber],
    [BagNumber],
    CustomerValue,
    TotalValue,
    [DifferenceValue]
),

-- DATA NEEDS TO BE SCAFFOLDED FOR FILTERING IN TABLEAU I.E. YOU CANNOT HAVE 2 CUSTOMER FIELDS

scaffold_cash AS ( 
  SELECT 
    DISTINCT
    CAL.[Date Period],
    CUST.CustomerKey,
    CUST.[Customer Number],
    CUST.[Customer Name],
    CUST.[Customer Type],
    CUST.[Customer Status],
    CUST.[Customer Group],
    CUST.[Level 2 Customer Name],
    CUST.[Level 3 Customer Name],
    CUST.[Level 4 Customer Name],
    CUST.[Store Reference],
    BA.[BankAccountKey],
    BA.[Account Number],
    BA.[Sort code],     
    BA.[Bank Short Name],
    CB.ContainerContentGroup,
    CB.[Cash Carrier Name],
    CB.[Cash Carrier Code],
    CB.[Order Period],
    CB.[History Period], 
    CB.[OrderDateKey],
    CB.[Order Batch Number],
    CB.[Cash Order Channel],
    CB.[Cash Centre Description With Type],
    CB.[Total Cash Orders],
    CB.[Cash Out / Order Value], -- Cash out Value
    CB.[Cash Out / Order Volume],
    CB.[Cash Content Value],
    CB.[Cash Content Volume],
    CB.[Cash Denomination / GBP Value],
    CB.[Coin Value],
    CB.[Note Value]
  FROM cash_base CB
  RIGHT JOIN customer CUST ON CB.[CustomerKey] = CUST.[CustomerKey] 
  RIGHT JOIN bankaccount BA ON CB.[BankAccountKey] = BA.[BankAccountKey] 
  RIGHT JOIN cal ON CAL.[Date Period] = CB.[History Period]
),

scaffold_deposit AS (
  SELECT 
    DISTINCT
    CAL.[Date Period],
    CUST.CustomerKey,
    CUST.[Customer Number],
    CUST.[Customer Name],
    CUST.[Customer Type],
    CUST.[Customer Status],
    CUST.[Customer Group],
    CUST.[Level 2 Customer Name],
    CUST.[Level 3 Customer Name],
    CUST.[Level 4 Customer Name],
    CUST.[Store Reference],
    BA.[BankAccountKey],
    BA.[Account Number],
    BA.[Sort code],     
    BA.[Bank Short Name],
    [Processing Period],
    [History Period],
    [ProcessingDateKey], 
    [CustomerSerialNo],
    [Discrepancy Code],
    [Discrepancy Description],
    [Discrepancy Category],
    [Cash Centre Description With Type],
    [ContainerContentGroup],
    SUM([Deposit Denomination]) AS [Deposit Denomination],
    COUNT(DISTINCT [FactDepositID]) AS [Total Deposits],
    COUNT(DISTINCT [SealNumber]) AS [Outer Bag Count],
    COUNT(DISTINCT [BagNumber]) AS [Bag Count],
    SUM([ContentValue]) AS [Total Bag Value],
    AVG([ContentValue]) AS [Average Bag Value],
    SUM([ContentVolume]) AS [Total Content Volume],
    SUM([CustomerValue]) AS [Total Customer Value],
    SUM([DifferenceValue]) AS [Total Discrepancy],
    SUM([TotalValue]) AS [Cash Out / Total Deposit Value],
    SUM([Shorts]) AS [Shorts],
    SUM([Overs]) AS [Overs],
    SUM([Credit with Differences]) AS [Credit with Differences]
  FROM customer CUST
  LEFT JOIN deposit_base DB ON DB.[CustomerKey] = CUST.[CustomerKey]
  RIGHT JOIN bankaccount BA ON DB.[BankAccountKey] = BA.[BankAccountKey] 
  RIGHT JOIN cal ON CAL.[Date Period] = DB.[History Period]
  GROUP BY 
    CAL.[Date Period],
    CUST.CustomerKey,
    CUST.[Customer Number],
    CUST.[Customer Name],
    CUST.[Customer Type],
    CUST.[Customer Status],
    CUST.[Customer Group],
    CUST.[Level 2 Customer Name],
    CUST.[Level 3 Customer Name],
    CUST.[Level 4 Customer Name],
    CUST.[Store Reference],
    BA.[BankAccountKey],
    BA.[Account Number],
    BA.[Sort code],     
    BA.[Bank Short Name],
    [Processing Period],
    [History Period],
    [ProcessingDateKey], 
    [CustomerSerialNo],
    [FactDepositId],
    [Discrepancy Code],
    [Discrepancy Description],
    [Discrepancy Category],
    [Cash Centre Description With Type],
    [ContainerContentGroup],
    [Deposit Denomination],
    [SealNumber],
    [BagNumber],
    CustomerValue,
    TotalValue,
    [DifferenceValue]
)

-- JOIN SCAFFOLDS AND SELECT DIMENSIONS FOR FILTER EITHER CASH/DEPOSIT, DOESN'T MATTER

SELECT * FROM scaffold_deposit;
