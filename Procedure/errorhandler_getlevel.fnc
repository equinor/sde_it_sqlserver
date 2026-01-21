CREATE_FUNCTION(SCHEMA.errorhandler_getlevel) ()
   returns integer
  --with execute as { CALLER | SELF | OWNER | 'user_name' } 
as
/*****************************************************************
* Author          : $Author: JOTHOR  $
* Original Date   : $Date: 23.10.2025 $
* Last Modified   : $Modtime: $
* Archive Name    : $Archive: GITHUB $
* Description     :  $
* Revision History: $Revision: 1.1 $
* Workfile        : $Workfile: $
* Copyright       : Equinor ASA
*****************************************************************
* Description
* Returns the current setting for error logging
*****************************************************************
* Log
* Date   Description					 Done by
*
*****************************************************************/
begin  
   --set nocount on;
   --S TANDARD_VARIABLE;
   declare @lLevel integer = 0;

   set @lLevel = convert(integer,session_context(N'error_level'));
   if @lLevel is null 
      set @lLevel = 0;

   return @lLevel;
END_CREATE_FUNCTION;

