CREATE_TRIGGER(SCHEMA.tuid_t_basis_clienterrorlog)
  on SCHEMA.t_basis_clienterrorlog
  after insert, update,delete
as
/*****************************************************************
*  Package Info
*   Author          : $Author:  $
*   Original Date   : $Date: 2026-02-02 $
*   Last Modified   : $Modtime: $
*   Archive Name    : $Archive: $
*   Description     : $Header: 
*   Revision History: $Revision: 1.0 $
*   Tag name        : $Name:  $
*   Workfile        : $Workfile: $
*****************************************************************
* Description
* In T-SQL, this trigger is equivalent to Oracle after statement.
* Example:
EXEC sp_addmessage 
    @msgnum = 50001, -- User-defined message ID (must be > 50000)
    @severity = 10,   -- Severity level (0 to 25)
    @msgtext = N'This is a new or updated user-defined error message.',
    @lang = 'us_english', -- Language (optional, default is the server's default language)
    @replace = 'REPLACE'; -- Overwrite if message ID exists
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
   declare @lMessage nvarchar(400)
          ,@lCode integer
          ,@lStartCode integer = 50000
          ,@lReplace_str nvarchar(20) = upper('replace');
   declare cur_ins cursor
      for select messagecode,messagetext from inserted;
   declare cur_del cursor
      for select messagecode from deleted;
      
   BEGIN_EXCEPTION
      if (IS_TRG_INSERTING) 
      begin
         update SCHEMA.t_basis_clienterrorlog
            set dateregistered = getutcdate()
         where st_id in (select st_id from inserted);
      end
      else if (IS_TRG_UPDATING) 
      begin
         update SCHEMA.t_basis_clienterrorlog
            set st_created_by   = d.st_created_by 
               ,st_created_date = d.st_created_date
               ,st_updated_by   = suser_sname()
               ,st_updated_date = sysutcdatetime()
               ,dateregistered = getutcdate()
            from deleted d
            where SCHEMA.t_basis_clienterrorlog.st_id = d.st_id;         
      end
      /*else if (IS_TRG_DELETING) 
      begin
      end;
      */
   EXCEPTION
      STD_EXCEPTION_HANDLER;
   END_EXCEPTION;
END_TRIGGER;
