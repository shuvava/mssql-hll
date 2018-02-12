CREATE FUNCTION [dbo].[update_hash] (
  @Bitmask binary(4096), -- varbinary(MAX),
  @hash binary(8)
)
returns binary(4096)
AS 
BEGIN   
	declare @p smallint = 12 -- should be between 4 and 16
	declare @_hash_range_bit smallint  = 64
	declare @max_rank smallint = @_hash_range_bit - @p
	declare @m smallint = 4096 --1 << p
	declare @reg_index smallint 
	declare @hash_rev binary(8) = CAST(REVERSE(@hash) as  binary(8))
	declare @bits bigint
	declare @_get_rank tinyint
	SET @reg_index = CAST(SUBSTRING(@hash_rev, 7, 2)as int) & cast(@m-1 as int) 
	SET @bits = CAST(SUBSTRING(@hash_rev, 1, 7)as bigint) / power(2,@p-8)
	SET @_get_rank = @max_rank- (64-dbo.get_index(CAST(@bits as binary(8)),0))+1

   declare @val int
   declare @inx int
   SET @inx = @reg_index + 1
   set @val = CONVERT(int, SUBSTRING(@Bitmask, @inx, 1))
   IF @_get_rank < = @val
   BEGIN
      return @Bitmask
   END
   return SUBSTRING(@Bitmask, 1, @inx - 1) +CONVERT(varbinary(1), @_get_rank) +  SUBSTRING(@Bitmask, @inx + 1, @m - @inx)
END
