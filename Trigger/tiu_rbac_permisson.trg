CREATE_TRIGGER(SCHEMA.tiu_rbac_permission)
  on SCHEMA.rbac_permission
  after insert, update,delete
as
/*****************************************************************
*  Package Info
*   Author          : $Author: JOTHOR $
*   Original Date   : $Date: 2026-07-02 $
*   Last Modified   : $Modtime: $
*   Archive Name    : $Archive: $
*   Description     : $Header: 
*   Revision History: $Revision: 1.0 $
*   Tag name        : $Name:  $
*   Workfile        : $Workfile: $
*****************************************************************
* Description
* In T-SQL, this trigger is equivalent to Oracle after statement.
* 1) Ensures correct letter case for some attributes.
*****************************************************************
* Log
* Date   Description					 Done by
*
*****************************************************************/
begin
   if (rowcount_big() = 0)
      return;
   if TRIGGER_NESTLEVEL() > 1
      return
      
   set nocount on;
   STANDARD_VARIABLE;
   
   BEGIN_EXCEPTION
      if (IS_TRG_INSERTING 
         or IS_TRG_UPDATING
         ) 
      begin
         update SCHEMA.rbac_permission
            set xselect = upper(xselect)
               ,xupdate = upper(xupdate)
               ,xinsert = upper(xinsert)
               ,xdelete = upper(xdelete)
               ,xexecute = upper(xexecute)
               ,xdrop    = upper(xdrop)
               ,xenable  = upper(xenable)
               ,xdisable = upper(xdisable)
         where st_id in (select st_id from inserted);
      end;

--      if (IS_TRG_UPDATING) 
--      begin
--      end;
--
--      if (IS_TRG_DELETING) 
--      begin
--      end;
   EXCEPTION
      --S TANDARD_EXCEPTION_HANDLER;
      throw;
   END_EXCEPTION;
END_TRIGGER;
