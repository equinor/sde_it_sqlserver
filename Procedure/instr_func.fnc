/*****************************************************************
*  Procedure Info
*   Author          : $Author: unknown $
*   Original Date   : $Date: $
*   Last Modified   : $Modtime: $
*   Archive Name    : $Archive: $
*   Description     : $Header:  $
*   Revision History: $Revision: $
*   Tag name        : $Name:  $
*   Workfile        : $Workfile: $
*****************************************************************
* Description
* User-defined function to implement Oracle "instr" in SQL Server
*  select sde_it.instr_func('Boston', 'o', 1, 2);
*  select sde_it.instr_func('Boston', 'B',default,default) -- use default values.
*
* charindex: https://learn.microsoft.com/en-us/sql/t-sql/functions/charindex-transact-sql?view=sql-server-ver16
*****************************************************************
* Log
* Date   Description                                           Done by
* 191222 Added this header to the file                         JOTHOR
*****************************************************************/
CREATE_FUNCTION(SCHEMA.instr_func) (@str varchar(8000)
         , @substr varchar(255)
         , @start int = 0
         , @occurrence int = 1 
         )
  returns int
  as
begin
   STANDARD_VARIABLE;
   declare @found int = @occurrence
          ,@pos int = @start;

   while 1=1 
   begin
      -- find the next occurrence
      set @pos = charindex(@substr, @str, @pos);
 
      -- nothing found
      if @pos is null or @pos = 0
         return @pos;
 
      -- the required occurrence found
      if @found = 1
         break;
 
      -- prepare to find another one occurrence
      set @found = @found - 1;
      set @pos = @pos + 1;
   end
 
   return @pos;
END_FUNCTION;
