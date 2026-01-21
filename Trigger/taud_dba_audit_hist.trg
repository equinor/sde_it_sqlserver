CREATE_TRIGGER(SCHEMA.taud_dba_audit_hist)
  on SCHEMA.dba_audit_hist
  --[ with <dml_trigger_option> [ , ...n ] ]
  after insert,update
as
/*****************************************************************
*   Author          : $Author:  $
*   Original Date   : $Date:  $
*   Last Modified   : $Modtime: $
*   Archive Name    : $Archive: $
*   Description     : $Header:  $
*   Revision History: $Revision: $
*   Tag name        : $Name:  $
*   Workfile        : $Workfile: $
*   Copyright       : $Equinor ASA: $
*****************************************************************
* Description
* NOTE: The "current_User will return the name of the user in the database 
* whereas "suser_name()" will return the user name on the server.
*
* More information on triggers. Check out e.g "set nocount on"
*   Ref: https://learn.microsoft.com/en-us/sql/t-sql/statements/create-trigger-transact-sql?view=sql-server-ver17
*         https://learn.microsoft.com/en-us/sql/relational-databases/triggers/create-dml-triggers?view=sql-server-ver17
*
*  Maintains the create and update columns in the table.
*****************************************************************
* Log
* Date   Description                                        Done by
* 170812 Illegal to alter "create" information once data    JOTHOR
*  has been entered.
*****************************************************************/
begin
   if (rowcount_big() = 0)
         return;

   BEGIN_EXCEPTION
      STANDARD_VARIABLE;
      set nocount on;
   /****************
   xxx https://learn.microsoft.com/en-us/sql/t-sql/functions/columns-updated-transact-sql?view=sql-server-ver17   
   xxx https://forums.sqlteam.com/t/sql-trigger-to-check-if-value-has-been-inserted-already-after-insert/11700
   xxx https://learn.microsoft.com/en-us/sql/t-sql/functions/update-trigger-functions-transact-sql?view=sql-server-ver17
   example of how to access. Have to first create a variable of the corresponding datatype.
      st_created_by {char type} = st_created_by from inserted;
      st_created_by {char type} = st_created_by from deleted;
   ****************/

      if (IS_TRG_INSERTING)
      begin
         update inserted
            set st_created_by = suser_name()  --current_user
            ,st_created_date = getutcdate()
            ,st_updated_by = null
            ,st_updated_date = null
         where st_id in (select st_id from inserted);
      end;
      else if (IS_TRG_UPDATING)
      begin
         declare @lCnt integer = 0;

         select @lCnt = count(*)
            from inserted
            inner join deleted
               on inserted.st_id=deleted.st_id
            where inserted.st_created_by is null or inserted.st_created_by <> deleted.st_created_by;
         if (@lCnt > 0) 
         begin
            USERERROR(19 ,'st_created_by' ,'XUSER');
         end;
         
         select @lCnt = count(*)
            from inserted
            inner join deleted
               on inserted.st_id=deleted.st_id
            where (inserted.st_updated_date is null and deleted.st_updated_date is not null)
            or inserted.st_updated_date <> deleted.st_updated_date;
            
         if (@lCnt > 0)
         begin
            USERERROR(19 ,'st_created_by' ,'XUSER');
         end;
            
/****************
         if (:old.st_updated_date is null and :new.st_updated_date is null)        
            pass; -- ok, this handles the first time the row is updated.
         else if (:new.st_updated_date is null)
         begin
            USERERROR(11 ,'st_updated_date' ,'XUSER');
         end
         else if (:new.st_updated_date <> :old.st_updated_date)
         begin
            USERERROR(19 ,'st_updated_date' ,'XUSER');
         end;
****************/
         
         update inserted 
            set st_updated_by   = suser_name()  --current_user
               ,st_updated_date = getutcdate()
            where st_id in (select st_id from inserted);
      end;
   EXCEPTION
     THROW_EXCEPTION_HANDLER;
   END_EXCEPTION;
END_TRIGGER;
