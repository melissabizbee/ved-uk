
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

),

mergedcashorder AS (
 SELECT 

	/*
	  [MergedCashOrder].[CalculatedCharge] AS [CalculatedCharge],
	  [MergedCashOrder].[CalculatedChargingVolume] AS [CalculatedChargingVolume],
	  [MergedCashOrder].[CalculatedUnitPrice] AS [CalculatedUnitPrice],
	  [MergedCashOrder].[CarrierTimes] AS [CarrierTimes],
	  [MergedCashOrder].[CreatedOn] AS [CreatedOn],
	  [MergedCashOrder].[DespatchTimeKey] AS [DespatchTimeKey],
	  [MergedCashOrder].[FactCashOrderContentID] AS [FactCashOrderContentID],
	  [MergedCashOrder].[FactCashOrderId] AS [FactCashOrderId],
	  [MergedCashOrder].[FactMergedCashOrderID] AS [FactMergedCashOrderID],
	  [MergedCashOrder].[MakeUpDateKey] AS [MakeUpDateKey],
	  [MergedCashOrder].[MakeUpTimeKey] AS [MakeUpTimeKey],
	  [MergedCashOrder].[NumberOfPacks] AS [NumberOfPacks],
	  [MergedCashOrder].[OrderBagNumbers] AS [OrderBagNumbers],
	  [MergedCashOrder].[OrderCageNumbers] AS [OrderCageNumbers],
	  [MergedCashOrder].[OrderContainerTypeKey] AS [OrderContainerTypeKey],
	  [MergedCashOrder].[OrderExchangeSerialNumber] AS [OrderExchangeSerialNumber],
	  [MergedCashOrder].[OrderSerialNumber] AS [OrderSerialNumber],
	    [MergedCashOrder].[PricingPointKey] AS [PricingPointKey],
	  [MergedCashOrder].[VaultDateKey] AS [VaultDateKey],
	  [MergedCashOrder].[VaultTimeKey] AS [VaultTimeKey]
	  
	  */
	  
	  MC.BankAccountKey,
	  MC.CashCentreKey,
	  MC.CashOrderAttributeKey,
	  MC.ContainerContentKey,
	--  MC.[CarrierKey] AS [CarrierKey],
	  MC.[ContentValue],
	  MC.[ContentVolume],
	  MC.[CustomerKey],
	  MC.[OrderDateKey] ,
	  MC.[HistoryDateKey],
	  MC.[Order Batch Number],
	  MC.[DeliveryDateKey],
	  MC.[DespatchDateKey],
	  MC.[OrderValue],
	  MC.[OrderVolume]
	
	FROM [dbo].[MergedCashOrder] MC
    WHERE MC.HistoryDateKey >= DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 13, 0)
),

bankaccount AS (
    SELECT 
        BA.[Account Number],
        BA.BankAccountKey,
        BA.[Sort code]
    FROM [dbo].[BankAccount] BA
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

cashorderatt AS (

		SELECT 
		  [CashOrderAttribute].[CashOrderAttributeKey],
		  [CashOrderAttribute].[Order Channel]
		
		FROM [dbo].[CashOrderAttribute] [CashOrderAttribute]
),
		
		
final AS (
    SELECT 
    	CUS.CustomerKey,
        CUS.[Customer Number],
        CUS.[Customer Name],
        CUS.[Customer Type],
        CUS.[Customer Status],
        CUS.[Customer Group],
        CUS.[Store Reference],
        MC.[ContentValue],
		MC.[ContentVolume],
		MC.[OrderDateKey] ,
		MC.[Order Batch Number],
		MC.[DeliveryDateKey],
		MC.[DespatchDateKey],
		MC.[OrderValue],
		MC.[OrderVolume],
		MC.[HistoryDateKey] AS [History Date],
        BA.[Account Number],
        BA.[Sort code],
        COA.[Order Channel],
        CC.[Cash Centre Description With Type],
        CONT.[GBP Value]
    FROM  customer CUS 
    INNER JOIN MergedCashOrder MC ON CUS.CustomerKey = MC.CustomerKey
    INNER JOIN bankaccount BA ON MC.BankAccountKey = BA.BankAccountKey
    INNER JOIN cashcentre CC ON MC.CashCentreKey = CC.CashCentreKey
    INNER JOIN container CONT ON MC.ContainerContentKey = CONT.ContainerContentKey
    INNER JOIN cashorderatt COA ON MC.CashOrderAttributeKey = COA.CashOrderAttributeKey
    
)

SELECT * FROM final;
