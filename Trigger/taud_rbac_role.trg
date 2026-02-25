CREATE_TRIGGER(SCHEMA.taud_rbac_role)
  on SCHEMA.rbac_role
  after insert, update
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
* Maintains the create and update columns in the table.
*
* Could extend auditing by including 
*  os-user (255 char)
* Why? ths "user" is not always the actual user. Using "os-user" 
* pinpoint the user who is logged in on the PC. This user may use
* a common login user thereby camouflaging their identify.
*
* Which to utc date to use?
* https://learn.microsoft.com/en-us/sql/t-sql/functions/getutcdate-transact-sql?view=sql-server-ver17
*****************************************************************
* Log
* Date   Description                                     Done by
* 170812 Illegal to alter "create" information once data JOTHOR
*  has been entered.
*****************************************************************/
begin
      if (rowcount_big() = 0)
         return;
      
      set nocount on;
      STANDARD_VARIABLE;
      ---------------------------------------------------------
      -- Update: Illegal to alter st_created_by and st_created_date.
      -- If actor attempts to alter st_updated_by and/or st_updated_date,
      -- these will be overwritten regardless. 
      -- There is code to flag if actor attempts to set these values,
      -- but currently not engaged
      ---------------------------------------------------------
      BEGIN_EXCEPTION
         if (IS_TRG_INSERTING) 
         begin
            update SCHEMA.rbac_role
               set st_created_by   = suser_sname()
                  ,st_created_date = sysutcdatetime()
                  ,st_updated_by   = null
                  ,st_updated_date = null
               where st_id in (select st_id from inserted);
         end
         else if (IS_TRG_UPDATING) 
         begin
            /*
            ------------------------------------------------------------
            -- Not engaging this error checking as uncertain how exception
            -- handling shall be handled. Shall the trigger rollback (see
            -- macro "create_method" and the macro setting "mcr_trans_off".
            -- Till further notice, the attributes st_created_by and
            -- st_created_date will be reset to original values and no
            -- notification will be given to actor activiating the trigger.
            ------------------------------------------------------------
            if exists(select 1 from inserted i
                   inner join deleted d
                   on i.st_id = d.st_id
                   and i.st_created_by != d.st_created_by
                     )
            begin
               USERERROR(19,'st_created_by','XUSER');
            end
            else if exists(select 1 from inserted i
                   inner join deleted d
                   on i.st_id = d.st_id
                   and i.st_created_date != d.st_created_date
                   )
            begin
               USERERROR(19,'st_created_date','XUSER');
            end
            */
            
            -- Fetching original create info from deleted table.
            update SCHEMA.rbac_role
               set st_created_by   = d.st_created_by 
                  ,st_created_date = d.st_created_date
                  ,st_updated_by   = suser_sname()
                  ,st_updated_date = sysutcdatetime()
               from deleted d
                  where SCHEMA.rbac_role.st_id = d.st_id;
         end;
   EXCEPTION
      THROW_EXCEPTION_HANDLER;
   END_EXCEPTION
END_TRIGGER;
