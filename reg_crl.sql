-- Turn advanced options on
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


ALTER ASSEMBLY HyperLogLog FROM 'c:\HyperLogLog\bin\Debug\HyperLogLog.dll'
WITH permission_set=Safe;
GO
  
CREATE AGGREGATE hhl_merge (@input binary(4096)) RETURNS binary(4096) 
EXTERNAL NAME [HyperLogLog].[HyperLogLog.hhl_merge]; 

CREATE AGGREGATE hhl_add (@input binary(8)) RETURNS binary(4096) 
EXTERNAL NAME [HyperLogLog].[HyperLogLog.hhl_add]; 