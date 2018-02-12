# T-SQL implementation HyperLogLog  algorithm
## prerequisits
* SQL server 2016 or above
## installation
1. create test db
```sql
CREATE DATABASE [hll-test]
GO
USE [hll-test]
GO
CREATE TABLE [dbo].[sample](
	[id] [int] NOT NULL
)
GO
INSERT INTO [dbo].[sample]
select CAST(RAND() * 10000000  as int) 
GO 1000
```
1. create functions
    1. merge_hashes
    1. update_hash
    1. get_index
    1. hll_get_estimatation
1. install .NET library with CRL implementation of update_hash and merge_hashesfunctions (this step is optional)
```sql
/* Turn advanced options on*/
EXEC sys.sp_configure @configname = 'show advanced options', @configvalue = 1 ;
GO
RECONFIGURE WITH OVERRIDE ;
GO
-- Enable CLR
EXEC sys.sp_configure @configname = 'clr enabled', @configvalue = 1 ;
GO
RECONFIGURE WITH OVERRIDE ;
GO
EXEC sys.sp_configure @configname = 'clr strict security', @configvalue = 0 ;
GO
RECONFIGURE WITH OVERRIDE ;
GO
/* you must to build library at first */
ALTER ASSEMBLY HyperLogLog FROM 'c:\PathWithProject\bin\Debug\HyperLogLog.dll'
WITH permission_set=Safe;
GO
CREATE AGGREGATE hhl_merge (@input binary(4096)) RETURNS binary(4096) 
EXTERNAL NAME [HyperLogLog].[HyperLogLog.hhl_merge]; 
CREATE AGGREGATE hhl_add (@input binary(8)) RETURNS binary(4096) 
EXTERNAL NAME [HyperLogLog].[HyperLogLog.hhl_add]; 
``` 

## usage estimation calculation
```sql
SELECT count(1) FROM [dbo].[sample]
DECLARE @Bitmask_res_tsql binary(4096) = 0 
DECLARE @Bitmask_res_crl binary(4096) = 0

SET @Bitmask_res_tsql = 0
SELECT 
	@Bitmask_res_tsql = dbo.update_hash(@Bitmask_res_tsql,HashBytes('SHA1', cast([id] as varchar))) 
FROM [hll].[dbo].[sample]
select  dbo.hll_get_estimatation(@Bitmask_res_tsql) as 'estimatation'
select count(distinct id), count(1) FROM [dbo].[sample] 

SET @Bitmask_res_crl = 0
SELECT 
	@Bitmask_res_crl = dbo.hhl_add(HashBytes('SHA1', cast([id] as varchar))) 
FROM [hll].[dbo].[sample]
select  dbo.hll_get_estimatation(@Bitmask_res_crl) as 'estimatation'

```
## usage hash merge
```sql
DECLARE @Bitmask_res_tsql binary(4096) = 0 
DECLARE @Bitmask_res_crl binary(4096) = 0 
DECLARE @Bitmask1 binary(4096) = 0 
DECLARE @Bitmask2 binary(4096) = 0 
		SET @Bitmask1 = 0

		SELECT 
			@Bitmask1 = dbo.update_hash(@Bitmask1,HashBytes('SHA1', cast([id] as varchar))) 
		FROM [dbo].[sample]
		order by id 
		OFFSET 0 ROWS FETCH NEXT 500 ROWS ONLY; 

		SELECT 
			@Bitmask2 = dbo.update_hash(@Bitmask2,HashBytes('SHA1', cast([id] as varchar))) 
		FROM [hll].[dbo].[sample]
		order by id 
		OFFSET 500 ROWS FETCH NEXT 4000000 ROWS ONLY; 
select 	@Bitmask_res_tsql = dbo.merge_hashes(@Bitmask1, @Bitmask2)
 select  dbo.hll_get_estimatation(@Bitmask_res_tsql) as 'estimatation', dbo.hll_get_estimatation(@Bitmask1), dbo.hll_get_estimatation(@Bitmask2)
 select count(distinct id), count(1) FROM [dbo].[sample]

 select @Bitmask_res_crl = [dbo].[hhl_merge](hll) from (
 select @Bitmask1 as hll
 union all
 select  @Bitmask2
 )as t

  select  dbo.hll_get_estimatation(@Bitmask_res_crl) as 'estimatation'
```