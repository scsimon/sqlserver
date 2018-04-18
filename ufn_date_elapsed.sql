/**************************************************************************************
Credit: https://stackoverflow.com/users/1570000/john-cappelletti

**************************************************************************************/



CREATE FUNCTION [dbo].[ufn_date_elapsed] (@D1 DateTime,@D2 DateTime)
Returns Table
Return (
    with cteBN(N)   as (Select 1 From (Values(1),(1),(1),(1),(1),(1),(1),(1),(1),(1)) N(N)),
         cteRN(R)   as (Select Row_Number() Over (Order By (Select NULL))-1 From cteBN a,cteBN b,cteBN c),
         cteYY(N,D) as (Select Max(R),Max(DateAdd(YY,R,@D1))From cteRN R Where DateAdd(YY,R,@D1)<=@D2),
         cteMM(N,D) as (Select Max(R),Max(DateAdd(MM,R,D))  From (Select Top 12 R From cteRN Order By 1) R, cteYY P Where DateAdd(MM,R,D)<=@D2),
         cteDD(N,D) as (Select Max(R),Max(DateAdd(DD,R,D))  From (Select Top 31 R From cteRN Order By 1) R, cteMM P Where DateAdd(DD,R,D)<=@D2),
         cteHH(N,D) as (Select Max(R),Max(DateAdd(HH,R,D))  From (Select Top 24 R From cteRN Order By 1) R, cteDD P Where DateAdd(HH,R,D)<=@D2),
         cteMI(N,D) as (Select Max(R),Max(DateAdd(MI,R,D))  From (Select Top 60 R From cteRN Order By 1) R, cteHH P Where DateAdd(MI,R,D)<=@D2),
         cteSS(N,D) as (Select Max(R),Max(DateAdd(SS,R,D))  From (Select Top 60 R From cteRN Order By 1) R, cteMI P Where DateAdd(SS,R,D)<=@D2)

    Select [Years]   = cteYY.N
          ,[Months]  = cteMM.N
          ,[Days]    = cteDD.N
          ,[Hours]   = cteHH.N
          ,[Minutes] = cteMI.N
          ,[Seconds] = cteSS.N
          --,[Elapsed] = Format(cteYY.N,'0000')+':'+Format(cteMM.N,'00')+':'+Format(cteDD.N,'00')+' '+Format(cteHH.N,'00')+':'+Format(cteMI.N,'00')+':'+Format(cteSS.N,'00')
     From  cteYY,cteMM,cteDD,cteHH,cteMI,cteSS
)
--Max 1000 years
--Select * from [dbo].[tvf-Date-Elapsed] ('1991-09-12 21:00:00.000',GetDate())
--Select * from [dbo].[tvf-Date-Elapsed] ('2017-01-01 20:30:15','2018-02-05 22:58:35')
