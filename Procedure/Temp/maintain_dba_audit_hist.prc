CREATE_PROCEDURE(maintain_dba_audit_hist)
authid current_user
--authid definer
is
/*****************************************************************
* Procedure Info
* Author          : $Author: JOTHOR  $
* Original Date   : $Date: 22.09.2022 $
* Last Modified   : $Modtime: $
* Archive Name    : $Archive: $
* Description     :  $
* Revision History: $Revision: 1.1 $
* Workfile        : $Workfile: $
* Copyright       : Equinor ASA
*****************************************************************
* Description
*
*
*****************************************************************
* Log
* Date   Description					 Done by
*
*****************************************************************/
  STANDARD_VARIABLE;
  lStart date := sysdate;
  lCount int;
begin
   insert into dba_audit_hist
      select  
         dt.os_username
         ,dt.username
         ,dt.current_user
         --,dt.TIMESTAMP
         ,dt.owner,dt.obj_name,dt.action_name
         ,trunc(sysdate - 1) as report_day
         ,count(*) as cnt
         --,dt.* 
         from dba_audit_trail dt
            inner join dba_users du
             on du.oracle_maintained= 'N'
             and upper(dt.os_username) not in  ('ORACLE')
             and action_name not in ('LOGOFF','LOGOFF BY CLEANUP','xLOGON')
             and owner not in ('SYS')
             and du.username=dt.username
             and dt.timestamp between trunc(sysdate - 1) and trunc(sysdate)
         group by dt.os_username
         ,dt.username
         ,dt.current_user
         ,dt.owner,dt.obj_name,dt.action_name
         ,trunc(sysdate - 1);
   lCount := sql%rowcount;
   commit;
   
   -- Consider logging in SDE_IT.BATCH_STATUS  
   SDE_IT.sf_updatebatchstatus('maintain_dba_audit_hist'
            ,lStart,sysdate,0
            ,lCount
            ,'Table dba_audit_hist updated '||to_char(trunc(sysdate - 1),'dd.mm.yyyy')||'.'
            ,true
            );
EXCEPTION_BLOCK
   STD_EXCEPTION_HANDLER;
END_PROCEDURE;
