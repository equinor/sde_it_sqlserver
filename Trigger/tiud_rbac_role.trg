CREATE_TRIGGER(SCHEMA.tiud_rbac_role)
  on SCHEMA.rbac_role
  after insert, update, delete
as
/*****************************************************************
* Audit trigger
*  Package Info
*   Author          : $Author: JOTHOR $
*   Original Date   : $Date: 2026-02-06 $
*   Last Modified   : $Modtime: $
*   Archive Name    : $Archive: $
*   Description     : $Header:  $
*   Revision History: $Revision: $
*   Tag name        : $Name:  $
*   Workfile        : $Workfile: $
*   Copyright       : $Equinor ASA: $
*****************************************************************
* Description
* Template created by: JOTHOR
*
*****************************************************************
* Log
* Date   Description                                     Done by
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
      if (exists(select 1
         from inserted
         where is_system_role = FALSE_CHAR
         and lower(name) not like  'r\_%' escape '\'
         ) )
      begin
         USERERROR(9,'name','none system roles must start with "r_"');
      end;

      if (exists(select 1
         from inserted
         where is_system_role = TRUE_CHAR
         and lower(name) like  'r\_%' escape '\'
         ) )
      begin
         USERERROR(9,'name','system roles must not start with "r_"');
      end;      

      if (IS_TRG_INSERTING) 
      begin
         update SCHEMA.rbac_role
            set name  = lower(name)
               ,change_date = sysutcdatetime()
            where st_id in (select st_id from inserted);
      end
      else if (IS_TRG_UPDATING) 
      begin
         update SCHEMA.rbac_role
            set name  = lower(name)
               ,change_date = sysutcdatetime()
            where st_id in (select st_id from inserted);
      end
      else if (IS_TRG_DELETING) 
      begin
         update SCHEMA.rbac_role
            set is_active = FALSE_CHAR
               ,change_date = sysutcdatetime()
            where st_id in (select st_id from deleted);      
      end;

   EXCEPTION
      --rollback;
      THROW_EXCEPTION_HANDLER;
   END_EXCEPTION
END_TRIGGER;
