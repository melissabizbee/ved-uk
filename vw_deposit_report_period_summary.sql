
 -- deposit report aggregated by month year for Tableau Charts


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
    INNER JOIN [dbo].CustomerHierarchy ch ON c.CustomerKey = ch.CustomerKey
    where [Customer Deleted On] is null
 ) ,

mergeddeposit AS (
    SELECT 
        MD.[BagNumber],
        MD.[BankAccountKey],
        MD.[ContainerContentKey],
        MD.CashCentreKey,
        MD.[CashValue],
        MD.[ChequeValue],
        MD.[ChequeVolume],
        MD.[CoinValue],
        MD.[CoinVolume],
        MD.[ContentVolume],
        MD.[ContentValue],
        MD.CustomerKey,
        MD.[CustomerSerialNo],
        MD.[CustomerValue],
        MD.[DifferenceValue],
        MD.[DiscrepancyBankAccountKey],
        MD.FactDepositId,
        MD.[ForeignValue],
        MD.[ForeignVolume],
        MD.[ForgeryValue],
        MD.[ForgeryVolume],
        MD.HistoryDateKey,
        MD.[NoteValue],
        MD.[NoteVolume],
        MD.[SealNumber],
        MD.[TotalValue],
        MD.[OriginalBagnumber],
        MD.[SlipDate],
        MD.[ProcessingDateKey],
        CASE WHEN  CustomerValue <0 THEN TotalValue - CustomerValue END AS Shorts,
        CASE WHEN  CustomerValue >0 THEN TotalValue - CustomerValue END AS Overs,
        
        CAST((DATEADD(MONTH, DATEDIFF(MONTH, 0, HistoryDateKey), 0)) AS DATE) AS [History Period],
		CAST((DATEADD(MONTH, DATEDIFF(MONTH, 0, SlipDate), 0)) AS DATE) AS [Slip Period],
		CAST((DATEADD(MONTH, DATEDIFF(MONTH, 0, ProcessingDateKey), 0)) AS DATE) AS [Processing Period],
		
        DATEADD(dd, -(DATEPART(dw, HistoryDateKey)-1), HistoryDateKey) [History WeekStart],
        DATEADD(dd, 7-(DATEPART(dw, HistoryDateKey)), HistoryDateKey) [History WeekEnd],
        DATEADD(dd, -(DATEPART(dw, SlipDate)-1), SlipDate) [Slip WeekStart],
        DATEADD(dd, 7-(DATEPART(dw, SlipDate)), SlipDate) [Slip WeekEnd],
        DATEADD(dd, -(DATEPART(dw, ProcessingDateKey)-1), ProcessingDateKey) [Processing WeekStart],
        DATEADD(dd, 7-(DATEPART(dw, ProcessingDateKey)), ProcessingDateKey) [Processing WeekEnd]

    FROM [dbo].[MergedDeposit] MD
    WHERE MD.HistoryDateKey >= DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 13, 0)
),

mergeddeposit_all AS (
    SELECT 
        'All' as [BagNumber],
        'All' as [SealNumber],
        'All' as [CustomerSerialNo],
        MD.[BankAccountKey],
        MD.[ContainerContentKey],
        MD.CashCentreKey,
        MD.[CashValue],
        MD.[ChequeValue],
        MD.[ChequeVolume],
        MD.[CoinValue],
        MD.[CoinVolume],
        MD.[ContentVolume],
        MD.[ContentValue],
        MD.CustomerKey,
        MD.[CustomerValue],
        MD.[DifferenceValue],
        MD.[DiscrepancyBankAccountKey],
        MD.FactDepositId,
        MD.[ForeignValue],
        MD.[ForeignVolume],
        MD.[ForgeryValue],
        MD.[ForgeryVolume],
        MD.HistoryDateKey,
        MD.[NoteValue],
        MD.[NoteVolume],

        MD.[TotalValue],
        MD.[SlipDate],
        MD.[ProcessingDateKey],
        CASE WHEN  CustomerValue <0 THEN TotalValue - CustomerValue END AS Shorts,
        CASE WHEN  CustomerValue >0 THEN TotalValue - CustomerValue END AS Overs,
        
        CAST((DATEADD(MONTH, DATEDIFF(MONTH, 0, HistoryDateKey), 0)) AS DATE) AS [History Period],
		CAST((DATEADD(MONTH, DATEDIFF(MONTH, 0, SlipDate), 0)) AS DATE) AS [Slip Period],
		CAST((DATEADD(MONTH, DATEDIFF(MONTH, 0, ProcessingDateKey), 0)) AS DATE) AS [Processing Period],
		
        DATEADD(dd, -(DATEPART(dw, HistoryDateKey)-1), HistoryDateKey) [History WeekStart],
        DATEADD(dd, 7-(DATEPART(dw, HistoryDateKey)), HistoryDateKey) [History WeekEnd],
        DATEADD(dd, -(DATEPART(dw, SlipDate)-1), SlipDate) [Slip WeekStart],
        DATEADD(dd, 7-(DATEPART(dw, SlipDate)), SlipDate) [Slip WeekEnd],
        DATEADD(dd, -(DATEPART(dw, ProcessingDateKey)-1), ProcessingDateKey) [Processing WeekStart],
        DATEADD(dd, 7-(DATEPART(dw, ProcessingDateKey)), ProcessingDateKey) [Processing WeekEnd]

    FROM [dbo].[MergedDeposit] MD
    WHERE MD.HistoryDateKey >= DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 13, 0)
),

bankaccount AS (
    SELECT 
        BA.[Account Number],
        BA.BankAccountKey,
        BA.[Sort code],
        BA.[Bank Short Name]
    FROM [dbo].[BankAccount] BA
),

discrepancy_code AS ( 
    SELECT 
        D.[Discrepancy Category],
        D.[Discrepancy Code],
        D.[Discrepancy Description],
        D.DiscrepancyKey
    FROM dbo.Discrepancy D 

),

discrepancy_bridge AS (
    SELECT 
        BDD.DiscrepancyKey,
        BDD.FactDepositID
        
    FROM dbo.BridgeDepositDiscrepancy BDD
    WHERE BDD.HistoryDateKey >= DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 13, 0)

),

cashcentre AS (
    SELECT 
        CC.[Cash Centre Description With Type],
        CC.CashCentreKey
    FROM [dbo].[CashCentre] CC
),

container AS (
    SELECT 
        CC.[GBP Value],
        CC.ContainerContentKey
    FROM [dbo].[ContainerContent] CC
),

final AS (
    SELECT DISTINCT
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
       -- MD.[Slip WeekStart],
       -- MD.[Slip WeekEnd],
        MD.[BagNumber],
        MD.[CustomerSerialNo],
        MD.[DiscrepancyBankAccountKey],
      --  MD.[History WeekStart],
      --  MD.[History WeekEnd],
      --  MD.[Processing WeekStart],
      --  MD.[Processing WeekEnd],
        MD.[SealNumber],       
        BA.[Account Number],
        BA.[Sort code],
        BA.[Bank Short Name],
        DC.[Discrepancy Code],
        DC.[Discrepancy Description],
        DC.[Discrepancy Category],
        CC.[Cash Centre Description With Type],
        MD.[History Period],
        MD.[Processing Period],
        MD.[Slip Period],
        
        
        sum(MD.[NoteValue]) AS [Note Value],
        sum(MD.[NoteVolume]) As [Note Volume],
        sum(MD.[ForeignValue]) AS [ForeignValue],
        sum(MD.[ForeignVolume]) AS [ForeignVolume],
        sum(MD.[ForgeryValue]) AS [ForgeryValue] ,
        sum(MD.[ForgeryVolume]) AS [ForgeryVolume],
        sum(MD.[ContentValue]) AS [ContentValue],
        sum(MD.[ContentVolume]) AS [ContentVolume],
        sum(MD.[CashValue]) AS [CashValue],
        sum(MD.[ChequeValue]) AS [ChequeValue],
        sum(MD.[ChequeVolume]) AS [ChequeVolume],
        sum(MD.[CoinValue]) AS [CoinValue],
        sum(MD.[CoinVolume]) AS [CoinVolume],
        sum(MD.[CustomerValue]) AS [CustomerValue],
        sum(MD.[DifferenceValue]) AS [DifferenceValue],
        sum(MD.[TotalValue]) AS [TotalValue],
        sum(CONT.[GBP Value]) AS [GBP Value],
        sum(MD. Shorts) AS [Shorts],
        sum(MD.Overs) AS [Overs]
        

    FROM  customer CUS 
    INNER JOIN mergeddeposit MD ON CUS.CustomerKey = MD.CustomerKey
    INNER JOIN bankaccount BA ON MD.BankAccountKey = BA.BankAccountKey
    LEFT JOIN discrepancy_bridge DISC ON MD.FactDepositId = DISC.FactDepositId
    LEFT JOIN discrepancy_code DC ON DISC.DiscrepancyKey = DC.DiscrepancyKey
    INNER JOIN cashcentre CC ON MD.CashCentreKey = CC.CashCentreKey
    INNER JOIN container CONT ON MD.ContainerContentKey = CONT.ContainerContentKey
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
      --  MD.[Slip WeekStart],
      --  MD.[Slip WeekEnd],
        MD.[BagNumber],
        MD.[CustomerSerialNo],
        MD.[DiscrepancyBankAccountKey],
       -- MD.[History WeekStart],
      --  MD.[History WeekEnd],
      --  MD.[Processing WeekStart],
      --  MD.[Processing WeekEnd],
        MD.[SealNumber],       
        BA.[Account Number],
        BA.[Sort code],
        BA.[Bank Short Name],
        DC.[Discrepancy Code],
        DC.[Discrepancy Description],
        DC.[Discrepancy Category],
        CC.[Cash Centre Description With Type],
        MD.[History Period],
        MD.[Processing Period],
        MD.[Slip Period]
        

),
final_all AS ( 

SELECT DISTINCT
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
       -- MD.[Slip WeekStart],
       -- MD.[Slip WeekEnd],
        MD.[BagNumber],
        MD.[CustomerSerialNo],
        MD.[DiscrepancyBankAccountKey],
      --  MD.[History WeekStart],
      --  MD.[History WeekEnd],
      --  MD.[Processing WeekStart],
      --  MD.[Processing WeekEnd],
        MD.[SealNumber],       
        BA.[Account Number],
        BA.[Sort code],
        BA.[Bank Short Name],
        DC.[Discrepancy Code],
        DC.[Discrepancy Description],
        DC.[Discrepancy Category],
        CC.[Cash Centre Description With Type],
        MD.[History Period],
        MD.[Processing Period],
        MD.[Slip Period],
        
        
        sum(MD.[NoteValue]) AS [Note Value],
        sum(MD.[NoteVolume]) As [Note Volume],
        sum(MD.[ForeignValue]) AS [ForeignValue],
        sum(MD.[ForeignVolume]) AS [ForeignVolume],
        sum(MD.[ForgeryValue]) AS [ForgeryValue] ,
        sum(MD.[ForgeryVolume]) AS [ForgeryVolume],
        sum(MD.[ContentValue]) AS [ContentValue],
        sum(MD.[ContentVolume]) AS [ContentVolume],
        sum(MD.[CashValue]) AS [CashValue],
        sum(MD.[ChequeValue]) AS [ChequeValue],
        sum(MD.[ChequeVolume]) AS [ChequeVolume],
        sum(MD.[CoinValue]) AS [CoinValue],
        sum(MD.[CoinVolume]) AS [CoinVolume],
        sum(MD.[CustomerValue]) AS [CustomerValue],
        sum(MD.[DifferenceValue]) AS [DifferenceValue],
        sum(MD.[TotalValue]) AS [TotalValue],
        sum(CONT.[GBP Value]) AS [GBP Value],
        sum(MD. Shorts) AS [Shorts],
        sum(MD.Overs) AS [Overs]
        

    FROM  customer CUS 
    INNER JOIN mergeddeposit MD ON CUS.CustomerKey = MD.CustomerKey
    INNER JOIN bankaccount BA ON MD.BankAccountKey = BA.BankAccountKey
    LEFT JOIN discrepancy_bridge DISC ON MD.FactDepositId = DISC.FactDepositId
    LEFT JOIN discrepancy_code DC ON DISC.DiscrepancyKey = DC.DiscrepancyKey
    INNER JOIN cashcentre CC ON MD.CashCentreKey = CC.CashCentreKey
    INNER JOIN container CONT ON MD.ContainerContentKey = CONT.ContainerContentKey
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
      --  MD.[Slip WeekStart],
      --  MD.[Slip WeekEnd],
        MD.[BagNumber],
        MD.[CustomerSerialNo],
        MD.[DiscrepancyBankAccountKey],
       -- MD.[History WeekStart],
      --  MD.[History WeekEnd],
      --  MD.[Processing WeekStart],
      --  MD.[Processing WeekEnd],
        MD.[SealNumber],       
        BA.[Account Number],
        BA.[Sort code],
        BA.[Bank Short Name],
        DC.[Discrepancy Code],
        DC.[Discrepancy Description],
        DC.[Discrepancy Category],
        CC.[Cash Centre Description With Type],
        MD.[History Period],
        MD.[Processing Period],
        MD.[Slip Period]
        

),

final_last as (

select * from final 
union all
select * from final_all

)


SELECT * FROM final_last;
