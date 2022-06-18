CREATE FUNCTION [dbo].[get_count_nonzerobucket] (
	@Bitmask binary(4096) = 0
)
RETURNS SMALLINT
BEGIN
    DECLARE @counter int  = 0

    WHILE @Bitmask > 0
    SELECT @counter +=@Bitmask % 2,  @Bitmask /= 2

    RETURN @counter
END
