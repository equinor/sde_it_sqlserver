CREATE_PROCEDURE(lCommand varchar2)
authid current_user
is
/*****************************************************************
*  Procedure Info
*   Author        : $Author: JOTHOR $
*   Original Date   : $Date: 2007/03/08 10:32:58 $
*   Last Modified   : $Modtime: $
*   Archive Name    : $Archive: $
*   Description     : $Header: f:\private\repository/dbr/Template/procedure.mal,v 1.4 2007/03/08 10:32:58 JOTHOR Exp $
*   Revision History: $Revision: 1.4 $
*   Tag name        : $Name:  $
*   Workfile        : $Workfile: $
*****************************************************************
* Description
*
*
*****************************************************************/
  DECLARE_VARIABLE;
  lDate date := null;
  lStartDate date;
  lEndDate date;
  lCount number := 0;
  lErrText batch_status.message%type;
  lMessage batch_status.message%type;
  lErrCount number := 0;
  lStr varchar2(1000);
begin
   if (lCommand = null) then
     USERERROR(11,'command to be executed');
   end if; 

   lLen := instr(lCommand,'(');
   if (lLen = 0) then
     lLen := instr(lCommand,';',-1);
     if (lLen = 0) then
       lStr := lCommand;
     else
       lStr := substr(lCommand,1, lLen - 1);
     end if;
   else
     lStr := substr(lCommand,1, lLen - 1);
   end if;

   lCommand := 'begin '|| lCommand || '; end;';
   begin
     dbms_output.put_line('execute immediate '||lCommand);
   exception
      when others then
         lMessage := SQLERRM;
   end;

/********************************************
* Calculate the date to delete from
********************************************/
  select sysdate - lDay into lDate from dual;

  SF_UpdateBatchStatus('cleanUpBatchTable'
	,lStartDate
	,lEndDate
	,lErrCount
	,lCount
	,lMessage
	);

  EXCEPTION_BLOCK
    STD_EXCEPTION_HANDLER;
END_CREATE_PROCEDURE;
