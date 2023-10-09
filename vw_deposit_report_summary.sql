
-- the purpose of this view is to bring in only what we need for the Tableau Deposit report. CTE's are used in case we need to do further aggregations, filters etc in order to optimise the data 

-- this view can populate a table for Tableau to connect to if performance is stil an issue with read/ write. Due to the level of granularity required for Tableau i.e. days, bag number, we may have to do this.

WITH customer AS (
    SELECT 
        C.[Customer Group],
        C.[Customer Name],
        C.[Customer Number],
        C.[Customer Status],
        C.[Customer Type],
        C.CustomerKey,
        C.[Store Reference]
        
    FROM [dbo].[Customer] C
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
        CASE WHEN  CustomerValue >0 THEN TotalValue - CustomerValue END AS Overs
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
    SELECT distinct
    	CUS.CustomerKey,
        CUS.[Customer Number],
        CUS.[Customer Name],
        CUS.[Customer Type],
        CUS.[Customer Status],
        CUS.[Customer Group],
        CUS.[Store Reference],
        MD.[SlipDate],
        MD.[BagNumber],
        MD.[CustomerSerialNo],
        MD.[DiscrepancyBankAccountKey],
        MD.HistoryDateKey AS [History Date],
        MD.[ProcessingDateKey],
        MD.[SealNumber],       
        BA.[Account Number],
        BA.[Sort code],
        BA.[Bank Short Name],
        DC.[Discrepancy Code],
        DC.[Discrepancy Description],
        DC.[Discrepancy Category],
        CC.[Cash Centre Description With Type],
        
        sum(MD.[NoteValue]) AS [Note Value],
        sum(MD.[NoteVolume]) As [Note Volume],
        sum(MD.[ForeignValue]) AS [Foreign Value],
        sum(MD.[ForeignVolume]) AS [Foreign Volume],
        sum(MD.[ForgeryValue]) AS [Forgery Value] ,
        sum(MD.[ForgeryVolume]) AS [Forgery Volume],
        sum(MD.[ContentValue]) AS [Content Value],
        sum(MD.[ContentVolume]) AS [Content Volume],
        sum(MD.[CashValue]) AS [Cash Value],
        sum(MD.[ChequeValue]) AS [Cheque Value],
        sum(MD.[ChequeVolume]) AS [Cheque Volume],
        sum(MD.[CoinValue]) AS [Coin Value],
        sum(MD.[CoinVolume]) AS [Coin Volume],
        sum(MD.[CustomerValue]) AS [Customer Value],
        sum(MD.[DifferenceValue]) AS [Difference Value],
        sum(MD.[TotalValue]) AS [Total Value],
        sum(CONT.[GBP Value]) AS [GBP Value],
        sum(MD.Shorts) AS [Shorts],
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
        CUS.[Store Reference],
        MD.[SlipDate],
        MD.[BagNumber],
        MD.[CustomerSerialNo],
        MD.[DiscrepancyBankAccountKey],
        MD.HistoryDateKey,
        MD.[ProcessingDateKey],
        MD.[SealNumber],       
        BA.[Account Number],
        BA.[Sort code],
        BA.[Bank Short Name],
        DC.[Discrepancy Code],
        DC.[Discrepancy Description],
        DC.[Discrepancy Category],
        CC.[Cash Centre Description With Type]


)

SELECT *,
        CAST((DATEADD(MONTH, DATEDIFF(MONTH, 0, [History Date]), 0)) AS DATE) AS [History Period] -- required for drill-down


 FROM final;
