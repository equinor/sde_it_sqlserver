CREATE_PROCEDURE(SCHEMA.errorhandler_log) 
   (@lLevel integer
   ,@lApplication nvarchar(200)
   ,@lVersion nvarchar(20)
   ,@lMessage nvarchar(300)
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
* 221025 JOTHOR: Currently 
* Variables
* Will log on levels less than the desired setting.
*  E.g. if desired =4, only levels 1,2,3,4 will be logged.
* @lCurrentDesiredLevel this is the current set level for performing
*  logging. 
*  231025 JOTHOR: Unfortunately setting and keeping the desired 
*  level has yet to be implemented. Even so the below levels provided
*  for future reference.
*  Levels are:
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
   declare @lMaxMessageLength integer = 255
      ,@lStr nvarchar(500)
      ,@lHost nvarchar(100) = 'NA'
      ,@lLevel_high integer = 1
      ,@lCurrentDesiredLevel integer = 0; -- Dirty trick: All logging will be performed.
   set nocount on;
   
   --print(cast(@lLevel as nvarchar(2))+": "+@lApplication+": "+@lVersion+": "+@lMessage+".");
   if (@lLevel > 5) set @lLevel = 5;
   if (@lLevel < 0) set @lLevel = 0;
   
   set @lCurrentDesiredLevel = SCHEMA.errorhandler_getlevel();
   
   if (@lLevel != @lLevel_high and @lLevel > @lCurrentDesiredLevel)
      return;

   if (@lMessage is null)
      set @lStr = 'N/A';
   else if (len(@lMessage) > @lMaxMessageLength)
      set @lStr = substring(@lMessage,1,@lMaxMessageLength);
   else
      set @lStr = @lMessage;

   if (@lVersion is null)
      set @lVersion = 'N/A';

   BEGIN_EXCEPTION 
      insert into SCHEMA.t_basis_clienterrorlog(
          applicationname
         ,applicationversion
         ,userregistered
         ,messagecode
         ,messagetext
         ,host
         )
         values (
             @lApplication
            ,@lVersion
            ,suser_name()
            ,@lLevel
            ,@lStr
            ,@lHost
            );
select * from  sde_it.t_basis_clienterrorlog;
      -------------------------------------------------------------------------
      -- Can not commit due to sqlserver lacks autonomous transaction handling.
      -------------------------------------------------------------------------
      --commit;
   EXCEPTION
      CONSUME_EXCEPTION_HANDLER;
   END_EXCEPTION;

END_CREATE_PROCEDURE;

