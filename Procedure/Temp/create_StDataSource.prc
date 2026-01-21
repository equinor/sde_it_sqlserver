CREATE_FUNCTION(create_StDataSource)(lCurrentSourceSet varchar2)
     return varchar2
--authid current_user
authid definer
is
/*****************************************************************
*  Function Info
*   Author          : $Author:  $
*   Original Date   : $Date:  $
*   Last Modified   : $Modtime: $
*   Archive Name    : $Archive: $
*   Description     : $Header:   Exp $
*   Revision History: $Revision: 1.0 $
*   Tag name        : $Name:  $
*   Workfile        : $Workfile: $
*****************************************************************
* Description
* Adds the System name to what is supplied via the input parameter.
* Intended for maintaining the st_source attribute and provides a
* chain of sources to the actor selecting the data.
* Leaves a lDelimiter at the end.
*
* Depends on FRAMEWORK_SCHEMA.tab_variable data.
* NOTE: Remember to check isactive = TRUE_NR when fetching data!
*****************************************************************
* Log
* Date   Description                                        Done by
*
*****************************************************************/
   STANDARD_VARIABLE;
   lStr varchar2(100); 
   lSystem varchar2(100); 
   lDelimiter varchar2(10); 
   lMaxSetSize integer;   
begin
   select valid_value into lSystem
     from tab_variable
     where category = upper('system_detail')
     and key = upper('name')
     and isactive = TRUE_NR;
     
   select valid_value into lDelimiter
     from tab_variable
     where category = upper('system_detail')
     and key = upper('delimiter')
     and isactive = TRUE_NR;
     
   select valid_value into lMaxSetSize
     from tab_variable
     where category = upper('system_detail')
     and key = upper('max_datasource_set')
     and isactive = TRUE_NR;    
     
   if (lSystem is null or lSystem = 'NA' or lDelimiter = 'NA'  or lDelimiter is null) then
      SYSTEMERROR(20,'The system_detail.delimiter/name/ is null or inactive.');
   end if;

   if (lCurrentSourceSet is null) then
      return lSystem||lDelimiter;
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

   if (substr(lStr,1,instr(lStr,lDelimiter) - 1) = lSystem) then
      return lStr;
   elsif (regexp_count(lStr,lDelimiter) >= lMaxSetSize) then
      return lSystem||lDelimiter||substr(lStr,1,instr(lStr,lDelimiter,1,lMaxSetSize-1));  
   else
      return lSystem||lDelimiter||lStr;
   end if;   
  EXCEPTION_BLOCK
      when no_data_found then
         SYSTEMERROR(20,'The system_detail.delimiter/name/ is null or inactive.');
      STD_EXCEPTION_HANDLER;
END_CREATE_FUNCTION;
