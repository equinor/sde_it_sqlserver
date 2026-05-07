CREATE_TRIGGER(SCHEMA.tiud_rbac_initial_oracle_permission)
  on SCHEMA.rbac_initial_oracle_permission
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

      end
      else if (IS_TRG_UPDATING) 
      begin

         -----------------------------------------
         -- Deactivation results in updating xpermission.
         -- Reactivation does not affect xpermission.
         -----------------------------------------
      
      end
      else if (IS_TRG_DELETING) 
      begin
         -----------------------------------------
         -- Deletion results in updating xpermission.
         -- Reactivation does not affect xpermission.
         -----------------------------------------

      end;

   EXCEPTION
      --rollback;
      THROW_EXCEPTION_HANDLER;
   END_EXCEPTION
END_TRIGGER;
