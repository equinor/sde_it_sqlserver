CREATE_PROCEDURE(grantToRbac)(lDryRun boolean default false)
authid current_user
--authid definer
is
/*****************************************************************
*  Procedure Info
*   Author          : $Author:  $
*   Original Date   : $Date:  $
*   Last Modified   : $Modtime: $
*   Archive Name    : $Archive: $
*   Description     : $Header:  $
*   Revision History: $Revision:  $
*   Tag name        : $Name:  $
*   Workfile        : $Workfile: $
*****************************************************************
* Description
* To be used in a job to grant privileges to the RBAC user.
* 
*****************************************************************
* Log
* Date   Description                                     Done by
*****************************************************************/
  STANDARD_VARIABLE;
  
  cursor cur_object(lRbacUser varchar2)
  is select 'grant '||
      case when object_type in ('TABLE') then 
        'SELECT,INSERT,UPDATE,DELETE'
      when object_type in ('VIEW') then 
        'SELECT /*,INSERT,UPDATE,DELETE*/'
      ELSE
        'EXECUTE'
      END
      || ' ON '||OBJECT_NAME||' TO "'||lRbacUser||'" with grant option' as grantstatement
     from user_objects
    where object_type in ('TABLE','VIEW','PACKAGE','FUNCTION','PROCEDURE')
    and object_name not like 'BIN$%$0'
    order by object_type,object_name;
--procedure output(lStr varchar2) is begin dbms_output.put_line(lStr); end;
  lStart date := sysdate;
  lCount int := 0;
  lRbacUser constant varchar2(50) := 'F_RBAC_MGR@STATOIL.NET';
begin
  for i in cur_object(lRbacUser)
  loop
    lCount := lCount + 1;
    DEBUG(i.grantstatement);
    if (lDryRun = false) then
      execute immediate i.grantstatement;
    end if;
  end loop;
  sde_it.sf_updatebatchstatus('grantToRbac',lStart,sysdate,0,lCount,'Grant on objects in '||user||' to "'||lRbacUser||'".',true);
EXCEPTION_BLOCK
   THROW_EXCEPTION_HANDLER;
END_PROCEDURE;
