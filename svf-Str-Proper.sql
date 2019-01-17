--Original From: https://stackoverflow.com/users/1570000/john-cappelletti
--Via: https://stackoverflow.com/a/54240287/6167855

CREATE FUNCTION [dbo].[svf-Str-Proper] (@S varchar(250))
Returns varchar(max)
As
Begin
    Set @S = ' '+Replace(Replace(Lower(@S),'   ',' '),'  ',' ')+' '
    ;with cte1 as (Select * From (Values(' '),('-'),('/'),('\'),('['),('{'),('('),('.'),(','),('&'),(' Mc'),(' O''')) A(P))
         ,cte2 as (Select * From (Values('A'),('B'),('C'),('D'),('E'),('F'),('G'),('H'),('I'),('J'),('K'),('L'),('M')
                                       ,('N'),('O'),('P'),('Q'),('R'),('S'),('T'),('U'),('V'),('W'),('X'),('Y'),('Z')
                                       ,('LLC'),('PhD'),('MD'),('DDS')
                                 ) A(S))
         ,cte3 as (Select F = Lower(A.P+B.S),T = A.P+B.S From cte1 A Cross Join cte2 B ) 
    Select @S = replace(@S,F,T) From cte3
    Return rtrim(ltrim(@S))
End
-- Syntax :  Select [dbo].[svf-Str-Proper]('old mcdonald phd,dds llc b&o railroad')
