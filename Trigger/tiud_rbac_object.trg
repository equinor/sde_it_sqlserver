CREATE_TRIGGER(SCHEMA.tiud_rbac_object)
  on SCHEMA.rbac_object
  after insert, update , delete
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
* Remeber to set change_date where appropiate. Other tables
*  could be in focus.
* Set is_active flag where appropiate. Other tables
*  could be in focus.
*****************************************************************
* Log
* Date   Description                                     Done by
* 120226 Include delete processing                       JOTHOR 
*****************************************************************/
begin
   if (rowcount_big() = 0)
      return;
      
   if TRIGGER_NESTLEVEL() > 1
      return
      
   set nocount on;
   STANDARD_VARIABLE;

   BEGIN_EXCEPTION
      if (IS_TRG_INSERTING) 
      begin
         update SCHEMA.rbac_object
            set xtype = upper(xtype)
            where st_id in (select st_id from inserted);
      end
      else if (IS_TRG_UPDATING) 
      begin
         update SCHEMA.rbac_object
            set xtype  = upper(xtype)
            where st_id in (select st_id from inserted);
            
         -----------------------------------------
         -- Deactivation results in updating xpermission.
         -- Reactivation does not affect xpermission.
         -----------------------------------------
         merge into  SDE_IT.rbac_permission p
            using (select ins.st_id
                     from inserted ins
                     inner join deleted del
                        on del.st_id = ins.st_id
                        and del.is_active = TRUE_CHAR
                        and ins.is_active = FALSE_CHAR
               )   xd
            on (p.rbac_object_st_id = xd.st_id)
            when matched then update 
               set is_active = FALSE_CHAR
                  ,change_date = sysutcdatetime();         
      end
      else if (IS_TRG_DELETING) 
      begin
         -----------------------------------------
         -- Deletion results in updating xpermission.
         -- Reactivation does not affect xpermission.
         -----------------------------------------
         update SCHEMA.rbac_permission
            set is_active = FALSE_CHAR
               ,change_date = sysutcdatetime()
         from deleted del
         where rbac_object_st_id = del.st_id;
      end;

   EXCEPTION
      --rollback;
      THROW_EXCEPTION_HANDLER;
   END_EXCEPTION
END_TRIGGER;
