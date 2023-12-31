-- view_customerRLS

with unpivot_level_0 as (

SELECT DISTINCT Level0CustomerKey as cusKey, Variable, Value
	FROM BridgeCustomerHierarchy bch 
	UNPIVOT
	(
	  Value FOR Variable IN (Level1CustomerKey, Level2CustomerKey, Level3CustomerKey,Level4CustomerKey,Level5CustomerKey,Level6CustomerKey,Level7CustomerKey)
	) AS Unpvt


),


unpivot_level_1 as (

SELECT Level1CustomerKey as cusKey, Variable, Value
	FROM BridgeCustomerHierarchy bch 
	--where Level0CustomerKey = 126641
	UNPIVOT
	(
	  Value FOR Variable IN ( Level2CustomerKey, Level3CustomerKey,Level4CustomerKey,Level5CustomerKey,Level6CustomerKey,Level7CustomerKey)
	) AS Unpvt

),

unpivot_level_2 as (

SELECT Level2CustomerKey as cusKey, Variable, Value
	FROM BridgeCustomerHierarchy bch 
	--where Level0CustomerKey = 126641
	UNPIVOT
	(
	  Value FOR Variable IN (Level3CustomerKey,Level4CustomerKey,Level5CustomerKey,Level6CustomerKey,Level7CustomerKey)
	) AS Unpvt

),

unpivot_level_3 as (

SELECT Level3CustomerKey as cusKey, Variable, Value
	FROM BridgeCustomerHierarchy bch 
	UNPIVOT
	(
	  Value FOR Variable IN (Level4CustomerKey,Level5CustomerKey,Level6CustomerKey,Level7CustomerKey)
	) AS Unpvt

),

unpivot_level_4 as (

SELECT Level4CustomerKey as cusKey, Variable, Value
	FROM BridgeCustomerHierarchy bch 
	UNPIVOT
	(
	  Value FOR Variable IN (Level5CustomerKey,Level6CustomerKey,Level7CustomerKey)
	) AS Unpvt

),

unpivot_level_5 as (

SELECT Level5CustomerKey as cusKey, Variable, Value
	FROM BridgeCustomerHierarchy bch 
	UNPIVOT
	(
	  Value FOR Variable IN (Level6CustomerKey,Level7CustomerKey)
	) AS Unpvt

),

unpivot_level_6 as (

SELECT Level6CustomerKey as cusKey, Variable, Value
	FROM BridgeCustomerHierarchy bch 
	UNPIVOT
	(
	  Value FOR Variable IN (Level7CustomerKey)
	) AS Unpvt

),
all_levels as (

select * from unpivot_level_0
union all
select * from unpivot_level_1
union all
select * from unpivot_level_2
union all
select * from unpivot_level_3
union all
select * from unpivot_level_4
union all
select * from unpivot_level_5
union all
select * from unpivot_level_6




),





rename_vw as (

select 
distinct
cusKey as CustomerKey_RLS, -- use this for rls
SUBSTRING(variable,6,1) as Level,
value as CustomerKey

-- us this to join to customer in tableau
from all_levels

)

select c.CustomerKey, c.[Customer Number] ,c.[Customer Name], vchr.Level, 
case when CustomerKey_RLS is null then c.CustomerKey ELSE CustomerKey_RLS end as CustomerKey_RLS,
case when vchr.CustomerKey is null then c.CustomerKey ELSE vchr.CustomerKey end as CustomerKey

from Customer c
left join rename_vw vchr 
on c.CustomerKey = vchr.CustomerKey_RLS  






