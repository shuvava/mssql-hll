CREATE FUNCTION dbo.merge_hashes(
	@hash_first binary (2048) = 0,
	@hash_second binary (2048) = 0
)
RETURNS  binary (2048)
WITH NATIVE_COMPILATION, SCHEMABINDING
AS 
BEGIN  ATOMIC WITH (TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE = N'English') 
   declare @inx int = 1
   declare @len int = 2049
   declare @val_first int
   declare @val_second int 
   WHILE @inx < @len
   BEGIN
	  SET @val_first = CONVERT(int, SUBSTRING(@hash_first, @inx, 1))
	  SET @val_second = CONVERT(int, SUBSTRING(@hash_second, @inx, 1))
	  
	  IF @val_second > @val_first
	  BEGIN
	     SET @hash_first = SUBSTRING(@hash_first, 1, @inx - 1) +CONVERT(varbinary(1), @val_second) +  SUBSTRING(@hash_first, @inx + 1, 2048 - @inx)
	  END
   END

   return  @hash_first
END
GO