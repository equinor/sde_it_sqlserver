CREATE_PROCEDURE(SCHEMA.errorhandler_setlevel) 
   (@lLevel integer
   )
  --with execute as { CALLER | SELF | OWNER | 'user_name' } 
as
/*****************************************************************
* Author          : $Author: JOTHOR  $
* Original Date   : $Date: 22.10.2025 $
* Last Modified   : $Modtime: $
* Archive Name    : $Archive: GITHUB $
* Description     :  $
* Revision History: $Revision: 1.1 $
* Workfile        : $Workfile: $
* Copyright       : Equinor ASA
*****************************************************************
* Description
* NOTE: Always ensure context key is alligned with fuction errorhandler_getlevel.
*
* Variables
*  Legal levels provided. Levels are:
*     logging_off  = 0;
*     level_high   = 1;
*     level_medium = 2;
*     level_low    = 3;
*     level_info   = 4;
*     level_trace  = 5; -- also known as debug
*****************************************************************
* Log
* Date   Description					 Done by
*
*****************************************************************/
begin  
   STANDARD_VARIABLE;
   set nocount on;

   if (@lLevel > 5) set @lLevel = 5;
   if (@lLevel < 0) set @lLevel = 0;
   
   execute sp_set_session_context 'error_level', @lLevel;
END_CREATE_PROCEDURE;

