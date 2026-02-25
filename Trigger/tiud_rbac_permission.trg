CREATE_TRIGGER(SCHEMA.tiud_rbac_permission)
  on SCHEMA.rbac_permission
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
* In T-SQL, this trigger is equivalent to Oracle after statement.
* NOTE: cursor "cur_data" should check object parent id fetching 
*  schema type and then check valid object types in 
*  rbac_legal_permission belonging to the parent "schema".
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
   
   -- An idea to use bits, thereby identifying the error(s)
   -- Note the values used.
   declare @lErr_Select integer = 2
      ,@lErr_Insert integer = 4
      ,@lErr_Update integer = 8
      ,@lErr_Delete integer = 16
      ,@lErr_Execute integer = 32
      ,@lErr_Create integer = 64
      ,@lErr_Drop integer = 128
      ,@lErr_Enable integer = 256
      ,@lErr_Disable integer = 512;
  
   BEGIN_EXCEPTION
      declare cur_data cursor local
         for select ob.xtype as data_type
               ,ob.st_id as object_id 
               ,p.st_id
             from inserted p  -- permission
            inner join rbac_object ob
               on p.rbac_object_st_id = ob.st_id;
               
      if (IS_TRG_INSERTING or IS_TRG_UPDATING) 
      begin
         open cur_data;
         fetch next from cur_data into @lDatatype,@lObjectId,@lPermissionId;
         
         while (GET_FETCH_STATUS = 0)
         begin
            if (not exists (select 1 from SCHEMA.rbac_legal_permission where data_type = @lDatatype) )
            begin
               USERERROR(20,'Illegal data type.')
            end;
            DEBUG('Datatype: '+@lDatatype);
            DEBUG('Object id: '+cast(@lObjectId as nvarchar(10)) );
            DEBUG('PermissionId id: '+cast(@lPermissionId as nvarchar(10)) );

            ---------------------------------------------------------------------------
            -- Only need to check if the permission value if the corresponding legal
            -- permission if false.
            -- The value in legal permission "is_active" doesn't matter.
            ---------------------------------------------------------------------------
            select @lRes = sum(
               case when (lg.xselect = FALSE_CHAR and lg.xselect != p.xselect) then  
                     @lErr_Select else 0 end  
               + case when (lg.xupdate  = FALSE_CHAR and lg.xupdate  != p.xupdate) then 
                  @lErr_Update  else 0 end
               + case when (lg.xinsert  = FALSE_CHAR and lg.xinsert  != p.xinsert) then 
                  @lErr_Insert  else 0 end
               + case when (lg.xdelete  = FALSE_CHAR and lg.xdelete  != p.xdelete) then 
                  @lErr_Delete  else 0 end
               + case when (lg.xexecute = FALSE_CHAR and lg.xexecute != p.xexecute)then 
                  @lErr_Execute else 0 end
               + case when (lg.xcreate  = FALSE_CHAR and lg.xcreate  != p.xcreate) then 
                  @lErr_Create  else 0 end
               + case when (lg.xdrop    = FALSE_CHAR and lg.xdrop    != p.xdrop)   then 
                  @lErr_Drop    else 0 end
               + case when (lg.xenable  = FALSE_CHAR and lg.xenable  != p.xenable) then 
                  @lErr_Enable  else 0 end
               + case when (lg.xdisable = FALSE_CHAR and lg.xenable  != p.xdisable) then 
                  @lErr_Disable else 0 end 
               )
            from inserted p
            inner join SCHEMA.rbac_legal_permission lg
               on lg.data_type = @lDatatype
            where p.st_id = @lPermissionId;
            DEBUG('Result='+cast(@lRes as nvarchar(50))+'.');
            
            if (@lRes != 0)
            begin
               USERERROR(20,'Illegal permission (st_id='+cast(@lPermissionId as nvarchar(10))+') for data type ('+cast(@lRes as nvarchar(10))+').Use bit to identify incorrect value(s).');
            end;
            
            fetch next from cur_data into @lDatatype,@lObjectId,@lPermissionId;
         end;   -- end while
         
         if (IS_TRG_DELETING) 
         begin
            -- Bit stupid as the row is actually deleted.
            -- Could move the data to history.
            update SCHEMA.rbac_permission
               set change_date = sysutcdatetime()
                  ,is_active = FALSE_CHAR
               where st_id in (select st_id from deleted);
         end;
         

      end;

      CLOSE_DEALLOCATE_CURSOR(cur_data);
   EXCEPTION
      CLOSE_DEALLOCATE_CURSOR(cur_data);
      THROW_EXCEPTION;
   END_EXCEPTION;
END_TRIGGER;

/*
   -- Captured values from rbac_permission
   declare @lVal_Select char(1) = 'N'
      ,@lVal_Insert char(1)  = 'N'
      ,@lVal_Update char(1)  = 'N'
      ,@lVal_Delete char(1)  = 'N'
      ,@lVal_Execute char(1) = 'N'
      ,@lVal_Create char(1)  = 'N'
      ,@lVal_Drop char(1)    = 'N'
      ,@lVal_Enable char(1)  = 'N'
      ,@lVal_Disable char(1) = 'N';
*/

