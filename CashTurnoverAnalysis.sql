-- cash turnover summary

select 

[DeliveryDateKey],
[OrderVolume],
[OrderValue],
[DespatchDateKey],
[ContentValue],
CustomerKey,
[Customer Number],
[Customer Name],
[Customer Type],
[Customer Status],
[Customer Group],
[Level 2 Customer Name],
[Level 3 Customer Name],
[Level 4 Customer Name],
100 as [Gross Turnover],
100 as [Total Turnover],
100 as [Gross Value],
100 as [Cash In],
100 as [Cash Out],
[ContentValue],
[Order Batch Number],
[Bank Name],
[Total Coin Value],
[Total Note Value],
[History Period],
[History Date]




from view_CashOrderReport vcor 