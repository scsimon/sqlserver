USE [AdminTools]
GO


 CREATE FUNCTION [dbo].[fnTallyProg]
/**********************************************************************************************************************
 Purpose:
 Given a start value, end value, and increment, create a sequencial list of integers.
 Programmers Notes:
 1. The increment can be negative if the start value is greater than the end value. In other words, it can count down
    as well as up.

 Revison History:
 Rev 00 - 18 Feb 2017 - Jeff Moden
        - Rewrite original to take start, end, and increment parameters.
**********************************************************************************************************************/
        (
         @pStart     BIGINT
        ,@pEnd       BIGINT
        ,@pIncrement BIGINT
        )
RETURNS TABLE WITH SCHEMABINDING AS
 RETURN WITH 
 E01(N)   AS (SELECT NULL FROM (VALUES (NULL),(NULL),(NULL),(NULL),(NULL),(NULL),(NULL),(NULL),(NULL),(NULL))E0(N)) --10 rows
,E04(N)   AS (SELECT NULL FROM E01 a CROSS JOIN E01 b CROSS JOIN E01 c CROSS JOIN E01 d) --10 Thousand rows
,E16(N)   AS (SELECT NULL FROM E04 a CROSS JOIN E04 b CROSS JOIN E04 c CROSS JOIN E04 d) --10 Quadrillion rows, which is crazy
,Tally(N) AS (SELECT TOP (ABS((@pEnd-@pStart+@pIncrement)/@pIncrement))
                     N = ROW_NUMBER() OVER (ORDER BY (SELECT NULL))
                FROM E16
               WHERE (@pStart<=@pEnd AND @pIncrement > 0)
                  OR (@pStart>=@pEnd AND @pIncrement < 0)
               ORDER BY N
             )
      SELECT TOP (ABS((@pEnd-@pStart+@pIncrement)/@pIncrement))
             N = (t.N-1)*@pIncrement+@pStart
        FROM Tally t
       ORDER BY t.N
;


GO


