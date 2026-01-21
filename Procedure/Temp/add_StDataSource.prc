CREATE_FUNCTION(add_StDataSource)(lDatasource varchar2,lCurrentSourceSet varchar2)
  return varchar2
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
* Date  Description                                      Done by
*
*****************************************************************/     
is
   STANDARD_VARIABLE;   
   lStr varchar2(100);
   -- The below to be moved to gli_constant
   lDelimiter char(1) := ';';
   lMaxSetSize integer := 5;
begin
   if (lCurrentSourceSet is null) then
      return lDatasource||lDelimiter;
   end if;

   ------------------------------------------------
   -- Add a delimiter to the end. Makes it easier to test
   -- If already in first position, return.
   -- If nr of systems exceeds limit, strip off the last one and add new value
   -- If none of the above, add new value
   ------------------------------------------------
   if (substr(lCurrentSourceSet,length(lCurrentSourceSet)) != lDelimiter) then
      lStr := lCurrentSourceSet||lDelimiter;
   else
      lStr := lCurrentSourceSet;
   end if;

   if (substr(lStr,1,instr(lStr,lDelimiter) - 1) = lDatasource) then
      return lStr;
   elsif (regexp_count(lStr,lDelimiter) >= lMaxSetSize) then
      return lDatasource||lDelimiter||substr(lStr,1,instr(lStr,lDelimiter,1,lMaxSetSize-1));  
   else
      return lDatasource||lDelimiter||lStr;
   end if;
EXCEPTION_BLOCK
 THROW_EXCEPTION_HANDLER;
END_FUNCTION;
