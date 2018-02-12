CREATE FUNCTION [dbo].[get_index] (
	@Bitmask binary(8),
	@offset int	= 0
)
returns int
WITH NATIVE_COMPILATION, SCHEMABINDING
AS 
BEGIN  ATOMIC WITH (TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE = N'English') 
	declare @index int = @offset
    declare @byteInx int = 0
	declare @byte tinyint = 0
	declare @len int = 2048*8
	--SET @len = LEN(@Bitmask)*8
	while @index<@len
	BEGIN
        IF @byteInx < @index/8+1
        BEGIN
            SET @byteInx = @index/8+1
            SET @byte = SUBSTRING(@Bitmask, @byteInx, 1)
        END
        
		if (@byte & power(2, 7-@index % 8)) >0
		BEGIN
		return 	@index
		END
 		set @index = @index + 1
	END 
	return @index
END
/*
select 
dbo.get_index( cast(cast(511 as smallint) as  binary(4)),0 )
, cast(cast(511 as smallint) as  binary(4)) 
, case when dbo.get_index( cast(cast(511 as smallint) as  binary(4)),0 )= 23 then 'correct' else 'error'end 'test result'
*/