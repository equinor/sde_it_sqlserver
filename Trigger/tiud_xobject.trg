CREATE_TRIGGER(SCHEMA.tiud_xobject)
  on SCHEMA.xobject
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
         update SCHEMA.xobject
            set xtype  = upper(xtype)
            where st_id in (select st_id from inserted);
      end
      else if (IS_TRG_UPDATING) 
      begin
         update SCHEMA.xobject
            set xtype  = upper(xtype)
            where st_id in (select st_id from inserted);
            
         -----------------------------------------
         -- Deactivation results in updating xpermission.
         -- Reactivation does not affect xpermission.
         -----------------------------------------
         update SCHEMA.xpermission per
            set is_active = FALSE_CHAR
               ,change_date = sysutcdatetime()
         from inserted ins
            inner join deleted del
         where  del.st_id = ins.st_id
         and del.is_active = TRUE_CHAR
         and ins.is_active = FALSE_CHAR
         and per.xobject_st_id = ins.st_id;
      end
      else if (IS_TRG_DELETING) 
      begin
         -----------------------------------------
         -- Deletion results in updating xpermission.
         -- Reactivation does not affect xpermission.
         -----------------------------------------
         update SCHEMA.xpermission per
            set is_active = FALSE_CHAR
               ,change_date = sysutcdatetime()
         from deleted del
         where per.xobject_st_id = del.st_id;
      end;

   EXCEPTION
      --rollback;
      THROW_EXCEPTION_HANDLER;
   END_EXCEPTION
END_TRIGGER;
