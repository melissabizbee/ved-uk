
-- cash order report aggregated by history date for drill-down


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

),

container AS (
    SELECT 
        CC.[GBP Value],
        CC.ContainerContentKey,
        CC.ContainerContentGroup
        
    FROM [dbo].[ContainerContent] CC
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
      MC.[CustomerKey],
	  MC.[OrderDateKey] ,
	  MC.[HistoryDateKey],
	  MC.[Order Batch Number],
	  MC.[DeliveryDateKey],
	  MC.[DespatchDateKey],
  CAST((DATEADD(MONTH, DATEDIFF(MONTH, 0, OrderDateKey), 0)) AS DATE) AS [Order Period],
        CAST((DATEADD(MONTH, DATEDIFF(MONTH, 0, HistoryDateKey), 0)) AS DATE) AS [History Period],
      DATEADD(dd, -(DATEPART(dw, HistoryDateKey)-1), HistoryDateKey) [History WeekStart],
     DATEADD(dd, 7-(DATEPART(dw, HistoryDateKey)), HistoryDateKey) [History WeekEnd],
      CONT.[GBP Value],
      CONT.ContainerContentGroup,
      CA.[Carrier Name],
      CA.[Carrier Code],
      MC.[ContentValue],
	  MC.[ContentVolume],
	  MC.[OrderValue],
	  MC.[OrderVolume],
	  CASE WHEN ContainerContentGroup = 'Coin' then [ContentValue] end as [Coin Value],
	  CASE WHEN ContainerContentGroup = 'Note' then [ContentValue] end as [Note Value]

	
	FROM [dbo].[MergedCashOrder] MC
	INNER JOIN container CONT ON MC.ContainerContentKey = CONT.ContainerContentKey
	INNER JOIN Carrier CA ON MC.CarrierKey = CA.CarrierKey 

    WHERE MC.HistoryDateKey >= DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 13, 0)


),


bankaccount AS (
    SELECT 
        BA.[Account Number],
        BA.BankAccountKey,
        BA.[Sort code],
        BA.[Bank Name]
    FROM [dbo].[BankAccount] BA
),

cashcentre AS (
    SELECT 
        CC.[Cash Centre Description With Type],
        CC.CashCentreKey
    FROM [dbo].[CashCentre] CC
),

cashorderatt AS (

		SELECT 
		  [CashOrderAttribute].[CashOrderAttributeKey],
		  [CashOrderAttribute].[Order Channel]
		
		FROM [dbo].[CashOrderAttribute] [CashOrderAttribute]
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
        MC.[Order Period],
		MC.[OrderDateKey] ,
		MC.[Order Batch Number],
		MC.[DeliveryDateKey],
		MC.[DespatchDateKey],
		MC.[HistoryDateKey] AS [History Date],
        BA.[Account Number],
        BA.[Sort code],
        BA.[Bank Name],
        COA.[Order Channel],
        CC.[Cash Centre Description With Type],
        MC.[History Period],
        MC.[History WeekStart],
        MC.[History WeekEnd],
        MC.[Carrier Name],
        MC.[Carrier Code],
        sum(MC.[GBP Value]) as [GPB Value],
        sum(MC.[OrderValue]) as [OrderValue],
		sum(MC.[OrderVolume]) as [OrderVolume],
		sum(MC.[ContentValue]) as [ContentValue],
		sum(MC.[ContentVolume]) as [ContentVolume],
		sum(MC.[Coin Value]) as [Coin Value],
		sum(MC.[Note Value]) as [Note Value]
		
    FROM  customer CUS 
    INNER JOIN MergedCashOrder MC ON CUS.CustomerKey = MC.CustomerKey
    INNER JOIN bankaccount BA ON MC.BankAccountKey = BA.BankAccountKey
    INNER JOIN cashcentre CC ON MC.CashCentreKey = CC.CashCentreKey
    INNER JOIN cashorderatt COA ON MC.CashOrderAttributeKey = COA.CashOrderAttributeKey
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
        MC.[Order Period],
		MC.[OrderDateKey] ,
		MC.[Order Batch Number],
		MC.[DeliveryDateKey],
		MC.[DespatchDateKey],
		MC.[HistoryDateKey],
        BA.[Account Number],
        BA.[Sort code],
        BA.[Bank Name],
        COA.[Order Channel],
        CC.[Cash Centre Description With Type],
        MC.[History Period],
        MC.[History WeekStart],
        MC.[History WeekEnd],
        MC.[Carrier Name],
        MC.[Carrier Code]
    
)

SELECT * FROM final;
