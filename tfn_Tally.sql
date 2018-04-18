USE [AdminTools]
GO




CREATE FUNCTION [dbo].[tfn_Tally]
(
@NumOfRows BIGINT = 1000000 
,@StartWith BIGINT = 1563984
)
/* ============================================================================
07/20/2017 JL, Created. Capable of creating a sequense of rows 
                ranging from -10,000,000,000,000,000 to 10,000,000,000,000,000
============================================================================ */
RETURNS TABLE WITH SCHEMABINDING AS 
RETURN
WITH 
        cte_n1 (n) AS (SELECT 1 FROM (VALUES (1),(1),(1),(1),(1),(1),(1),(1),(1),(1)) n (n)),   -- 10 rows
        cte_n2 (n) AS (SELECT 1 FROM cte_n1 a CROSS JOIN cte_n1 b),                             -- 100 rows
        cte_n3 (n) AS (SELECT 1 FROM cte_n2 a CROSS JOIN cte_n2 b),                             -- 10,000 rows
        cte_n4 (n) AS (SELECT 1 FROM cte_n3 a CROSS JOIN cte_n3 b),                             -- 100,000,000 rows
        cte_Tally (n) AS (
            SELECT TOP (@NumOfRows)
                (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1) + @StartWith
            FROM 
                cte_n4 a CROSS JOIN cte_n4 b                                                    -- 10,000,000,000,000,000 rows
            )
    SELECT 
        t.n
    FROM 
        cte_Tally t;



GO


