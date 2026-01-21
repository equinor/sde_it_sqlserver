CREATE_FUNCTION(SCHEMA.add_StDataSource) 
   (@lDatasource nvarchar(100)
   ,@lCurrentSourceSet nvarchar(200)
   )
  returns nvarchar
/*****************************************************************
* Package Info
* Author          : $Author: JOTHOR $
* Original Date   : $Date: 02.07.2021 $
* Last Modified   : $Modtime:  $
* Archive Name    : $Archive:  $
* Description     : $Header:  $
* Revision History: $Revision:  $
* Workfile        : $Workfile: $
* Copyright info  : Copyright (c), Equinor ASA,Norway. $Date:  $
*****************************************************************
* Description
* Maintain the st_source attribute, adds a source to current st_datasource
* Leave a lDelimiter at the end
*****************************************************************
* Log
* Date   Description                                        Done by
* 300323 Altered to sqlserver code                          JOTHOR
*****************************************************************/     
as
begin
   STANDARD_VARIABLE;   
   declare @lStr nvarchar(100);
   -- The below to be moved to the constant function or fetch from configuration table.
   declare @lDelimiter char(1) = ';';
   declare @lMaxSetSize integer = 5;

   if (@lCurrentSourceSet is null)-- then
      return @lDatasource+@lDelimiter;

   ------------------------------------------------
   -- Add a delimiter to the end. Makes it easier to test
   -- If already in first position, return.
   -- If nr of systems exceeds limit, strip off the last one and add new value
   -- If none of the above, add new value
   ------------------------------------------------
   if (substring(reverse(trim(@lCurrentSourceSet)),1,1) != @lDelimiter) -- then
      set @lStr = @lCurrentSourceSet+@lDelimiter;
   else
      set @lStr = @lCurrentSourceSet;

   if (substring(@lStr,1,SCHEMA.instr_func(@lStr,@lDelimiter,0,1) - 1) = @lDatasource)-- then
      return @lStr;
   else if ((len(@lStr) - len(replace(@lStr, '@lDelimiter', ''))) >= @lMaxSetSize)-- then
      return @lDatasource+@lDelimiter+substring(@lStr,1,SCHEMA.instr_func(@lStr,@lDelimiter,0,@lMaxSetSize-1));  
   else
      return @lDatasource+@lDelimiter+@lStr;

   return null;
/*EXCEPTION_BLOCK
 THROW_EXCEPTION_HANDLER;
*/
END_CREATE_FUNCTION;
