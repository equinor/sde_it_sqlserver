CREATE_TRIGGER(SCHEMA.tiu_xpermission)
  on SCHEMA.xpermission
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
*
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
   
   declare @lDatatype nvarchar(100)
      ,@lObjectId integer
      ,@lPermissionId integer
      ,@lRes integer;
   
   BEGIN_EXCEPTION
      declare cur_data cursor local
         for select ob.xtype as data_type
               ,ob.st_id as object_id 
               ,p.st_id
            from inserted p  -- permission
            inner join xobject ob
               on p.xobject_st_id = ob.st_id;
      if (IS_TRG_INSERTING or IS_TRG_UPDATING) 
      begin
         open cur_data;
         fetch next from cur_data into @lDatatype,@lObjectId,@lPermissionId;
         
         while (GET_FETCH_STATUS = 0)
         begin
            if (not exists (select 1 from legal_permission where data_type = @lDatatype) )
            begin
               USERERROR(20,'Illegal data type.')
            end;
            select @lRes = sum ( 
                  case when ins.xselect = TRUE_CHAR and (lg.xselect = FALSE_CHAR or lg.is_active =FALSE_CHAR) then 0 else 1 end
                  + case when ins.xupdate = TRUE_CHAR and (lg.xupdate = FALSE_CHAR or lg.is_active =FALSE_CHAR) then 0 else 1 end
                  + case when ins.xinsert = TRUE_CHAR and (lg.xinsert = FALSE_CHAR or lg.is_active =FALSE_CHAR) then 0 else 1 end
                  + case when ins.xdelete = TRUE_CHAR and (lg.xdelete = FALSE_CHAR or lg.is_active =FALSE_CHAR) then 0 else 1 end
                  + case when ins.xexecute = TRUE_CHAR and (lg.xexecute = FALSE_CHAR or lg.is_active =FALSE_CHAR) then 0 else 1 end
                  + case when ins.xcreate = TRUE_CHAR and (lg.xcreate = FALSE_CHAR or lg.is_active =FALSE_CHAR) then 0 else 1 end
                  + case when ins.xdrop = TRUE_CHAR and (lg.xdrop = FALSE_CHAR or lg.is_active =FALSE_CHAR) then 0 else 1 end
                  ) 
               from inserted ins
               inner join legal_permission lg
                  on lg.data_type = @lDatatype
               where ins.st_id = @lPermissionId;
               
            if (@lRes != 0)
            begin
               USERERROR(20,'Illegal permission for data type.')
            end;            
         end;   -- end while
             
      end;

      CLOSE_DEALLOCATE_CURSOR(cur_data);
   EXCEPTION
      CLOSE_DEALLOCATE_CURSOR(cur_data);
      THROW_EXCEPTION;
   END_EXCEPTION;
END_TRIGGER;
