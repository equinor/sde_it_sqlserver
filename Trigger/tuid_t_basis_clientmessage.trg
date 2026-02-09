CREATE_TRIGGER(SCHEMA.tuid_t_basis_clientmessage)
  on SCHEMA.t_basis_clientmessage
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
         open cur_ins;
         fetch cur_ins into @lCode,@lMessage;
         while (GET_FETCH_STATUS = 0)
         begin
            set @lCode = @lCode + @lStartCode;
            -- If mismatch between sde_it and sys then update.
            if exists(select 1 from sys.messages where message_id=@lCode)
            begin
            exec sp_addmessage @msgnum = @lCode
               ,@severity = 11
               ,@msgtext= @lMessage
               ,@replace = @lReplace_str;
            end
            else
            begin
               exec sp_addmessage @msgnum = @lCode
                  ,@severity = 11
                  ,@msgtext= @lMessage;
            end;
            fetch cur_ins into @lCode,@lMessage;
         end;
      end
      else if (IS_TRG_UPDATING) 
      begin
         open cur_ins;
         fetch cur_ins into @lCode,@lMessage;
         while (GET_FETCH_STATUS = 0)
         begin
            set @lCode = @lCode + @lStartCode;
            exec sp_addmessage  @msgnum = @lCode
               ,@severity = 11
               ,@msgtext= @lMessage
               ,@replace = @lReplace_str;
            fetch cur_ins into @lCode,@lMessage;
         end
      end
      else if (IS_TRG_DELETING) 
      begin
         open cur_del;
         fetch cur_del into @lCode
         while (GET_FETCH_STATUS = 0)
         begin
            set @lCode = @lCode + @lStartCode;
            exec sp_dropmessage @msgnum = @lCode;
            fetch cur_del into @lCode;
         end
      end;
      
      DEALLOCATE_CURSOR(cur_ins);
      DEALLOCATE_CURSOR(cur_del);
   EXCEPTION
      STD_EXCEPTION_HANDLER;
   END_EXCEPTION;
END_TRIGGER;
