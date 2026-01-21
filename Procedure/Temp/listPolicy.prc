CREATE_PROCEDURE(listPolicy)(lObject_owner varchar2 default '%')
authid current_user
--authid definer
is
/*****************************************************************
*  Procedure Info
*   Author          : $Author: JOTHOR $
*   Copyright       : Equionor ASA
*   Original Date   : $Date:  $
*   Last Modified   : $Modtime: $
*   Archive Name    : $Archive: $
*   Description     : $Header:  $
*   Revision History: $Revision:  $
*   Tag name        : $Name:  $
*   Workfile        : $Workfile: $
*****************************************************************
* Description
* Lists all policies. Specific schemas can be targeted
* Output via dbms_output
*****************************************************************
* Log
* Date   Description                                     Done by
*****************************************************************/
  STANDARD_VARIABLE;
  cursor cur_data(lObject_owner varchar2)
   is select p.* from sys.dba_policies p
   inner join sys.dba_users u
      on u.oracle_maintained = 'N'
      and u.username = p.object_owner
   where p.object_owner like lObject_owner;
   lCount integer := 0;
begin
   if (lObject_owner is null) then
      USERERROR(24,'lObject_owner');
   end if;
   
   dbms_output.put_line(rpad('Row',5)
         ||rpad('object_owner',32)
         ||rpad('object_name',32)
         ||rpad('policy_name',32)
         ||rpad('package',32)
         ||rpad('policy_function',32)
         );
   dbms_output.put_line('======================================================================================================================================================');
   for i in cur_data(lObject_owner)
   loop
      lCount := lCount + 1;
      dbms_output.put_line(
           rpad(lCount,5)
         ||rpad(i.object_owner,32)
         ||rpad(i.object_name,32)
         ||rpad(i.policy_name,32)
         ||rpad(coalesce(i.package,'NA'),32)
         ||rpad(i.function,32)
         );
   end loop;
EXCEPTION_BLOCK
    STD_EXCEPTION_HANDLER;
END_CREATE_PROCEDURE;
